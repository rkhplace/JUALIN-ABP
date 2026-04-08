import { useEffect, useState } from 'react';
import { sellerService } from '@/services/seller/sellerService';
import { orderService } from '@/services/seller/orderService';

/**
 * Hook to fetch seller dashboard data (products + orders in parallel)
 * @param {number|null} sellerId - Seller ID
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
        const [productsData, ordersData] = await Promise.all([
          sellerService.fetchMyProducts(sellerId),
          orderService.fetchSellerOrders({
            sellerId,
            status: 'all',
            limit: 10,
          }),
        ]);

        setProducts(Array.isArray(productsData) ? productsData : []);
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
