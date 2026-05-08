import { useEffect, useState } from 'react';
import { sellerService } from '@/services/seller/sellerService';
import { orderService } from '@/services/seller/orderService';

/**
 * Hook to fetch seller dashboard data (products + orders in parallel)
 * @param {number|null} sellerId - Seller ID (used for orders)
 */
export const useSellerDashboard = (sellerId) => {
  const [products, setProducts] = useState([]);
  const [orders, setOrders] = useState([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    if (!sellerId) return;

    const load = async () => {
      setIsLoading(true);
      setError(null);

      try {
        const [productsResult, ordersData] = await Promise.all([
          sellerService.fetchMyProducts(),
          orderService.fetchSellerOrders({
            sellerId,
            status: 'all',
            limit: 10,
          }),
        ]);

        // fetchMyProducts now returns { products, totalProducts, totalPages, currentPage }
        const productsList = productsResult?.products ?? productsResult;
        setProducts(Array.isArray(productsList) ? productsList : []);
        setOrders(Array.isArray(ordersData) ? ordersData : []);
      } catch (err) {
        const error = err instanceof Error ? err : new Error('Failed to load dashboard data');
        setError(error);
        console.error('Failed to load seller dashboard data:', error);
      } finally {
        setIsLoading(false);
      }
    };

    load();
  }, [sellerId]);

  return {
    products,
    orders,
    isLoading,
    error,
  };
};

