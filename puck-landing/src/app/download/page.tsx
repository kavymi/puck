"use client";

import { motion } from "framer-motion";
import { Apple, ArrowLeft, Download, HardDrive, Shield } from "lucide-react";
import Link from "next/link";

export default function DownloadPage() {
  return (
    <main className="bg-puck-gradient min-h-screen flex items-center justify-center px-6">
      {/* Background orbs */}
      <div className="absolute inset-0 overflow-hidden pointer-events-none">
        <div className="absolute top-1/4 right-1/4 w-96 h-96 bg-puck-cyan/10 rounded-full blur-3xl animate-float" />
        <div className="absolute bottom-1/4 left-1/4 w-96 h-96 bg-puck-purple/10 rounded-full blur-3xl animate-float" style={{ animationDelay: "2s" }} />
      </div>

      <div className="relative z-10 max-w-2xl w-full">
        {/* Back link */}
        <motion.div
          initial={{ opacity: 0, x: -20 }}
          animate={{ opacity: 1, x: 0 }}
          transition={{ duration: 0.4 }}
          className="mb-8"
        >
          <Link
            href="/"
            className="inline-flex items-center gap-2 text-sm text-puck-muted hover:text-puck-cyan transition-colors"
          >
            <ArrowLeft size={14} />
            Back to Home
          </Link>
        </motion.div>

        <motion.div
          initial={{ opacity: 0, y: 30 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6 }}
          className="glass-card rounded-2xl p-8 text-center"
        >
          {/* Icon */}
          <motion.div
            initial={{ scale: 0 }}
            animate={{ scale: 1 }}
            transition={{ type: "spring", duration: 0.5, delay: 0.2 }}
            className="w-20 h-20 rounded-2xl bg-gradient-to-br from-puck-cyan to-puck-purple flex items-center justify-center mx-auto mb-6"
          >
            <span className="text-white font-bold text-3xl">P</span>
          </motion.div>

          <h1 className="text-3xl font-bold text-foreground mb-2">Download Puck</h1>
          <p className="text-puck-muted mb-8">
            Lightning-fast media downloader for macOS
          </p>

          {/* Download button */}
          <a
            href="#"
            className="inline-flex items-center gap-3 px-8 py-4 rounded-xl bg-gradient-to-r from-puck-cyan to-puck-purple text-white font-semibold text-base hover:shadow-lg hover:shadow-puck-cyan/20 transition-all duration-300 mb-4"
          >
            <Download size={20} />
            Download for macOS
          </a>

          <p className="text-xs text-puck-muted mb-8">
            Requires macOS 14.0 (Sonoma) or later
          </p>

          {/* System info */}
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 text-left">
            <div className="bg-puck-surface rounded-xl p-4">
              <Apple size={18} className="text-puck-cyan mb-2" />
              <h3 className="text-sm font-semibold text-foreground mb-1">Native macOS</h3>
              <p className="text-xs text-puck-muted">
                Built with SwiftUI. Universal binary for Apple Silicon & Intel.
              </p>
            </div>
            <div className="bg-puck-surface rounded-xl p-4">
              <HardDrive size={18} className="text-puck-purple mb-2" />
              <h3 className="text-sm font-semibold text-foreground mb-1">Batteries Included</h3>
              <p className="text-xs text-puck-muted">
                yt-dlp & ffmpeg bundled. No Homebrew or CLI setup needed.
              </p>
            </div>
            <div className="bg-puck-surface rounded-xl p-4">
              <Shield size={18} className="text-puck-green mb-2" />
              <h3 className="text-sm font-semibold text-foreground mb-1">Signed & Notarized</h3>
              <p className="text-xs text-puck-muted">
                Code-signed and notarized by Apple for your security.
              </p>
            </div>
          </div>

          {/* License reminder */}
          <div className="mt-8 p-4 rounded-xl border border-puck-border bg-puck-surface/50">
            <p className="text-sm text-puck-muted">
              A license key is required to use Puck.{" "}
              <Link href="/#pricing" className="text-puck-cyan hover:underline">
                Get your license
              </Link>{" "}
              if you haven&apos;t already.
            </p>
          </div>
        </motion.div>
      </div>
    </main>
  );
}
