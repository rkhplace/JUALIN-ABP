import { useQuery } from "@tanstack/react-query";
import { queryKeys } from "@/lib/queryClient";
import { productService } from "@/services/product/productService";

const fetchProducts = async ({ queryKey }) => {
  const [_, params] = queryKey;
  return await productService.fetchAll(params);
};

export const useProductsQuery = (params = {}, options = {}) => {
  const {
    enabled = true,
    staleTime = 5 * 60 * 1000,
    gcTime = 10 * 60 * 1000,
    refetchOnWindowFocus = true,
    retry = 2,
    keepPreviousData = true,
  } = options;

  const { data, isLoading, error, refetch } = useQuery({
    queryKey: [queryKeys.products, params],
    queryFn: fetchProducts,
    enabled,
    staleTime,
    gcTime,
    keepPreviousData,
    refetchOnWindowFocus,
    retry,
  });

  const defaultData = {
    products: [],
    totalProducts: 0,
    totalPages: 1,
    currentPage: 1,
  };
  const finalData = data || defaultData;

  return {
    data: finalData,
    products: finalData.products,
    isLoading,
    error,
    refetch,
  };
};
