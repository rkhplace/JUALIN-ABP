import Skeleton from './Skeleton';

/**
 * Product Card Skeleton
 * Loading placeholder untuk product cards
 */
export default function ProductCardSkeleton() {
  return (
    <div className="bg-white rounded-2xl shadow p-6 flex flex-col items-start">
      {/* Image skeleton */}
      <Skeleton className="w-full h-60 mb-4" variant="rectangular" />

      {/* Brand/Category skeleton */}
      <Skeleton className="h-4 w-24 mb-2" variant="text" />

      {/* Title skeleton */}
      <Skeleton className="h-6 w-full mb-1" variant="text" />

      {/* Description skeleton */}
      <Skeleton className="h-4 w-3/4 mb-2" variant="text" />

      {/* Price skeleton */}
      <Skeleton className="h-6 w-32" variant="text" />
    </div>
  );
}
