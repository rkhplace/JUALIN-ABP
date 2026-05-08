import { QueryClient } from '@tanstack/react-query';

/**
 * Query Client Configuration
 * Centralized cache & data fetching configuration
 */
export const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 5 * 60 * 1000,
      gcTime: 10 * 60 * 1000,
      refetchOnWindowFocus: true,
      refetchOnReconnect: true,
      retry: 1,
      refetchInterval: false,
      refetchOnMount: 'always',
    },
    mutations: {
      retry: 1,
    },
  },
});

/**
 * Query Keys
 * Centralized query key management untuk consistency
 */
export const queryKeys = {
  products: ['products'],
  productDetail: (id) => ['products', 'detail', id],
  productsByCategory: (category) => ['products', 'category', category],

  sellerProducts: (sellerId) => ['seller', sellerId, 'products'],
  sellerIncome: (sellerId, period) => ['seller', sellerId, 'income', period],
  sellerOrders: (sellerId) => ['seller', sellerId, 'orders'],
  sellerDashboard: (sellerId) => ['seller', sellerId, 'dashboard'],
  sellerInfo: (sellerId) => ['seller', sellerId, 'info'],

  transactions: (params) => ['transactions', params],

  user: ['user'],
  userProfile: (userId) => ['user', userId, 'profile'],
  purchaseHistory: (userId) => ['user', userId, 'purchases'],

  chats: ['chats'],
  chatMessages: (chatId) => ['chats', chatId, 'messages'],
};
