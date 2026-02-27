"use client";

import { motion } from "framer-motion";
import { Download, Menu, X } from "lucide-react";
import Link from "next/link";
import { useState } from "react";

export default function Navbar() {
  const [mobileOpen, setMobileOpen] = useState(false);

  return (
    <motion.nav
      initial={{ y: -20, opacity: 0 }}
      animate={{ y: 0, opacity: 1 }}
      transition={{ duration: 0.5 }}
      className="fixed top-0 left-0 right-0 z-50 glass-card border-b border-puck-border/50"
    >
      <div className="max-w-7xl mx-auto px-6 h-16 flex items-center justify-between">
        {/* Logo */}
        <Link href="/" className="flex items-center gap-2 group">
          <div className="w-8 h-8 rounded-lg bg-gradient-to-br from-puck-cyan to-puck-purple flex items-center justify-center">
            <span className="text-white font-bold text-sm">P</span>
          </div>
          <span className="text-lg font-bold text-foreground group-hover:text-puck-cyan transition-colors">
            Puck
          </span>
        </Link>

        {/* Desktop Nav */}
        <div className="hidden md:flex items-center gap-8">
          <a href="#features" className="text-sm text-puck-muted hover:text-puck-cyan transition-colors">
            Features
          </a>
          <a href="#pricing" className="text-sm text-puck-muted hover:text-puck-cyan transition-colors">
            Pricing
          </a>
          <a href="#faq" className="text-sm text-puck-muted hover:text-puck-cyan transition-colors">
            FAQ
          </a>
          <Link
            href="/download"
            className="flex items-center gap-2 px-4 py-2 rounded-lg bg-gradient-to-r from-puck-cyan to-puck-purple text-white text-sm font-medium hover:opacity-90 transition-opacity"
          >
            <Download size={14} />
            Download
          </Link>
        </div>

        {/* Mobile toggle */}
        <button
          onClick={() => setMobileOpen(!mobileOpen)}
          className="md:hidden text-puck-muted hover:text-puck-cyan"
        >
          {mobileOpen ? <X size={24} /> : <Menu size={24} />}
        </button>
      </div>

      {/* Mobile Nav */}
      {mobileOpen && (
        <motion.div
          initial={{ opacity: 0, height: 0 }}
          animate={{ opacity: 1, height: "auto" }}
          exit={{ opacity: 0, height: 0 }}
          className="md:hidden glass-card border-t border-puck-border/50 px-6 py-4 space-y-3"
        >
          <a href="#features" className="block text-sm text-puck-muted hover:text-puck-cyan" onClick={() => setMobileOpen(false)}>
            Features
          </a>
          <a href="#pricing" className="block text-sm text-puck-muted hover:text-puck-cyan" onClick={() => setMobileOpen(false)}>
            Pricing
          </a>
          <a href="#faq" className="block text-sm text-puck-muted hover:text-puck-cyan" onClick={() => setMobileOpen(false)}>
            FAQ
          </a>
          <Link
            href="/download"
            className="flex items-center gap-2 px-4 py-2 rounded-lg bg-gradient-to-r from-puck-cyan to-puck-purple text-white text-sm font-medium w-fit"
            onClick={() => setMobileOpen(false)}
          >
            <Download size={14} />
            Download
          </Link>
        </motion.div>
      )}
    </motion.nav>
  );
}
