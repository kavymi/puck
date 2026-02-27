"use client";

import { motion } from "framer-motion";
import Link from "next/link";

export default function Footer() {
  return (
    <motion.footer
      initial={{ opacity: 0 }}
      whileInView={{ opacity: 1 }}
      viewport={{ once: true }}
      className="border-t border-puck-border/50 py-12 px-6"
    >
      <div className="max-w-6xl mx-auto">
        <div className="flex flex-col md:flex-row items-center justify-between gap-6">
          {/* Logo */}
          <div className="flex items-center gap-2">
            <div className="w-7 h-7 rounded-lg bg-gradient-to-br from-puck-cyan to-puck-purple flex items-center justify-center">
              <span className="text-white font-bold text-xs">P</span>
            </div>
            <span className="text-sm font-semibold text-foreground">Puck</span>
            <span className="text-xs text-puck-muted ml-2">
              Lightning-fast media downloader for macOS
            </span>
          </div>

          {/* Links */}
          <div className="flex items-center gap-6 text-sm text-puck-muted">
            <Link href="#features" className="hover:text-puck-cyan transition-colors">
              Features
            </Link>
            <Link href="#pricing" className="hover:text-puck-cyan transition-colors">
              Pricing
            </Link>
            <Link href="#faq" className="hover:text-puck-cyan transition-colors">
              FAQ
            </Link>
            <a
              href="https://github.com"
              target="_blank"
              rel="noopener noreferrer"
              className="hover:text-puck-cyan transition-colors"
            >
              GitHub
            </a>
          </div>
        </div>

        <div className="mt-8 pt-6 border-t border-puck-border/30 flex flex-col md:flex-row items-center justify-between gap-4">
          <p className="text-xs text-puck-muted">
            &copy; {new Date().getFullYear()} Puck. All rights reserved.
          </p>
          <p className="text-xs text-puck-muted">
            Built with SwiftUI for macOS 14+. Powered by yt-dlp & ffmpeg.
          </p>
        </div>
      </div>
    </motion.footer>
  );
}
