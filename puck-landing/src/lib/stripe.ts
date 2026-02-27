import Stripe from "stripe";

export const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!, {
  apiVersion: "2026-01-28.clover",
  typescript: true,
});

export const PLANS = {
  starter: {
    name: "Starter",
    description: "For individual creators",
    price: 9,
    priceId: process.env.STRIPE_STARTER_PRICE_ID!,
    features: [
      "1 device license",
      "Unlimited downloads",
      "All audio formats (MP3, FLAC, WAV, M4A)",
      "Standard video quality (up to 1080p)",
      "Email support",
      "Auto-updates",
    ],
    limits: {
      devices: 1,
      concurrent: 3,
    },
  },
  pro: {
    name: "Pro",
    description: "For power users & professionals",
    price: 19,
    priceId: process.env.STRIPE_PRO_PRICE_ID!,
    popular: true,
    features: [
      "3 device licenses",
      "Unlimited downloads",
      "All audio & video formats",
      "ProRes conversion (Proxy, LT, HQ)",
      "4K+ video quality",
      "NLE auto-import (Premiere, Resolve, FCP)",
      "Priority support",
      "Auto-updates",
    ],
    limits: {
      devices: 3,
      concurrent: 10,
    },
  },
  team: {
    name: "Team",
    description: "For studios & teams",
    price: 49,
    priceId: process.env.STRIPE_TEAM_PRICE_ID!,
    features: [
      "10 device licenses",
      "Everything in Pro",
      "Team license management dashboard",
      "Batch download API",
      "Custom output presets",
      "Dedicated support channel",
      "Volume discount available",
      "Priority auto-updates",
    ],
    limits: {
      devices: 10,
      concurrent: 25,
    },
  },
} as const;

export type PlanKey = keyof typeof PLANS;
