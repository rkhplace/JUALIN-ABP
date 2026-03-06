"use client"

import useMidtransPayment from "@/app/(private)/product/hooks/useMidtransPayment";
import { useState } from "react";
import { escrowService } from "@/services";

/**
 * PurchaseHistorySection
 * Purchase history display with date filter, summary, and pagination
 * Used in profile/edit/page.jsx
 */
export function PurchaseHistorySection({
  purchases,
  totalAmount,
  pagination,
  formatCurrency,
  isLoading,
  onExport,
  onRefresh
}) {
  const { resumePayment, loading: isPaymentLoading, toast: paymentToast } = useMidtransPayment();
  const [escrowLoading, setEscrowLoading] = useState(false);
  const [escrowToast, setEscrowToast] = useState(null);
  const [refundModalOpen, setRefundModalOpen] = useState(false);
  const [refundOrderId, setRefundOrderId] = useState(null);

  const initiateRefund = (transactionId, e) => {
    e.stopPropagation(); // prevent row click
    setRefundOrderId(transactionId);
    setRefundModalOpen(true);
  };

  const confirmRefund = async () => {
    if (!refundOrderId) return;

    setEscrowLoading(true);
    try {
      await escrowService.refundPayment(refundOrderId);
      setEscrowToast({ type: "success", message: "Refund successful. Funds added to your wallet." });
      onRefresh();
    } catch (err) {
      setEscrowToast({ type: "error", message: err?.response?.data?.message || "Refund failed." });
    } finally {
      setEscrowLoading(false);
      setRefundModalOpen(false);
      setTimeout(() => setEscrowToast(null), 3000);
    }
  };

  if (isLoading) {
    return <div className="text-center py-12 text-gray-500">Loading purchases...</div>;
  }

  return (
    <div>
      {/* Toast Notification */}
      {paymentToast && (
        <div className={`fixed top-4 right-4 z-50 px-4 py-2 rounded-lg shadow-lg ${paymentToast.type === 'error' ? 'bg-red-500 text-white' :
          paymentToast.type === 'success' ? 'bg-green-500 text-white' :
            'bg-blue-500 text-white'
          }`}>
          {paymentToast.message}
        </div>
      )}

      {isPaymentLoading && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/20 backdrop-blur-sm">
          <div className="bg-white p-4 rounded-lg shadow-lg flex items-center gap-3">
            <div className="w-5 h-5 border-2 border-red-500 border-t-transparent rounded-full animate-spin"></div>
            <span className="font-medium text-gray-700">Mempersiapkan Pembayaran...</span>
          </div>
        </div>
      )}

      <div className="mb-8">

        <h1 className="text-2xl font-semibold text-[#1F1F1F] mb-4">
          Riwayat Pembelian
        </h1>
        <div className="flex items-center justify-between">
          <div />
          <div className="flex gap-4">
            <button
              onClick={onExport}
              className="group relative text-sm font-medium text-[#E53935] hover:text-[#D32F2F] transition-colors flex items-center gap-1"
            >
              <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4" />
              </svg>
              <span className="relative">
                Export to CSV
                <span className="absolute left-0 bottom-0 w-0 h-[2px] bg-[#E53935] transition-all duration-300 group-hover:w-full"></span>
              </span>
            </button>
            <button
              onClick={onRefresh}
              className="text-sm font-medium text-[#E53935] hover:text-[#D32F2F] transition-colors"
            >
              {isLoading ? "Refreshing..." : "Refresh"}
            </button>
          </div>
        </div>
      </div>

      {/* Escrow Action Toast */}
      {escrowToast && (
        <div
          className={`mb-6 rounded-lg p-4 shadow-sm text-sm border font-medium ${escrowToast.type === "success"
            ? "bg-green-50 text-green-700 border-green-200"
            : "bg-red-50 text-red-700 border-red-200"
            }`}
        >
          {escrowToast.message}
        </div>
      )}

      {/* Total card */}
      <div className="bg-white border border-gray-300 rounded-xl p-6 mb-8 shadow-md">
        <p className="text-sm font-medium text-gray-500 mb-1">Total Amount</p>
        <h2 className="text-3xl font-bold text-[#1F1F1F]">
          {formatCurrency(totalAmount)}
        </h2>
      </div>

      {/* Payment List */}
      {purchases && purchases.length > 0 ? (
        <div className="space-y-4">
          {purchases.map((p) => {
            const status = String(p?.transaction_status || "").toLowerCase();
            const isPending = status === "pending";
            const isWaitingCOD = status === "waiting_cod";
            const isCompleted = status === "completed";
            const isRefunded = status === "refunded";

            // Status Badge Styles
            const statusStyles =
              status === "pending"
                ? "bg-yellow-100 text-yellow-700 border-yellow-200"
                : status === "waiting_cod"
                  ? "bg-orange-100 text-orange-700 border-orange-200"
                  : status === "settlement" ||
                    status === "capture" ||
                    status === "paid" ||
                    status === "completed"
                    ? "bg-green-100 text-green-700 border-green-200"
                    : status === "refunded"
                      ? "bg-purple-100 text-purple-700 border-purple-200"
                      : "bg-red-100 text-red-700 border-red-200";

            // Data extraction
            const orderLabel = `Order #${p?.order_id || "-"}`;
            const title = p?.first_item_name || orderLabel;
            const subtitle = p?.seller_name || orderLabel;

            // Date formatting (keeping ID locale as per app context)
            const when = p?.transaction_time
              ? new Date(p.transaction_time).toLocaleDateString('id-ID', {
                day: 'numeric',
                month: 'short',
                year: 'numeric'
              })
              : "";

            // Format status label
            let displayStatus = status;
            if (isWaitingCOD) displayStatus = "Waiting COD";
            if (isCompleted) displayStatus = "Completed";
            if (isRefunded) displayStatus = "Refunded";

            return (
              <div
                key={p?.order_id}
                className={`w-full text-left group bg-white border border-gray-300 p-5 rounded-xl transition-all relative shadow-md
                  ${isPending
                    ? 'cursor-pointer hover:bg-[#F7F7F8] hover:shadow-lg hover:border-red-200 ring-1 ring-inset ring-transparent hover:ring-red-100'
                    : ''
                  }`}
                onClick={() => {
                  if (isPending) {
                    resumePayment(p.snap_token, p.snap_url, p.order_id);
                  }
                }}
              >
                {/* Tooltip for pending items */}
                {isPending && (
                  <div className="absolute top-2 right-2 text-[10px] text-gray-400 opacity-0 group-hover:opacity-100 transition-opacity">
                    Klik untuk bayar
                  </div>
                )}

                <div className="flex justify-between items-start">
                  <div className="flex-1">
                    <h3 className={`text-lg font-semibold text-[#1F1F1F] mb-1 ${isPending ? 'group-hover:text-[#E53935] transition-colors' : ''}`}>
                      {title}
                    </h3>

                    {subtitle && (
                      <p className="text-sm text-gray-600 mb-2">{subtitle}</p>
                    )}

                    <div className="flex items-center gap-2 text-gray-500 text-sm mt-2">
                      <svg
                        className="w-4 h-4"
                        fill="none"
                        stroke="currentColor"
                        viewBox="0 0 24 24"
                      >
                        <path
                          strokeLinecap="round"
                          strokeLinejoin="round"
                          strokeWidth={2}
                          d="M8 7V3m8 4V3M4 11h16M5 5h14a2 2 0 012 2v12a2 2 0 01-2 2H5a2 2 0 01-2-2V7a2 2 0 012-2z"
                        />
                      </svg>
                      <span>{when}</span>

                      {/* Status Chip */}
                      <span
                        className={`ml-2 px-3 py-0.5 rounded-full text-[10px] font-medium border ${statusStyles}`}
                      >
                        {displayStatus}
                      </span>
                    </div>

                    {/* Escrow COD Content */}
                    {isWaitingCOD && (
                      <div className="mt-4 p-4 bg-orange-50 border border-orange-200 rounded-lg">
                        <p className="text-sm font-medium text-orange-800 mb-2">
                          Show this authentication code to the seller after confirming the product matches your expectations.
                        </p>
                        <div className="flex items-center justify-between">
                          <span className="text-xl font-bold tracking-widest text-[#1F1F1F]">{p?.transaction?.auth_code || "N/A"}</span>
                          <button
                            onClick={(e) => initiateRefund(p?.transaction_id, e)}
                            disabled={escrowLoading}
                            className="px-4 py-2 bg-white border border-red-300 text-red-600 rounded-lg hover:bg-red-50 text-sm font-medium transition-colors disabled:opacity-50"
                          >
                            {escrowLoading ? 'Processing...' : 'Refund to Wallet'}
                          </button>
                        </div>
                        <p className="text-xs text-orange-600 mt-2">
                          Only click refund if the product is rejected.
                        </p>
                      </div>
                    )}

                  </div>

                  <div className="text-right">
                    <span className="text-base font-semibold text-[#1F1F1F]">
                      {formatCurrency(p?.gross_amount)}
                    </span>
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      ) : (
        <div className="text-center py-12 text-gray-500">
          No purchase history found
        </div>
      )}

      {/* Pagination */}
      {pagination.totalPages > 1 && (
        <div className="flex items-center justify-between border-t border-gray-200 pt-6 mt-6">
          <div className="flex items-center gap-2">
            <button
              className="p-2 rounded-lg hover:bg-gray-100 text-gray-500 disabled:opacity-50"
              disabled={pagination.currentPage <= 1}
              onClick={pagination.prev}
            >
              <svg
                className="w-5 h-5"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M15 19l-7-7 7-7"
                />
              </svg>
            </button>

            {Array.from({ length: pagination.totalPages }, (_, i) => i + 1).map(
              (page) => (
                <button
                  key={page}
                  onClick={() => pagination.goToPage(page)}
                  className={`w-8 h-8 rounded-lg text-sm font-medium transition-colors ${pagination.currentPage === page
                    ? "bg-[#E53935] text-white"
                    : "text-gray-600 hover:bg-gray-100"
                    }`}
                >
                  {page}
                </button>
              )
            )}

            <button
              className="p-2 rounded-lg hover:bg-gray-100 text-gray-500 disabled:opacity-50"
              disabled={pagination.currentPage >= pagination.totalPages}
              onClick={pagination.next}
            >
              <svg
                className="w-5 h-5"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M9 5l7 7-7 7"
                />
              </svg>
            </button>
          </div>

          <div className="flex items-center gap-2">
            <span className="text-sm text-gray-500">Show per page</span>
            <select
              value={pagination.itemsPerPage}
              onChange={(e) =>
                pagination.setItemsPerPage(Number(e.target.value))
              }
              className="text-sm border-none bg-transparent font-medium text-[#1F1F1F] outline-none cursor-pointer hover:text-[#E53935]"
            >
              <option value={10}>10</option>
              <option value={20}>20</option>
              <option value={50}>50</option>
            </select>
          </div>
        </div>
      )}

      {/* Refund Confirmation Modal */}
      {refundModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm">
          <div className="bg-white rounded-xl shadow-2xl w-full max-w-md p-6 relative">
            <h3 className="text-xl font-bold text-gray-900 mb-2">Request Refund</h3>
            <p className="text-sm text-gray-600 mb-6 font-medium">
              Are you sure you want to refund this product? The total amount will be credited back instantly to your Virtual Wallet.
            </p>
            <div className="flex gap-3">
              <button
                onClick={() => setRefundModalOpen(false)}
                className="flex-1 px-4 py-2 bg-gray-100 text-gray-700 rounded-lg hover:bg-gray-200 transition-colors font-medium"
              >
                No, Keep it
              </button>
              <button
                onClick={confirmRefund}
                disabled={escrowLoading}
                className="flex-1 px-4 py-2 bg-[#E53935] text-white rounded-lg hover:bg-[#D32F2F] transition-colors disabled:opacity-50 disabled:cursor-not-allowed font-medium"
              >
                {escrowLoading ? "Processing..." : "Yes, Refund"}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

export default PurchaseHistorySection;
