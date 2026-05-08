import { useState, useCallback, useEffect, useRef } from 'react';

/**
 * Generic async state management hook
 * @param {Function} asyncFunction - Async function to execute
 * @param {Object} options - Configuration options
 * @param {boolean} options.immediate - Execute immediately on mount
 * @param {*} options.initialData - Initial data value
 * @param {Function} options.onSuccess - Success callback
 * @param {Function} options.onError - Error callback
 */
export const useAsync = (asyncFunction, options = {}) => {
  const { immediate = false, initialData = null, onSuccess, onError } = options;

  const [state, setState] = useState({
    data: initialData,
    loading: false,
    error: null,
  });

  const asyncFunctionRef = useRef(asyncFunction);
  const onSuccessRef = useRef(onSuccess);
  const onErrorRef = useRef(onError);

  useEffect(() => {
    asyncFunctionRef.current = asyncFunction;
    onSuccessRef.current = onSuccess;
    onErrorRef.current = onError;
  });

  const execute = useCallback(async () => {
    setState((prev) => ({ ...prev, loading: true, error: null }));

    try {
      const data = await asyncFunctionRef.current();
      setState({ data, loading: false, error: null });
      onSuccessRef.current?.(data);
      return data;
    } catch (error) {
      const err = error instanceof Error ? error : new Error('Unknown error');
      setState({ data: null, loading: false, error: err });
      onErrorRef.current?.(err);
      throw err;
    }
  }, []);

  const reset = useCallback(() => {
    setState({ data: initialData, loading: false, error: null });
  }, [initialData]);

  useEffect(() => {
    if (immediate) {
      execute();
    }
  }, []);

  return {
    ...state,
    execute,
    reset,
    isLoading: state.loading,
    isError: !!state.error,
    isSuccess: !state.loading && !state.error && state.data !== null,
  };
};
