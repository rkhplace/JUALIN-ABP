import { BadgeCheck } from "lucide-react";

/**
 * Inline verified badge — shows a blue checkmark next to a seller's name.
 * Usage: <VerifiedBadge />
 * Props:
 *   size  — "sm" | "md" (default "md")
 */
export default function VerifiedBadge({ size = "md" }) {
  const dim = size === "sm" ? "w-4 h-4" : "w-5 h-5";
  return (
    <span
      title="Seller Terverifikasi"
      aria-label="Seller Terverifikasi"
      className="inline-flex items-center"
    >
      <BadgeCheck className={`${dim} text-blue-500 flex-shrink-0`} />
    </span>
  );
}
