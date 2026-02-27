"use client";

import { motion } from "framer-motion";
import { Check, Sparkles, Zap } from "lucide-react";
import { useState } from "react";

const plans = [
  {
    key: "starter",
    name: "Starter",
    description: "For individual creators",
    price: 9,
    features: [
      "1 device license",
      "Unlimited downloads",
      "All audio formats (MP3, FLAC, WAV, M4A)",
      "Standard video quality (up to 1080p)",
      "Email support",
      "Auto-updates",
    ],
  },
  {
    key: "pro",
    name: "Pro",
    description: "For power users & professionals",
    price: 19,
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
  },
  {
    key: "team",
    name: "Team",
    description: "For studios & teams",
    price: 49,
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
  },
];

const containerVariants = {
  hidden: {},
  visible: {
    transition: { staggerChildren: 0.12 },
  },
};

const cardVariants = {
  hidden: { opacity: 0, y: 40 },
  visible: { opacity: 1, y: 0, transition: { duration: 0.6 } },
};

export default function Pricing() {
  const [loading, setLoading] = useState<string | null>(null);
  const [email, setEmail] = useState("");

  const handleCheckout = async (planKey: string) => {
    setLoading(planKey);
    try {
      const res = await fetch("/api/checkout", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ plan: planKey, email: email || undefined }),
      });
      const data = await res.json();
      if (data.url) {
        window.location.href = data.url;
      } else {
        alert(data.error || "Something went wrong");
      }
    } catch {
      alert("Failed to start checkout. Please try again.");
    } finally {
      setLoading(null);
    }
  };

  return (
    <section id="pricing" className="relative py-32 px-6">
      {/* Background glow */}
      <div className="absolute inset-0 overflow-hidden pointer-events-none">
        <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[800px] h-[400px] bg-puck-purple/5 rounded-full blur-3xl" />
      </div>

      <div className="relative z-10 max-w-6xl mx-auto">
        {/* Section header */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.5 }}
          className="text-center mb-6"
        >
          <h2 className="text-3xl md:text-5xl font-bold mb-4">
            <span className="bg-gradient-to-r from-puck-purple to-puck-cyan bg-clip-text text-transparent">
              Simple, fair pricing
            </span>
          </h2>
          <p className="text-puck-muted text-lg max-w-xl mx-auto">
            One-time setup, monthly subscription. Cancel anytime.
            Every plan includes a license key for the macOS app.
          </p>
        </motion.div>

        {/* Email input */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.5, delay: 0.1 }}
          className="max-w-sm mx-auto mb-16"
        >
          <input
            type="email"
            placeholder="Enter your email (optional)"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            className="w-full px-4 py-3 rounded-xl bg-puck-surface border border-puck-border text-foreground placeholder:text-puck-muted/50 text-sm focus:outline-none focus:border-puck-cyan/50 focus:ring-1 focus:ring-puck-cyan/20 transition-all"
          />
        </motion.div>

        {/* Pricing cards */}
        <motion.div
          variants={containerVariants}
          initial="hidden"
          whileInView="visible"
          viewport={{ once: true, margin: "-50px" }}
          className="grid grid-cols-1 md:grid-cols-3 gap-6 lg:gap-8"
        >
          {plans.map((plan) => (
            <motion.div
              key={plan.key}
              variants={cardVariants}
              className={`relative rounded-2xl p-8 transition-all duration-300 ${
                plan.popular
                  ? "glass-card border-puck-cyan/40 glow-cyan scale-[1.02]"
                  : "glass-card glass-card-hover"
              }`}
            >
              {/* Popular badge */}
              {plan.popular && (
                <div className="absolute -top-3 left-1/2 -translate-x-1/2">
                  <div className="flex items-center gap-1.5 px-4 py-1 rounded-full bg-gradient-to-r from-puck-cyan to-puck-purple text-white text-xs font-semibold">
                    <Sparkles size={12} />
                    Most Popular
                  </div>
                </div>
              )}

              {/* Plan info */}
              <div className="mb-6">
                <h3 className="text-xl font-bold text-foreground mb-1">
                  {plan.name}
                </h3>
                <p className="text-sm text-puck-muted">{plan.description}</p>
              </div>

              {/* Price */}
              <div className="mb-8">
                <div className="flex items-baseline gap-1">
                  <span className="text-4xl font-bold bg-gradient-to-r from-puck-cyan to-puck-purple bg-clip-text text-transparent">
                    ${plan.price}
                  </span>
                  <span className="text-puck-muted text-sm">/month</span>
                </div>
              </div>

              {/* Features */}
              <ul className="space-y-3 mb-8">
                {plan.features.map((feature) => (
                  <li key={feature} className="flex items-start gap-3">
                    <Check
                      size={16}
                      className={`mt-0.5 flex-shrink-0 ${
                        plan.popular ? "text-puck-cyan" : "text-puck-green"
                      }`}
                    />
                    <span className="text-sm text-puck-muted">{feature}</span>
                  </li>
                ))}
              </ul>

              {/* CTA */}
              <button
                onClick={() => handleCheckout(plan.key)}
                disabled={loading !== null}
                className={`w-full py-3 rounded-xl font-semibold text-sm transition-all duration-300 flex items-center justify-center gap-2 ${
                  plan.popular
                    ? "bg-gradient-to-r from-puck-cyan to-puck-purple text-white hover:shadow-lg hover:shadow-puck-cyan/20"
                    : "border border-puck-border text-foreground hover:border-puck-cyan/40 hover:text-puck-cyan"
                } disabled:opacity-50 disabled:cursor-not-allowed`}
              >
                {loading === plan.key ? (
                  <div className="w-5 h-5 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                ) : (
                  <>
                    <Zap size={14} />
                    Get {plan.name}
                  </>
                )}
              </button>
            </motion.div>
          ))}
        </motion.div>

        {/* Guarantee */}
        <motion.p
          initial={{ opacity: 0 }}
          whileInView={{ opacity: 1 }}
          viewport={{ once: true }}
          transition={{ delay: 0.5 }}
          className="text-center text-sm text-puck-muted mt-10"
        >
          7-day money-back guarantee. No questions asked. Cancel your subscription anytime.
        </motion.p>
      </div>
    </section>
  );
}
