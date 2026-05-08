/**
 * Reusable Spinner Component
 * Untuk loading states di buttons, inline elements, dll
 */
export default function Spinner({ size = 'md', color = 'brand' }) {
  const sizes = {
    sm: 'w-4 h-4',
    md: 'w-6 h-6',
    lg: 'w-8 h-8',
    xl: 'w-12 h-12',
  };

  const colors = {
    brand: 'border-[var(--color-brand-primary)]',
    white: 'border-white',
    gray: 'border-[var(--color-neutral-400)]',
  };

  return (
    <div className="flex items-center justify-center">
      <div
        className={`${sizes[size]} border-2 ${colors[color]} border-t-transparent rounded-full animate-spin`}
        role="status"
        aria-label="Loading"
      />
    </div>
  );
}
