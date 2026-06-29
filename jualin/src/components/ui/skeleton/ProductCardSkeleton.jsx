import Skeleton from './Skeleton';

/**
 * Product Card Skeleton
 * Loading placeholder untuk product cards
 */
export default function ProductCardSkeleton() {
  return (
    <div className="flex flex-col items-start rounded-2xl bg-white p-3 shadow sm:p-5 md:p-6">
      {/* Image skeleton */}
      <Skeleton className="mb-3 h-32 w-full sm:mb-4 sm:h-52 md:h-60" variant="rectangular" />

      {/* Brand/Category skeleton */}
      <Skeleton className="mb-2 h-3 w-20 sm:h-4 sm:w-24" variant="text" />

      {/* Title skeleton */}
      <Skeleton className="mb-1 h-5 w-full sm:h-6" variant="text" />

      {/* Description skeleton */}
      <Skeleton className="mb-2 h-3 w-3/4 sm:h-4" variant="text" />

      {/* Price skeleton */}
      <Skeleton className="h-5 w-24 sm:h-6 sm:w-32" variant="text" />
    </div>
  );
}
