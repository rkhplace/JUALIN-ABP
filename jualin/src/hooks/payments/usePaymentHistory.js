import { useEffect, useMemo, useState } from "react";
import { paymentService } from "@/services";

export default function usePaymentHistory() {
  const [payments, setPayments] = useState([]);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState(null);
  const [statusFilter, setStatusFilter] = useState("all");

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

  const filteredPayments = useMemo(() => {
    if (statusFilter === "all") return payments;

    return payments.filter((payment) => {
      const status = String(payment?.transaction_status || "").toLowerCase();

      if (statusFilter === "completed") {
        return ["verified", "completed", "settlement", "capture", "paid"].includes(
          status
        );
      }

      if (statusFilter === "refunded") {
        return ["refunded", "cancelled"].includes(status);
      }

      return status === statusFilter;
    });
  }, [payments, statusFilter]);

  const totalPages = Math.max(
    1,
    Math.ceil((filteredPayments?.length || 0) / itemsPerPage)
  );
  const paginated = useMemo(() => {
    const start = (currentPage - 1) * itemsPerPage;
    return (filteredPayments || []).slice(start, start + itemsPerPage);
  }, [filteredPayments, currentPage, itemsPerPage]);

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
    filteredCount: filteredPayments.length,
    statusFilter,
    setStatusFilter: (status) => {
      setStatusFilter(status);
      setCurrentPage(1);
    },
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
