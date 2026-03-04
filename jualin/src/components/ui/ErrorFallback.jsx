"use client";

export const ErrorFallback = ({ error, resetError }) => {
  return (
    <div className="flex flex-col items-center justify-center min-h-[400px] p-8">
      <div className="max-w-md w-full bg-red-50 border border-red-200 rounded-lg p-6">
        <h2 className="text-xl font-bold text-red-900 mb-2">Something went wrong</h2>
        <p className="text-red-700 mb-4">{error?.message || 'An unexpected error occurred'}</p>
        {resetError && (
          <button
            onClick={resetError}
            className="px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 transition-colors"
          >
            Try again
          </button>
        )}
      </div>
    </div>
  );
};

export default ErrorFallback;
