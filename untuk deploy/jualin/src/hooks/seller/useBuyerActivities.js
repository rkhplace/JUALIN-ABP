import { useMemo, useState } from 'react';
import { usePagination } from '../common/usePagination';

/**
 * Hook to transform orders into buyer activities with search and pagination
 * @param {Array} orders - Orders array from API
 */
export const useBuyerActivities = (orders = []) => {
  const [searchQuery, setSearchQuery] = useState('');
  const activities = useMemo(() => {
    return orders.map((order) => {
      const dateTime = order.created_at
        ? new Date(order.created_at).toLocaleString('id-ID')
        : 'Recently';
      const [date, time] = dateTime.split(', ');

      return {
        id: order.id,
        buyerName: order.buyer?.name || 'Unknown Buyer',
        buyerId: order.buyer_id,
        productName: order.items?.[0]?.product?.name || 'Product',
        amount: order.total_amount || 0,
        status: order.status || 'pending',
        time: time || '',
        date: date || '',
        avatar: order.buyer?.avatar || '/ProfilePhoto.png',
      };
    });
  }, [orders]);

  const filteredActivities = useMemo(() => {
    if (!searchQuery.trim()) return activities;

    const q = searchQuery.toLowerCase();
    return activities.filter((activity) => {
      return [activity.buyerName, activity.productName, activity.status].some((field) =>
        String(field).toLowerCase().includes(q)
      );
    });
  }, [activities, searchQuery]);

  const pagination = usePagination(filteredActivities, {
    initialPage: 1,
    initialPerPage: 8,
  });

  return {
    activities: pagination.paginatedItems,
    allActivities: filteredActivities,
    searchQuery,
    setSearchQuery,
    pagination,
    totalCount: filteredActivities.length,
  };
};
