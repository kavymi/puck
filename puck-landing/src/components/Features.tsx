"use client";

import { motion } from "framer-motion";
import {
  Download,
  Music,
  Film,
  Layers,
  MonitorPlay,
  Gauge,
  Shield,
  FolderSync,
} from "lucide-react";

const features = [
  {
    icon: Download,
    title: "Universal Downloads",
    description:
      "Grab videos and audio from YouTube, Vimeo, Twitter, TikTok, and 1000+ sites with a single paste.",
    color: "text-puck-cyan",
    glow: "group-hover:shadow-puck-cyan/20",
  },
  {
    icon: Music,
    title: "All Audio Formats",
    description:
      "Extract audio in MP3, FLAC, WAV, M4A, Opus, or OGG. Perfect for music, podcasts, and sound design.",
    color: "text-puck-purple-light",
    glow: "group-hover:shadow-puck-purple/20",
  },
  {
    icon: Film,
    title: "ProRes Conversion",
    description:
      "Convert to Apple ProRes (Proxy, LT, HQ) for seamless editing in professional NLE workflows.",
    color: "text-puck-pink",
    glow: "group-hover:shadow-puck-pink/20",
  },
  {
    icon: MonitorPlay,
    title: "NLE Auto-Import",
    description:
      "Automatically import downloads into Premiere Pro, DaVinci Resolve, Final Cut Pro, or After Effects.",
    color: "text-puck-green",
    glow: "group-hover:shadow-puck-green/20",
  },
  {
    icon: Layers,
    title: "Batch Downloads",
    description:
      "Download entire playlists with concurrent processing. Queue up dozens of videos at once.",
    color: "text-puck-cyan-light",
    glow: "group-hover:shadow-puck-cyan/20",
  },
  {
    icon: Gauge,
    title: "Blazing Fast",
    description:
      "Native macOS app built with SwiftUI. Sub-second startup, minimal memory usage, zero Electron bloat.",
    color: "text-puck-purple",
    glow: "group-hover:shadow-puck-purple/20",
  },
  {
    icon: Shield,
    title: "Privacy First",
    description:
      "No telemetry, no tracking, no accounts required. Your downloads stay on your machine.",
    color: "text-puck-cyan",
    glow: "group-hover:shadow-puck-cyan/20",
  },
  {
    icon: FolderSync,
    title: "Smart Organization",
    description:
      "Custom output paths, automatic file naming, and format-based folder organization.",
    color: "text-puck-pink",
    glow: "group-hover:shadow-puck-pink/20",
  },
];

const containerVariants = {
  hidden: {},
  visible: {
    transition: {
      staggerChildren: 0.08,
    },
  },
};

const itemVariants = {
  hidden: { opacity: 0, y: 30 },
  visible: { opacity: 1, y: 0, transition: { duration: 0.5 } },
};

export default function Features() {
  return (
    <section id="features" className="relative py-32 px-6">
      <div className="max-w-6xl mx-auto">
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
              Everything you need
            </span>
          </h2>
          <p className="text-puck-muted text-lg max-w-xl mx-auto">
            Professional-grade media downloading and conversion, wrapped in a
            beautiful native macOS experience.
          </p>
        </motion.div>

        {/* Feature grid */}
        <motion.div
          variants={containerVariants}
          initial="hidden"
          whileInView="visible"
          viewport={{ once: true, margin: "-100px" }}
          className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4"
        >
          {features.map((feature) => (
            <motion.div
              key={feature.title}
              variants={itemVariants}
              className={`group p-6 rounded-2xl glass-card glass-card-hover transition-all duration-300 hover:shadow-lg ${feature.glow}`}
            >
              <div className={`mb-4 ${feature.color}`}>
                <feature.icon size={28} strokeWidth={1.5} />
              </div>
              <h3 className="text-base font-semibold text-foreground mb-2">
                {feature.title}
              </h3>
              <p className="text-sm text-puck-muted leading-relaxed">
                {feature.description}
              </p>
            </motion.div>
          ))}
        </motion.div>
      </div>
    </section>
  );
}
