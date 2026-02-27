"use client";

import { motion } from "framer-motion";
import { CheckCircle, Copy, Key, Loader2, RefreshCw } from "lucide-react";
import Link from "next/link";
import { useSearchParams } from "next/navigation";
import { Suspense, useCallback, useEffect, useState } from "react";

interface LicenseData {
  status: string;
  licenseKey?: string;
  plan?: string;
  email?: string;
  message?: string;
}

function SuccessContent() {
  const searchParams = useSearchParams();
  const sessionId = searchParams.get("session_id");
  const [data, setData] = useState<LicenseData | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [copied, setCopied] = useState(false);

  const fetchLicense = useCallback(async () => {
    if (!sessionId) {
      setError("No session ID found. Please check your email for your license key.");
      setLoading(false);
      return;
    }

    try {
      const res = await fetch(`/api/license?session_id=${sessionId}`);
      const result = await res.json();

      if (res.ok) {
        setData(result);
      } else {
        setError(result.error || "Failed to retrieve license");
      }
    } catch {
      setError("Network error. Please try again.");
    } finally {
      setLoading(false);
    }
  }, [sessionId]);

  useEffect(() => {
    fetchLicense();
  }, [fetchLicense]);

  const copyToClipboard = async () => {
    if (data?.licenseKey) {
      await navigator.clipboard.writeText(data.licenseKey);
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    }
  };

  const retry = () => {
    setLoading(true);
    setError(null);
    fetchLicense();
  };

  return (
    <main className="bg-puck-gradient min-h-screen flex items-center justify-center px-6">
      {/* Background orbs */}
      <div className="absolute inset-0 overflow-hidden pointer-events-none">
        <div className="absolute top-1/3 left-1/3 w-96 h-96 bg-puck-green/10 rounded-full blur-3xl animate-float" />
        <div className="absolute bottom-1/3 right-1/3 w-96 h-96 bg-puck-cyan/10 rounded-full blur-3xl animate-float" style={{ animationDelay: "3s" }} />
      </div>

      <motion.div
        initial={{ opacity: 0, y: 30 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.6 }}
        className="relative z-10 max-w-lg w-full"
      >
        <div className="glass-card rounded-2xl p-8 text-center">
          {loading ? (
            <div className="py-12">
              <Loader2 size={48} className="text-puck-cyan animate-spin mx-auto mb-4" />
              <p className="text-puck-muted">Retrieving your license key...</p>
            </div>
          ) : error ? (
            <div className="py-8">
              <div className="w-16 h-16 rounded-full bg-red-500/10 flex items-center justify-center mx-auto mb-4">
                <span className="text-3xl">!</span>
              </div>
              <h2 className="text-xl font-bold text-foreground mb-2">Something went wrong</h2>
              <p className="text-sm text-puck-muted mb-6">{error}</p>
              <button
                onClick={retry}
                className="flex items-center gap-2 mx-auto px-6 py-2.5 rounded-xl border border-puck-border text-sm text-foreground hover:border-puck-cyan/40 transition-colors"
              >
                <RefreshCw size={14} />
                Try Again
              </button>
            </div>
          ) : data?.status === "pending" ? (
            <div className="py-8">
              <Loader2 size={48} className="text-puck-cyan animate-spin mx-auto mb-4" />
              <h2 className="text-xl font-bold text-foreground mb-2">Generating your license...</h2>
              <p className="text-sm text-puck-muted mb-6">{data.message}</p>
              <button
                onClick={retry}
                className="flex items-center gap-2 mx-auto px-6 py-2.5 rounded-xl border border-puck-border text-sm text-foreground hover:border-puck-cyan/40 transition-colors"
              >
                <RefreshCw size={14} />
                Refresh
              </button>
            </div>
          ) : (
            <>
              {/* Success state */}
              <motion.div
                initial={{ scale: 0 }}
                animate={{ scale: 1 }}
                transition={{ type: "spring", duration: 0.5, delay: 0.2 }}
              >
                <CheckCircle size={64} className="text-puck-green mx-auto mb-4" />
              </motion.div>

              <h1 className="text-2xl font-bold text-foreground mb-2">
                Welcome to Puck!
              </h1>
              <p className="text-sm text-puck-muted mb-2">
                Your <span className="text-puck-cyan font-semibold capitalize">{data?.plan}</span> subscription is active.
              </p>
              {data?.email && (
                <p className="text-xs text-puck-muted mb-8">{data.email}</p>
              )}

              {/* License key display */}
              <div className="mb-8">
                <div className="flex items-center gap-2 justify-center mb-3">
                  <Key size={16} className="text-puck-cyan" />
                  <span className="text-sm font-medium text-puck-muted">Your License Key</span>
                </div>
                <div className="relative group">
                  <div className="bg-puck-surface border border-puck-border rounded-xl p-4 font-mono text-lg text-puck-cyan tracking-wider glow-cyan">
                    {data?.licenseKey}
                  </div>
                  <button
                    onClick={copyToClipboard}
                    className="absolute top-3 right-3 p-2 rounded-lg bg-puck-surface-light hover:bg-puck-border transition-colors"
                    title="Copy to clipboard"
                  >
                    {copied ? (
                      <CheckCircle size={16} className="text-puck-green" />
                    ) : (
                      <Copy size={16} className="text-puck-muted" />
                    )}
                  </button>
                </div>
              </div>

              {/* Instructions */}
              <div className="text-left bg-puck-surface rounded-xl p-5 mb-8">
                <h3 className="text-sm font-semibold text-foreground mb-3">How to activate:</h3>
                <ol className="space-y-2 text-sm text-puck-muted">
                  <li className="flex gap-2">
                    <span className="text-puck-cyan font-bold">1.</span>
                    Download and install Puck from the Downloads page
                  </li>
                  <li className="flex gap-2">
                    <span className="text-puck-cyan font-bold">2.</span>
                    Open Puck and go to Settings → License
                  </li>
                  <li className="flex gap-2">
                    <span className="text-puck-cyan font-bold">3.</span>
                    Paste your license key and click Activate
                  </li>
                </ol>
              </div>

              <div className="flex flex-col sm:flex-row gap-3">
                <Link
                  href="/download"
                  className="flex-1 flex items-center justify-center gap-2 px-6 py-3 rounded-xl bg-gradient-to-r from-puck-cyan to-puck-purple text-white font-semibold text-sm hover:opacity-90 transition-opacity"
                >
                  Download Puck
                </Link>
                <Link
                  href="/"
                  className="flex-1 flex items-center justify-center px-6 py-3 rounded-xl border border-puck-border text-sm text-puck-muted hover:text-foreground hover:border-puck-cyan/30 transition-all"
                >
                  Back to Home
                </Link>
              </div>
            </>
          )}
        </div>
      </motion.div>
    </main>
  );
}

export default function SuccessPage() {
  return (
    <Suspense
      fallback={
        <main className="bg-puck-gradient min-h-screen flex items-center justify-center">
          <Loader2 size={48} className="text-puck-cyan animate-spin" />
        </main>
      }
    >
      <SuccessContent />
    </Suspense>
  );
}
