import { NextRequest, NextResponse } from "next/server";
import { stripe } from "@/lib/stripe";

export async function GET(request: NextRequest) {
  const sessionId = request.nextUrl.searchParams.get("session_id");

  if (!sessionId) {
    return NextResponse.json({ error: "Missing session_id" }, { status: 400 });
  }

  try {
    const session = await stripe.checkout.sessions.retrieve(sessionId);

    if (session.payment_status !== "paid") {
      return NextResponse.json({ error: "Payment not completed" }, { status: 402 });
    }

    const customerId = session.customer as string;
    const customer = await stripe.customers.retrieve(customerId);

    if (customer.deleted) {
      return NextResponse.json({ error: "Customer not found" }, { status: 404 });
    }

    const licenseKey = customer.metadata?.license_key;
    const plan = customer.metadata?.plan;

    if (!licenseKey) {
      // License may not be generated yet (webhook delay)
      return NextResponse.json({
        status: "pending",
        message: "Your license is being generated. Please refresh in a moment.",
      });
    }

    return NextResponse.json({
      status: "active",
      licenseKey,
      plan,
      email: customer.email,
    });
  } catch (error) {
    console.error("License retrieval error:", error);
    return NextResponse.json(
      { error: "Failed to retrieve license" },
      { status: 500 }
    );
  }
}
