import { useAsync } from '../common/useAsync';
import { productService } from '@/services/product/productService';

export const useProducts = () => {
  const {
    data: products,
    loading,
    error,
    execute: refetch,
  } = useAsync(
    () => productService.fetchAll(),
    {
      immediate: true,
      initialData: [],
      onError: (err) => {
        console.error('Failed to load products:', err);
      },
    }
  );

  return {
    products: products || [],
    isLoading: loading,
    error,
    refetch,
  };
};
