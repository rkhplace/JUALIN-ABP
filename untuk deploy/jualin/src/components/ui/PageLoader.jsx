import Spinner from './Spinner';

/**
 * Full Page Loader
 * Untuk loading state saat halaman pertama kali load
 */
export default function PageLoader({ message = 'Memuat...' }) {
  return (
    <div className="min-h-screen flex flex-col items-center justify-center bg-[var(--color-background-secondary)]">
      <Spinner size="xl" color="brand" />
      <p className="mt-4 text-[var(--color-text-secondary)] font-medium">
        {message}
      </p>
    </div>
  );
}
