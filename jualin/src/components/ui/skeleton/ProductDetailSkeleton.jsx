import Skeleton from './Skeleton';

/**
 * Product Detail Skeleton
 * Loading placeholder untuk product detail page
 */
export default function ProductDetailSkeleton() {
  return (
    <div className="max-w-7xl mx-auto px-4 py-8">
      {/* Main Detail Card Skeleton */}
      <div className="flex flex-col md:flex-row gap-8 items-start bg-white rounded-2xl shadow p-6">
        {/* Image Section - Single large image */}
        <Skeleton className="w-full md:w-1/2 h-80 rounded-2xl" variant="rectangular" />

        {/* Details Section */}
        <div className="flex-1 space-y-4 w-full">
          {/* Title - h2 equivalant */}
          <Skeleton className="h-9 w-3/4" variant="text" />

          {/* Category - h1 equivalent (large blue text) */}
          <Skeleton className="h-8 w-1/2" variant="text" />

          {/* Description */}
          <div className="space-y-2 pt-2">
            <Skeleton className="h-4 w-full" variant="text" />
            <Skeleton className="h-4 w-full" variant="text" />
            <Skeleton className="h-4 w-2/3" variant="text" />
          </div>

          {/* Price */}
          <Skeleton className="h-8 w-1/3 pt-2" variant="text" />

          {/* Buttons - Pill shaped */}
          <div className="flex gap-4 pt-4">
            <Skeleton className="h-10 w-32 rounded-full" variant="rectangular" />
            <Skeleton className="h-10 w-32 rounded-full" variant="rectangular" />
          </div>
        </div>
      </div>

      {/* Recommended Section Skeleton */}
      <div className="mt-16 space-y-6">
        <div className="flex justify-center">
          <Skeleton className="h-8 w-48" variant="text" />
        </div>
        <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-8">
          {[...Array(3)].map((_, idx) => (
            <div key={idx} className="space-y-4">
              <Skeleton className="w-full h-60 rounded-xl" variant="rectangular" />
              <Skeleton className="h-4 w-24" variant="text" />
              <Skeleton className="h-6 w-full" variant="text" />
              <Skeleton className="h-4 w-full" variant="text" />
              <Skeleton className="h-6 w-32" variant="text" />
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
