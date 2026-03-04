"use client";

export default function PaymentHistoryList({
  items,
  formatCurrency,
  onItemClick,
}) {
  if (!items || items.length === 0) {
    return (
      <div className="text-center py-12 text-gray-500">No payments found</div>
    );
  }

  const formatWhen = (ts) => {
    if (!ts) return "";
    try {
      const d = new Date(ts);
      return d.toLocaleDateString("en-US", {
        month: "short",
        day: "numeric",
        year: "numeric",
      });
    } catch {
      return "";
    }
  };

  return (
    <div className="space-y-4 mb-8">
      {items.map((p) => {
        const status = String(p?.transaction_status || "").toLowerCase();
        const statusStyles =
          status === "pending"
            ? "bg-yellow-100 text-yellow-700 border-yellow-200"
            : status === "settlement" ||
              status === "capture" ||
              status === "paid" ||
              status === "completed"
            ? "bg-green-100 text-green-700 border-green-200"
            : "bg-gray-100 text-gray-700 border-gray-200";

        const orderLabel = `${p?.order_id || p?.payment_id || "-"}`;
        const title = p?.first_item_name || p?.seller_name || orderLabel;

        const subtitle = orderLabel;
        const category = p?.first_item_category;
        const when = formatWhen(p?.transaction_time);

        return (
          <button
            key={p?.payment_id || p?.order_id}
            onClick={() => onItemClick?.(p)}
            className="w-full text-left group bg-white border border-gray-100 p-5 hover:bg-[#F7F7F8] rounded-xl transition-colors cursor-pointer"
          >
            <div className="flex justify-between items-start">
              <div className="flex-1">
                <h3 className="text-lg font-semibold text-[#1F1F1F] mb-1">
                  {title}
                </h3>

                <p className="text-sm text-gray-600 mb-2">{subtitle}</p>

                <div className="flex items-center gap-2 text-gray-500 text-sm">
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

                  {/* category chip */}
                  {category && (
                    <span className="ml-2 px-3 py-0.5 rounded-full text-xs bg-gray-100 text-gray-700">
                      {category}
                    </span>
                  )}

                  <span
                    className={`ml-2 px-2 py-0.5 rounded-full text-[10px] font-medium border ${statusStyles}`}
                  >
                    {status}
                  </span>
                </div>
              </div>

              <div className="text-right">
                <span className="text-base font-semibold text-[#1F1F1F]">
                  {formatCurrency(p?.gross_amount)}
                </span>
              </div>
            </div>
          </button>
        );
      })}
    </div>
  );
}
