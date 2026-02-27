import { NextRequest, NextResponse } from "next/server";
import { stripe } from "@/lib/stripe";
import { generateLicenseKey } from "@/lib/license";

export async function POST(request: NextRequest) {
  const body = await request.text();
  const signature = request.headers.get("stripe-signature");

  if (!signature) {
    return NextResponse.json({ error: "No signature" }, { status: 400 });
  }

  let event;

  try {
    event = stripe.webhooks.constructEvent(
      body,
      signature,
      process.env.STRIPE_WEBHOOK_SECRET!
    );
  } catch (err) {
    console.error("Webhook signature verification failed:", err);
    return NextResponse.json({ error: "Invalid signature" }, { status: 400 });
  }

  switch (event.type) {
    case "checkout.session.completed": {
      const session = event.data.object;
      const customerId = session.customer as string;
      const plan = session.metadata?.plan || "starter";

      // Generate license key
      const licenseKey = generateLicenseKey(customerId, plan);

      // In production, store this in a database (e.g., Postgres, Supabase, etc.)
      // For now, we store it in Stripe customer metadata
      await stripe.customers.update(customerId, {
        metadata: {
          license_key: licenseKey,
          plan,
          activated_at: new Date().toISOString(),
        },
      });

      console.log(`License generated for ${customerId}: ${licenseKey}`);
      break;
    }

    case "customer.subscription.deleted": {
      const subscription = event.data.object;
      const customerId = subscription.customer as string;

      // Revoke license
      await stripe.customers.update(customerId, {
        metadata: {
          license_key: "",
          plan: "cancelled",
          cancelled_at: new Date().toISOString(),
        },
      });

      console.log(`License revoked for ${customerId}`);
      break;
    }

    case "customer.subscription.updated": {
      const subscription = event.data.object;
      const customerId = subscription.customer as string;

      if (subscription.status === "past_due" || subscription.status === "unpaid") {
        console.log(`Subscription issue for ${customerId}: ${subscription.status}`);
      }
      break;
    }
  }

  return NextResponse.json({ received: true });
}
