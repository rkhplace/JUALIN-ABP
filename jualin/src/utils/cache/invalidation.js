import { queryClient, queryKeys } from "@/lib/queryClient";
import { productService } from "@/services/product/productService";

/**
 * Cache Invalidation Utilities
 * Functions to invalidate specific caches when data changes
 */

/**
 * Invalidate all products cache
 * Call this after creating, updating, or deleting a product
 */
export const invalidateProducts = async () => {
  await queryClient.invalidateQueries({
    queryKey: queryKeys.products,
  });
};

/**
 * Invalidate specific product detail
 * Call this after updating a specific product
 */
export const invalidateProductDetail = async (productId) => {
  await queryClient.invalidateQueries({
    queryKey: queryKeys.productDetail(productId),
  });
};

/**
 * Invalidate seller income data
 * Call this after a transaction is completed
 */
export const invalidateSellerIncome = async (sellerId) => {
  await queryClient.invalidateQueries({
    queryKey: ["seller", sellerId, "income"],
    exact: false,
  });
};

/**
 * Invalidate seller dashboard data
 * Call this after any seller-related change
 */
export const invalidateSellerDashboard = async (sellerId) => {
  await Promise.all([
    queryClient.invalidateQueries({
      queryKey: queryKeys.sellerProducts(sellerId),
    }),
    queryClient.invalidateQueries({
      queryKey: queryKeys.sellerOrders(sellerId),
    }),
    queryClient.invalidateQueries({
      queryKey: queryKeys.sellerDashboard(sellerId),
    }),
    invalidateSellerIncome(sellerId),
  ]);
};

/**
 * Invalidate user data
 * Call this after profile update or login/logout
 */
export const invalidateUser = async () => {
  await queryClient.invalidateQueries({
    queryKey: queryKeys.user,
  });
};

/**
 * Invalidate chat data
 * Call this after sending/receiving messages
 */
export const invalidateChats = async (chatId = null) => {
  if (chatId) {
    await queryClient.invalidateQueries({
      queryKey: queryKeys.chatMessages(chatId),
    });
  } else {
    await queryClient.invalidateQueries({
      queryKey: queryKeys.chats,
    });
  }
};

/**
 * Clear all cache
 * Use sparingly - only when necessary (e.g., logout)
 */
export const clearAllCache = async () => {
  await queryClient.clear();
};

/**
 * Prefetch data for faster navigation
 */
export const prefetchProductDetail = async (productId) => {
  await queryClient.prefetchQuery({
    queryKey: queryKeys.productDetail(productId),
    queryFn: () => productService.fetchById(productId),
  });
};

/**
 * Set data manually (optimistic updates)
 */
export const setProductInCache = (productId, data) => {
  queryClient.setQueryData(queryKeys.productDetail(productId), data);
};

/**
 * Get cached data without fetching
 */
export const getCachedProduct = (productId) => {
  return queryClient.getQueryData(queryKeys.productDetail(productId));
};
