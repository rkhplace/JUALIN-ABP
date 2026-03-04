/**
 * Mock Income Data for Development & Testing
 * Digunakan ketika API belum tersedia atau untuk testing
 */

export const generateMockIncomeData = (period = 'Month') => {
  const getChartDataByPeriod = () => {
    switch (period) {
      case 'Week':
        return [
          { label: 'Mon', income: 250000 },
          { label: 'Tue', income: 320000 },
          { label: 'Wed', income: 180000 },
          { label: 'Thu', income: 450000 },
          { label: 'Fri', income: 580000 },
          { label: 'Sat', income: 720000 },
          { label: 'Sun', income: 640000 },
        ];

      case 'Month':
        return [
          { label: 'Week 1', income: 1250000 },
          { label: 'Week 2', income: 1580000 },
          { label: 'Week 3', income: 980000 },
          { label: 'Week 4', income: 2150000 },
        ];

      case 'Year':
        return [
          { label: 'Jan', income: 3500000 },
          { label: 'Feb', income: 4200000 },
          { label: 'Mar', income: 3800000 },
          { label: 'Apr', income: 5100000 },
          { label: 'May', income: 4800000 },
          { label: 'Jun', income: 6200000 },
          { label: 'Jul', income: 5900000 },
          { label: 'Aug', income: 7100000 },
          { label: 'Sep', income: 6500000 },
          { label: 'Oct', income: 7800000 },
          { label: 'Nov', income: 8200000 },
          { label: 'Dec', income: 9500000 },
        ];

      default:
        return [];
    }
  };

  const chartData = getChartDataByPeriod();
  const totalIncome = chartData.reduce((sum, item) => sum + item.income, 0);

  return {
    balance: totalIncome * 0.7,
    transferred: totalIncome * 0.3,
    chart_data: chartData,
  };
};

/**
 * Check if running in development mode
 */
export const isDevelopment = () => {
  return process.env.NODE_ENV === 'development';
};
