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

  if (rawTransactions && rawTransactions.chart_data) {
    const formattedChartData = (rawTransactions.chart_data || []).map(
      (item) => ({
        label: item.label,
        income: item.income,
      })
    );
    return {
      balance: rawTransactions.balance || 0,
      transferred: rawTransactions.transferred || 0,
      chartData: formattedChartData,
    };
  }

  return { balance: 0, transferred: 0, chartData: [] };
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
    const maxIncome = Math.max(...data.chartData.map((d) => d.income), 0);
    const minIncome = Math.min(...data.chartData.map((d) => d.income), 0);
    const padding = Math.max(maxIncome * 0.2, 1000);
    const max = Math.ceil((maxIncome + padding) / 1000) * 1000;
    const min = Math.max(0, Math.floor((minIncome - padding) / 1000) * 1000);
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
      (min, item) => (item.income < min.income ? item : min),
      data.chartData[0]
    );
  };

  return {
    balance: data?.balance || 0,
    transferred: data?.transferred || 0,
    withdrawn: data?.withdrawn || 0,
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
