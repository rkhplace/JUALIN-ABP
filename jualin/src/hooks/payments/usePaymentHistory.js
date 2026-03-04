import { useEffect, useMemo, useState } from "react";
import { paymentService } from "@/services";

export default function usePaymentHistory() {
  const [payments, setPayments] = useState([]);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState(null);

  const [itemsPerPage, setItemsPerPage] = useState(10);
  const [currentPage, setCurrentPage] = useState(1);

  const fetchHistory = async () => {
    setIsLoading(true);
    setError(null);
    try {
      const data = await paymentService.getHistory();
      setPayments(data || []);
      setCurrentPage(1);
    } catch (err) {
      setError(err);
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchHistory();
  }, []);

  const totalAmount = useMemo(
    () => payments.reduce((acc, p) => acc + Number(p?.gross_amount || 0), 0),
    [payments]
  );

  const totalPages = Math.max(
    1,
    Math.ceil((payments?.length || 0) / itemsPerPage)
  );
  const paginated = useMemo(() => {
    const start = (currentPage - 1) * itemsPerPage;
    return (payments || []).slice(start, start + itemsPerPage);
  }, [payments, currentPage, itemsPerPage]);

  const formatCurrency = (amount) =>
    new Intl.NumberFormat("id-ID", {
      style: "currency",
      currency: "IDR",
      minimumFractionDigits: 0,
    }).format(Number(amount || 0));

  return {
    payments,
    isLoading,
    error,
    totalAmount,
    paginated,
    pagination: {
      currentPage,
      totalPages,
      itemsPerPage,
      setItemsPerPage: (n) => {
        setItemsPerPage(n);
        setCurrentPage(1);
      },
      goToPage: (p) => setCurrentPage(Math.min(Math.max(1, p), totalPages)),
      next: () => setCurrentPage((p) => Math.min(p + 1, totalPages)),
      prev: () => setCurrentPage((p) => Math.max(p - 1, 1)),
    },
    refetch: fetchHistory,
    formatCurrency,
  };
}
