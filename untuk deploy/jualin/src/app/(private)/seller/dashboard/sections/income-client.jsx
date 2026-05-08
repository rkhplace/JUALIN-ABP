"use client";
import React, { useMemo } from "react";
import { ResponsiveContainer, LineChart, Line, XAxis, YAxis, Tooltip, ReferenceDot } from "recharts";
import { useSellerIncome } from "@/hooks/seller/useSellerIncome";
import { Skeleton } from "@/components/ui/skeleton";

function WithdrawTooltip({ active, payload, formatCurrency }) {
  if (!active || !payload?.length) return null;

  const point = payload[0]?.payload;
  const fullLabel = point?.fullLabel || point?.label || "-";
  const amount = Number(point?.amount || 0);

  return (
    <div className="rounded-lg border border-gray-200 bg-white px-3 py-2 shadow-md">
      <p className="text-sm font-semibold text-gray-900">{fullLabel}</p>
      <p className="text-sm text-gray-600">{formatCurrency(amount)}</p>
    </div>
  );
}

const IncomeSectionClient = ({ sellerId }) => {
  const {
    balance,
    transferred,
    chartData,
    selectedPeriod,
    setSelectedPeriod,
    isLoading,
    error,
    formatCurrency,
    getYAxisDomain,
    getYAxisTicks,
    getMinDataPoint,
  } = useSellerIncome(sellerId);

  const [yMin, yMax] = getYAxisDomain();
  const yTicks = getYAxisTicks();
  const minDataPoint = getMinDataPoint();
  const visibleTicks = useMemo(() => {
    if (!chartData.length) return [];
    if (chartData.length <= 6) return chartData.map((item) => item.label);

    const step = Math.ceil(chartData.length / 6);
    const ticks = chartData
      .filter((_, index) => index % step === 0)
      .map((item) => item.label);
    const lastLabel = chartData[chartData.length - 1]?.label;

    if (lastLabel && ticks[ticks.length - 1] !== lastLabel) {
      ticks.push(lastLabel);
    }

    return [...new Set(ticks)];
  }, [chartData]);

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
              {error}
              <button
                onClick={() => setSelectedPeriod(selectedPeriod)}
                className="ml-2 underline hover:no-underline"
              >
                Retry
              </button>
            </div>
          )}

          <div className="h-64 overflow-hidden">
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
                <LineChart data={chartData} margin={{ top: 12, right: 20, left: 8, bottom: 20 }}>
                  <XAxis
                    dataKey="label"
                    axisLine={false}
                    tickLine={false}
                    tick={{ fill: "var(--color-text-tertiary)", fontSize: 12 }}
                    angle={0}
                    textAnchor="middle"
                    interval="preserveStartEnd"
                    ticks={visibleTicks}
                    minTickGap={24}
                    tickMargin={10}
                    height={44}
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
                  <Tooltip content={<WithdrawTooltip formatCurrency={formatCurrency} />} />
                  <Line
                    type="monotone"
                    dataKey="amount"
                    stroke="var(--color-brand-primary)"
                    strokeWidth={3}
                    dot={{ fill: "var(--color-brand-primary)", r: 4 }}
                    activeDot={{ r: 6 }}
                  />
                  {minDataPoint && (
                    <ReferenceDot
                      x={minDataPoint.label}
                      y={minDataPoint.amount}
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
            {["Year", "Month", "Week", "Day"].map((p) => (
              <button
                key={p}
                onClick={() => setSelectedPeriod(p)}
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

export default IncomeSectionClient;
