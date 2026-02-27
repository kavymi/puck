import crypto from "crypto";

const LICENSE_PREFIX = "PUCK";
const LICENSE_SECRET = process.env.LICENSE_SECRET || "puck-default-secret-change-me";

export function generateLicenseKey(customerId: string, plan: string): string {
  const timestamp = Date.now().toString(36).toUpperCase();
  const hash = crypto
    .createHmac("sha256", LICENSE_SECRET)
    .update(`${customerId}:${plan}:${timestamp}`)
    .digest("hex")
    .substring(0, 16)
    .toUpperCase();

  const planCode = plan === "team" ? "TM" : plan === "pro" ? "PR" : "ST";

  // Format: PUCK-PR-XXXX-XXXX-XXXX-XXXX
  const segments = [
    LICENSE_PREFIX,
    planCode,
    hash.substring(0, 4),
    hash.substring(4, 8),
    hash.substring(8, 12),
    hash.substring(12, 16),
  ];

  return segments.join("-");
}

export function validateLicenseFormat(key: string): boolean {
  const pattern = /^PUCK-(ST|PR|TM)-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}$/;
  return pattern.test(key);
}
