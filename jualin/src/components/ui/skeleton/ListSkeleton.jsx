import Skeleton from './Skeleton';

/**
 * List Skeleton
 * Loading placeholder untuk list items
 */
export default function ListSkeleton({ count = 5 }) {
  return (
    <div className="space-y-4">
      {[...Array(count)].map((_, idx) => (
        <div key={idx} className="flex items-center gap-4 p-4 bg-white rounded-lg shadow">
          <Skeleton className="w-16 h-16" variant="rectangular" />
          <div className="flex-1 space-y-2">
            <Skeleton className="h-4 w-3/4" variant="text" />
            <Skeleton className="h-3 w-1/2" variant="text" />
          </div>
        </div>
      ))}
    </div>
  );
}
