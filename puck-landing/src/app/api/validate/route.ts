import { NextRequest, NextResponse } from "next/server";
import { stripe } from "@/lib/stripe";
import { validateLicenseFormat } from "@/lib/license";

export async function POST(request: NextRequest) {
  try {
    const { licenseKey } = await request.json();

    if (!licenseKey || !validateLicenseFormat(licenseKey)) {
      return NextResponse.json(
        { valid: false, error: "Invalid license key format" },
        { status: 400 }
      );
    }

    // Search for customer with this license key in Stripe
    const customers = await stripe.customers.search({
      query: `metadata["license_key"]:"${licenseKey}"`,
    });

    if (customers.data.length === 0) {
      return NextResponse.json(
        { valid: false, error: "License key not found" },
        { status: 404 }
      );
    }

    const customer = customers.data[0];
    const plan = customer.metadata?.plan;

    // Check if subscription is still active
    const subscriptions = await stripe.subscriptions.list({
      customer: customer.id,
      status: "active",
    });

    if (subscriptions.data.length === 0) {
      return NextResponse.json(
        { valid: false, error: "Subscription is no longer active" },
        { status: 403 }
      );
    }

    return NextResponse.json({
      valid: true,
      plan,
      email: customer.email,
    });
  } catch (error) {
    console.error("Validation error:", error);
    return NextResponse.json(
      { valid: false, error: "Validation failed" },
      { status: 500 }
    );
  }
}
