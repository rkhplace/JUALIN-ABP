"use client";
import React, { useState } from "react";
import { ResponsiveContainer, LineChart, Line, XAxis, YAxis, Tooltip, ReferenceDot } from "recharts";
import { useSellerIncomeQuery } from "@/hooks/seller/useSellerIncomeQuery";
import { Skeleton } from "@/components/ui/skeleton";

const IncomeSectionClientCached = ({ sellerId }) => {
  const [selectedPeriod, setSelectedPeriod] = useState("Month");

  const {
    balance,
    transferred,
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

  return (
    <section>
      <h2 className="text-2xl font-bold text-[var(--color-text-primary)] mb-4">Income</h2>
      <div className="rounded-2xl bg-white shadow-lg hover:shadow-2xl transition-shadow duration-200">
        <div className="p-6">
          <div className="flex justify-between mb-4">
            <div>
              <p className="text-sm text-[var(--color-text-secondary)]">Balance</p>
              {isLoading ? (
                <Skeleton className="h-8 w-32 mt-1" />
              ) : (
                <p className="text-2xl font-bold text-brand-red">{formatCurrency(balance)}</p>
              )}
            </div>
            <div className="text-right">
              <p className="text-sm text-[var(--color-text-secondary)]">Transferred</p>
              {isLoading ? (
                <Skeleton className="h-8 w-32 mt-1" />
              ) : (
                <p className="text-2xl font-bold text-brand-red">{formatCurrency(transferred)}</p>
              )}
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
                className={`flex-1 rounded-lg px-3 py-2 text-sm font-medium transition-all duration-200 ${
                  selectedPeriod === p
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
