"use client";
import React, { useState } from "react";
import { ResponsiveContainer, LineChart, Line, XAxis, YAxis, Tooltip, ReferenceDot } from "recharts";
import { useSellerIncomeQuery } from "@/hooks/seller/useSellerIncomeQuery";
import { Skeleton } from "@/components/ui/skeleton";
import { useAuth } from "@/context/AuthProvider";
import WithdrawModal from "@/components/wallet/WithdrawModal";
import { transactionService } from "@/services";
import Toast from "@/components/ui/Toast";

const IncomeSectionClientCached = ({ sellerId }) => {
  const { user, mutate } = useAuth();
  const [selectedPeriod, setSelectedPeriod] = useState("Month");
  const [isWithdrawModalOpen, setIsWithdrawModalOpen] = useState(false);
  const [toast, setToast] = useState(null);
  const [isWithdrawing, setIsWithdrawing] = useState(false);

  const {
    balance,
    transferred,
    withdrawn,
    chartData,
    isLoading,
    error,
    formatCurrency,
    getYAxisDomain,
    getYAxisTicks,
    getMinDataPoint,
    refetch,
  } = useSellerIncomeQuery(sellerId, selectedPeriod);

  const [yMin, yMax] = getYAxisDomain();
  const yTicks = getYAxisTicks();
  const minDataPoint = getMinDataPoint();

  const handlePeriodChange = (period) => {
    setSelectedPeriod(period);
  };

  const handleWithdraw = async (payload) => {
    setIsWithdrawing(true);
    try {
      await transactionService.withdrawWallet(payload);
      setToast({
        message: "Penarikan saldo berhasil diproses",
        type: "success",
      });
      setIsWithdrawModalOpen(false);
      // Refresh the user context to get the updated balance
      if (mutate) {
        mutate();
      }
    } catch (err) {
      setToast({
        message: err.message || "Gagal melakukan penarikan saldo",
        type: "error",
      });
    } finally {
      setIsWithdrawing(false);
    }
  };

  return (
    <section>
      {toast && (
        <Toast
          message={toast.message}
          type={toast.type}
          onClose={() => setToast(null)}
        />
      )}
      <WithdrawModal
        isOpen={isWithdrawModalOpen}
        onClose={() => setIsWithdrawModalOpen(false)}
        onConfirm={handleWithdraw}
        walletBalance={user?.wallet_balance || 0}
      />
      <h2 className="text-2xl font-bold text-[var(--color-text-primary)] mb-4">Dashboard Keuangan</h2>
      <div className="rounded-2xl bg-white shadow-lg hover:shadow-2xl transition-shadow duration-200">
        <div className="p-6">
          <div className="flex flex-col md:flex-row justify-between mb-6 gap-4">
            <div className="flex-1 bg-red-50 rounded-xl p-4 border border-red-100">
              <p className="text-sm font-semibold text-red-800 uppercase tracking-wide">Saldo Dapat Dicairkan</p>
              <div className="flex justify-between items-end mt-1">
                {isLoading && !user ? (
                  <Skeleton className="h-8 w-32" />
                ) : (
                  <p className="text-3xl font-black text-brand-red">
                    {formatCurrency(user?.wallet_balance || 0)}
                  </p>
                )}
                <button
                  onClick={() => setIsWithdrawModalOpen(true)}
                  disabled={!user || user.wallet_balance <= 0 || isWithdrawing}
                  className="bg-red-600 hover:bg-red-700 text-white text-sm font-bold py-1.5 px-4 rounded-lg transition-colors shadow-sm disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  {isWithdrawing ? "Processing..." : "Tarik Saldo"}
                </button>
              </div>
              <p className="text-xs text-red-600 mt-2">Dapat ditarik ke rekening bank</p>
            </div>
            <div className="flex-1 bg-gray-50 rounded-xl p-4 border border-gray-100">
              <p className="text-sm font-semibold text-gray-500 uppercase tracking-wide">Total Sales (Periode)</p>
              {isLoading ? (
                <Skeleton className="h-8 w-32 mt-1" />
              ) : (
                <p className="text-3xl font-bold text-gray-800 mt-1">{formatCurrency(balance)}</p>
              )}
              <p className="text-xs text-gray-400 mt-2">Seluruh transaksi (termasuk diproses)</p>
            </div>
          </div>

          {error && (
            <div className="mb-4 p-3 bg-[var(--color-error-light)] border border-[var(--color-error)] rounded-lg text-[var(--color-error)] text-sm">
              {error.message || 'Failed to load income data'}
              <button
                onClick={() => refetch()}
                className="ml-2 underline hover:no-underline"
              >
                Retry
              </button>
            </div>
          )}

          <div className="h-64">
            {isLoading ? (
              <div className="h-full space-y-2">
                <Skeleton className="h-full w-full" />
              </div>
            ) : chartData.length === 0 ? (
              <div className="h-full flex flex-col items-center justify-center">
                <svg className="w-16 h-16 text-[var(--color-neutral-300)] mb-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
                </svg>
                <p className="text-[var(--color-text-secondary)]">No income data available</p>
                <p className="text-sm text-[var(--color-text-tertiary)] mt-1">Try selecting a different period</p>
              </div>
            ) : (
              <ResponsiveContainer width="100%" height="100%">
                <LineChart data={chartData} margin={{ top: 12, right: 20, left: 8, bottom: 0 }}>
                  <XAxis
                    dataKey="label"
                    axisLine={false}
                    tickLine={false}
                    tick={{ fill: "var(--color-text-tertiary)", fontSize: 12 }}
                    angle={-45}
                    textAnchor="end"
                    height={60}
                  />
                  <YAxis
                    axisLine={false}
                    tickLine={false}
                    tick={{ fill: "var(--color-text-tertiary)", fontSize: 12 }}
                    tickFormatter={(v) => v >= 1000 ? `${(v / 1000).toFixed(0)}k` : v.toString()}
                    domain={[yMin, yMax]}
                    ticks={yTicks}
                    width={60}
                  />
                  <Tooltip
                    contentStyle={{
                      background: "white",
                      border: "1px solid var(--color-border-default)",
                      borderRadius: "8px",
                      padding: "8px 12px"
                    }}
                    formatter={(value) => [formatCurrency(value), "Income"]}
                    labelStyle={{ color: "var(--color-text-primary)", fontWeight: 600 }}
                  />
                  <Line
                    type="monotone"
                    dataKey="income"
                    stroke="var(--color-brand-primary)"
                    strokeWidth={3}
                    dot={{ fill: "var(--color-brand-primary)", r: 4 }}
                    activeDot={{ r: 6 }}
                  />
                  {minDataPoint && (
                    <ReferenceDot
                      x={minDataPoint.label}
                      y={minDataPoint.income}
                      r={6}
                      fill="var(--color-brand-primary)"
                      stroke="white"
                      strokeWidth={2}
                    />
                  )}
                </LineChart>
              </ResponsiveContainer>
            )}
          </div>

          <div className="flex mt-6 bg-[var(--color-neutral-100)] rounded-xl p-1">
            {["Year", "Month", "Week"].map((p) => (
              <button
                key={p}
                onClick={() => handlePeriodChange(p)}
                disabled={isLoading}
                className={`flex-1 rounded-lg px-3 py-2 text-sm font-medium transition-all duration-200 ${selectedPeriod === p
                  ? "bg-brand-red text-white shadow-md"
                  : "bg-[var(--color-neutral-100)] text-[var(--color-text-secondary)] hover:bg-[var(--color-neutral-200)]"
                  } ${isLoading ? "opacity-50 cursor-not-allowed" : ""}`}
              >
                {p}
              </button>
            ))}
          </div>
        </div>
      </div>
    </section>
  );
};

export default IncomeSectionClientCached;
