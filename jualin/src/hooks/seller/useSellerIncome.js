import { useState, useEffect } from "react";
import { formatCurrency } from "@/utils/formatters/currency";
import { transformIncomeData } from "@/utils/helpers/incomeHelper";
import { orderService } from "@/services";

export const useSellerIncome = (sellerId) => {
  const [selectedPeriod, setSelectedPeriod] = useState("Month");
  const [incomeData, setIncomeData] = useState({
    balance: 0,
    transferred: 0,
    chartData: [],
  });
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    if (!sellerId) {
      setIsLoading(false);
      return;
    }

    const fetchIncomeData = async () => {
      try {
        setIsLoading(true);
        setError(null);
        const rawTransactions = await orderService.fetchIncome(
          sellerId,
          selectedPeriod
        );

        if (Array.isArray(rawTransactions)) {
          const transformedData = transformIncomeData(
            rawTransactions,
            selectedPeriod
          );
          setIncomeData(transformedData);
        } else if (rawTransactions && (rawTransactions.chart_data || rawTransactions.labels || rawTransactions.data)) {
          const sourceChartData = Array.isArray(rawTransactions.chart_data)
            ? rawTransactions.chart_data
            : (rawTransactions.labels || []).map((label, index) => ({
                label,
                amount: rawTransactions.data?.[index] || 0,
              }));

          const formattedChartData = sourceChartData.map(
            (item) => ({
              label: item.label,
              fullLabel: item.full_label ?? item.fullLabel ?? item.label,
              amount: Number(item.amount ?? item.income ?? 0),
              periodKey: item.period_key ?? item.periodKey ?? item.label,
              date: item.date ?? null,
            })
          );
          setIncomeData({
            balance: rawTransactions.balance || 0,
            transferred: rawTransactions.transferred || 0,
            chartData: formattedChartData,
          });
        } else {
          setIncomeData({ balance: 0, transferred: 0, chartData: [] });
        }
      } catch (err) {
        let errorMessage = "Failed to load income data";
        if (err.code === "ECONNABORTED" || err.message?.includes("timeout")) {
          errorMessage = "Request timed out. Please try again.";
        } else if (err.statusCode === 401) {
          errorMessage = "Session expired. Please login again.";
        } else if (err.statusCode === 403) {
          errorMessage =
            "Access denied. You do not have permission to view this data.";
        } else if (err.statusCode === 404) {
          errorMessage = "Income data not found for this seller.";
        } else if (err.message) {
          errorMessage = err.message;
        }
        setError(errorMessage);
        setIncomeData({ balance: 0, transferred: 0, chartData: [] });
      } finally {
        setIsLoading(false);
      }
    };

    fetchIncomeData();
  }, [sellerId, selectedPeriod]);

  const getYAxisDomain = () => {
    if (incomeData.chartData.length === 0) return [0, 10000];
    const maxAmount = Math.max(...incomeData.chartData.map((d) => d.amount), 0);
    const minAmount = Math.min(...incomeData.chartData.map((d) => d.amount), 0);
    const padding = Math.max(maxAmount * 0.2, 1000);
    const max = Math.ceil((maxAmount + padding) / 1000) * 1000;
    const min = Math.max(0, Math.floor((minAmount - padding) / 1000) * 1000);
    return [min, max];
  };

  const getYAxisTicks = () => {
    const [yMin, yMax] = getYAxisDomain();
    const yTicks = [];
    const step = (yMax - yMin) / 4;
    for (let i = yMin; i <= yMax; i += step) yTicks.push(Math.round(i));
    return yTicks;
  };

  const getMinDataPoint = () => {
    if (incomeData.chartData.length === 0) return null;
    return incomeData.chartData.reduce(
      (min, item) => (item.amount < min.amount ? item : min),
      incomeData.chartData[0]
    );
  };

  return {
    ...incomeData,
    selectedPeriod,
    setSelectedPeriod,
    isLoading,
    error,
    formatCurrency,
    getYAxisDomain,
    getYAxisTicks,
    getMinDataPoint,
  };
};
