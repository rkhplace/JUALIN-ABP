import { useQuery } from '@tanstack/react-query';
import { productService } from '@/services/product/productService';
import { queryKeys } from '@/lib/queryClient';

/**
 * Fetch single product detail with caching
 */
const fetchProductDetail = async (productId) => {
  if (!productId) {
    throw new Error('Product ID is required');
  }

  return await productService.fetchById(productId);
};

/**
 * Hook to fetch product detail with caching
 * @param {number} productId - Product ID
 */
export const useProductDetailQuery = (productId) => {
  const { data, isLoading, error, refetch } = useQuery({
    queryKey: queryKeys.productDetail(productId),
    queryFn: () => fetchProductDetail(productId),
    enabled: !!productId,
    staleTime: 10 * 60 * 1000,
    gcTime: 30 * 60 * 1000,
    retry: 2,
  });

  return {
    product: data,
    isLoading,
    error,
    refetch,
  };
};
