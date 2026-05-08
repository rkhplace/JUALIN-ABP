/**
 * Base Skeleton Component
 * Untuk menampilkan placeholder saat loading
 */
export default function Skeleton({ className = '', variant = 'rectangular' }) {
  const variants = {
    rectangular: 'rounded-lg',
    circular: 'rounded-full',
    text: 'rounded',
  };

  return (
    <div
      className={`bg-[var(--color-neutral-200)] animate-pulse ${variants[variant]} ${className}`}
      aria-hidden="true"
    />
  );
}
