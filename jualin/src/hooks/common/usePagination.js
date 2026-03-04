import { useState, useMemo, useCallback } from 'react';

/**
 * Pagination hook
 * @param {Array} items - Items to paginate
 * @param {Object} options - Pagination options
 * @param {number} options.initialPage - Initial page number (default: 1)
 * @param {number} options.initialPerPage - Items per page (default: 8)
 */
export const usePagination = (items, options = {}) => {
  const { initialPage = 1, initialPerPage = 8 } = options;

  const [currentPage, setCurrentPage] = useState(initialPage);
  const [perPage, setPerPage] = useState(initialPerPage);

  const totalPages = useMemo(
    () => Math.max(1, Math.ceil(items.length / perPage)),
    [items.length, perPage]
  );

  const paginatedItems = useMemo(() => {
    const start = (currentPage - 1) * perPage;
    return items.slice(start, start + perPage);
  }, [items, currentPage, perPage]);

  const goToPage = useCallback((page) => {
    setCurrentPage(Math.max(1, Math.min(page, totalPages)));
  }, [totalPages]);

  const nextPage = useCallback(() => {
    setCurrentPage((prev) => Math.min(prev + 1, totalPages));
  }, [totalPages]);

  const prevPage = useCallback(() => {
    setCurrentPage((prev) => Math.max(prev - 1, 1));
  }, []);

  const changePerPage = useCallback((newPerPage) => {
    setPerPage(newPerPage);
    setCurrentPage(1); 
  }, []);

  return {
    currentPage,
    perPage,
    totalPages,
    totalItems: items.length,
    paginatedItems,
    goToPage,
    nextPage,
    prevPage,
    changePerPage,
    hasNextPage: currentPage < totalPages,
    hasPrevPage: currentPage > 1,
  };
};
