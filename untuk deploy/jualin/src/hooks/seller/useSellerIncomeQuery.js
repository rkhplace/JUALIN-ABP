import { useQuery } from "@tanstack/react-query";
import { queryKeys } from "@/lib/queryClient";
import { transformIncomeData } from "@/utils/helpers/incomeHelper";
import { formatCurrency } from "@/utils/formatters/currency";
import { orderService } from "@/services";

const fetchSellerIncome = async ({ sellerId, period }) => {
  if (!sellerId) throw new Error("Seller ID is required");
  const rawTransactions = await orderService.fetchIncome(sellerId, period);

  if (Array.isArray(rawTransactions))
    return transformIncomeData(rawTransactions, period);

  if (rawTransactions && (rawTransactions.chart_data || rawTransactions.labels || rawTransactions.data)) {
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
    return {
      balance: rawTransactions.balance || 0,
      claimed: rawTransactions.claimed || rawTransactions.balance || 0,
      transferred: rawTransactions.transferred || 0,
      withdrawn: rawTransactions.withdrawn || rawTransactions.transferred || 0,
      chartTotal: rawTransactions.chart_total || 0,
      currentBalance: rawTransactions.current_balance || 0,
      labels: rawTransactions.labels || formattedChartData.map((item) => item.label),
      fullLabels: rawTransactions.full_labels || formattedChartData.map((item) => item.fullLabel),
      data: rawTransactions.data || formattedChartData.map((item) => item.amount),
      chartData: formattedChartData,
    };
  }

  return {
    balance: 0,
    claimed: 0,
    transferred: 0,
    withdrawn: 0,
    chartTotal: 0,
    currentBalance: 0,
    labels: [],
    fullLabels: [],
    data: [],
    chartData: [],
  };
};

export const useSellerIncomeQuery = (sellerId, period = "Month") => {
  const { data, isLoading, error, refetch } = useQuery({
    queryKey: queryKeys.sellerIncome(sellerId, period),
    queryFn: () => fetchSellerIncome({ sellerId, period }),
    enabled: !!sellerId,
    staleTime: 2 * 60 * 1000,
    gcTime: 5 * 60 * 1000,
    retry: 1,
  });

  const getYAxisDomain = () => {
    if (!data?.chartData || data.chartData.length === 0) return [0, 10000];
    const maxAmount = Math.max(...data.chartData.map((d) => d.amount), 0);
    const minAmount = Math.min(...data.chartData.map((d) => d.amount), 0);
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
    if (!data?.chartData || data.chartData.length === 0) return null;
    return data.chartData.reduce(
      (min, item) => (item.amount < min.amount ? item : min),
      data.chartData[0]
    );
  };

  return {
    balance: data?.balance || 0,
    claimed: data?.claimed || data?.balance || 0,
    transferred: data?.transferred || 0,
    withdrawn: data?.withdrawn || 0,
    chartTotal: data?.chartTotal || 0,
    currentBalance: data?.currentBalance || 0,
    labels: data?.labels || [],
    fullLabels: data?.fullLabels || [],
    data: data?.data || [],
    chartData: data?.chartData || [],
    isLoading,
    error,
    refetch,
    formatCurrency,
    getYAxisDomain,
    getYAxisTicks,
    getMinDataPoint,
  };
};
