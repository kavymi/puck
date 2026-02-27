"use client";

import { motion } from "framer-motion";
import { ArrowRight, Sparkles, Zap } from "lucide-react";

export default function Hero() {
  return (
    <section className="relative min-h-screen flex items-center justify-center overflow-hidden pt-16">
      {/* Background orbs */}
      <div className="absolute inset-0 overflow-hidden pointer-events-none">
        <div className="absolute top-1/4 left-1/4 w-96 h-96 bg-puck-cyan/10 rounded-full blur-3xl animate-float" />
        <div className="absolute bottom-1/4 right-1/4 w-96 h-96 bg-puck-purple/10 rounded-full blur-3xl animate-float" style={{ animationDelay: "2s" }} />
        <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[600px] h-[600px] bg-puck-pink/5 rounded-full blur-3xl animate-pulse-glow" />
      </div>

      {/* Grid pattern overlay */}
      <div
        className="absolute inset-0 opacity-[0.03]"
        style={{
          backgroundImage: `linear-gradient(rgba(0,212,255,0.3) 1px, transparent 1px), linear-gradient(90deg, rgba(0,212,255,0.3) 1px, transparent 1px)`,
          backgroundSize: "60px 60px",
        }}
      />

      <div className="relative z-10 max-w-5xl mx-auto px-6 text-center">
        {/* Badge */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5 }}
          className="inline-flex items-center gap-2 px-4 py-1.5 rounded-full border border-puck-cyan/30 bg-puck-cyan/5 mb-8"
        >
          <Sparkles size={14} className="text-puck-cyan" />
          <span className="text-xs font-medium text-puck-cyan">
            Built for macOS — Powered by yt-dlp & ffmpeg
          </span>
        </motion.div>

        {/* Heading */}
        <motion.h1
          initial={{ opacity: 0, y: 30 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6, delay: 0.1 }}
          className="text-5xl md:text-7xl font-bold leading-tight mb-6"
        >
          <span className="text-foreground">Download </span>
          <span className="bg-gradient-to-r from-puck-cyan via-puck-purple to-puck-pink bg-clip-text text-transparent glow-text-cyan">
            anything.
          </span>
          <br />
          <span className="text-foreground">Convert </span>
          <span className="bg-gradient-to-r from-puck-purple to-puck-cyan bg-clip-text text-transparent glow-text-purple">
            everything.
          </span>
        </motion.h1>

        {/* Subtitle */}
        <motion.p
          initial={{ opacity: 0, y: 30 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6, delay: 0.2 }}
          className="text-lg md:text-xl text-puck-muted max-w-2xl mx-auto mb-10"
        >
          Puck is a lightning-fast media downloader for macOS. Grab videos and audio
          from YouTube, Vimeo, and 1000+ sites. Convert to ProRes, MP3, FLAC, and
          auto-import into your NLE.
        </motion.p>

        {/* CTA Buttons */}
        <motion.div
          initial={{ opacity: 0, y: 30 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6, delay: 0.3 }}
          className="flex flex-col sm:flex-row items-center justify-center gap-4"
        >
          <a
            href="#pricing"
            className="group flex items-center gap-2 px-8 py-3.5 rounded-xl bg-gradient-to-r from-puck-cyan to-puck-purple text-white font-semibold text-base hover:shadow-lg hover:shadow-puck-cyan/20 transition-all duration-300"
          >
            <Zap size={18} />
            Get Your License
            <ArrowRight size={16} className="group-hover:translate-x-1 transition-transform" />
          </a>
          <a
            href="#features"
            className="flex items-center gap-2 px-8 py-3.5 rounded-xl border border-puck-border text-puck-muted hover:text-foreground hover:border-puck-cyan/30 transition-all duration-300"
          >
            See Features
          </a>
        </motion.div>

        {/* Stats */}
        <motion.div
          initial={{ opacity: 0, y: 30 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6, delay: 0.5 }}
          className="mt-16 grid grid-cols-3 gap-8 max-w-lg mx-auto"
        >
          {[
            { value: "1000+", label: "Supported Sites" },
            { value: "4K+", label: "Video Quality" },
            { value: "< 1s", label: "Startup Time" },
          ].map((stat) => (
            <div key={stat.label} className="text-center">
              <div className="text-2xl md:text-3xl font-bold bg-gradient-to-r from-puck-cyan to-puck-purple bg-clip-text text-transparent">
                {stat.value}
              </div>
              <div className="text-xs text-puck-muted mt-1">{stat.label}</div>
            </div>
          ))}
        </motion.div>
      </div>
    </section>
  );
}
