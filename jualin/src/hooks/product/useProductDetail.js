import { useEffect } from 'react';
import { useAsync } from '../common/useAsync';
import { productService } from '@/services/product/productService';

/**
 * Hook to fetch single product detail by ID
 * @param {number} productId - Product ID
 */
export const useProductDetail = (productId) => {
  const {
    data: product,
    loading,
    error,
    execute,
  } = useAsync(
    () => productService.fetchById(productId),
    {
      immediate: false,
      initialData: null,
    }
  );

  useEffect(() => {
    if (productId) {
      execute();
    }
  }, [productId]);

  return {
    product,
    isLoading: loading,
    error,
    refetch: execute,
  };
};
