"use client";

import { motion, AnimatePresence } from "framer-motion";
import { ChevronDown } from "lucide-react";
import { useState } from "react";

const faqs = [
  {
    question: "How does the license key work?",
    answer:
      "After subscribing, you'll receive a unique license key (e.g., PUCK-PR-XXXX-XXXX-XXXX-XXXX). Enter this key in the Puck macOS app to activate your subscription. The key is tied to your Stripe subscription and remains active as long as your subscription is current.",
  },
  {
    question: "What happens if I cancel my subscription?",
    answer:
      "Your license key will remain active until the end of your current billing period. After that, the app will revert to limited functionality. You can resubscribe at any time to get a new license key.",
  },
  {
    question: "Can I use Puck on multiple Macs?",
    answer:
      "Yes! The Starter plan supports 1 device, Pro supports 3 devices, and Team supports up to 10 devices. Each device is activated with the same license key.",
  },
  {
    question: "What sites does Puck support?",
    answer:
      "Puck uses yt-dlp under the hood, which supports 1000+ websites including YouTube, Vimeo, Twitter/X, TikTok, Instagram, Twitch, SoundCloud, Bandcamp, and many more.",
  },
  {
    question: "Do I need to install yt-dlp and ffmpeg separately?",
    answer:
      "Puck comes bundled with yt-dlp and ffmpeg in the DMG. No Homebrew or manual installation required. The app will also detect system-installed versions if you prefer to manage them yourself.",
  },
  {
    question: "What video/audio formats are supported?",
    answer:
      "Audio: MP3, FLAC, WAV, M4A, Opus, OGG. Video: Original format, plus ProRes conversion (Proxy, LT, HQ) for professional editing workflows. Pro and Team plans unlock all formats and 4K+ quality.",
  },
  {
    question: "Is there a free trial?",
    answer:
      "We offer a 7-day money-back guarantee on all plans. Try Puck risk-free — if it's not for you, we'll refund your payment, no questions asked.",
  },
];

export default function FAQ() {
  const [openIndex, setOpenIndex] = useState<number | null>(null);

  return (
    <section id="faq" className="relative py-32 px-6">
      <div className="max-w-3xl mx-auto">
        {/* Section header */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.5 }}
          className="text-center mb-16"
        >
          <h2 className="text-3xl md:text-5xl font-bold mb-4">
            <span className="bg-gradient-to-r from-puck-cyan to-puck-purple bg-clip-text text-transparent">
              Frequently asked questions
            </span>
          </h2>
        </motion.div>

        {/* FAQ items */}
        <div className="space-y-3">
          {faqs.map((faq, index) => (
            <motion.div
              key={index}
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.4, delay: index * 0.05 }}
              className="glass-card rounded-xl overflow-hidden"
            >
              <button
                onClick={() => setOpenIndex(openIndex === index ? null : index)}
                className="w-full flex items-center justify-between p-5 text-left hover:bg-puck-surface-light/50 transition-colors"
              >
                <span className="text-sm font-medium text-foreground pr-4">
                  {faq.question}
                </span>
                <motion.div
                  animate={{ rotate: openIndex === index ? 180 : 0 }}
                  transition={{ duration: 0.2 }}
                >
                  <ChevronDown size={18} className="text-puck-muted flex-shrink-0" />
                </motion.div>
              </button>
              <AnimatePresence>
                {openIndex === index && (
                  <motion.div
                    initial={{ height: 0, opacity: 0 }}
                    animate={{ height: "auto", opacity: 1 }}
                    exit={{ height: 0, opacity: 0 }}
                    transition={{ duration: 0.3 }}
                  >
                    <div className="px-5 pb-5 text-sm text-puck-muted leading-relaxed">
                      {faq.answer}
                    </div>
                  </motion.div>
                )}
              </AnimatePresence>
            </motion.div>
          ))}
        </div>
      </div>
    </section>
  );
}
