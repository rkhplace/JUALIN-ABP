/**
 * Income Data Transformation Helpers
 * Transform raw transaction data into chart-ready format
 */

/**
 * Calculate total income from transactions
 */
export const calculateTotals = (transactions) => {
  const totals = transactions.reduce(
    (acc, transaction) => {
      const amount = parseFloat(transaction.total_amount || 0);

      if (transaction.status === 'paid') {
        acc.transferred += amount;
      } else if (transaction.status === 'pending') {
        acc.balance += amount;
      }

      acc.total += amount;

      return acc;
    },
    { balance: 0, transferred: 0, total: 0 }
  );

  return totals;
};

/**
 * Group transactions by week
 */
const groupByWeek = (transactions) => {
  const weekGroups = {};
  const today = new Date();

  transactions.forEach((transaction) => {
    const date = new Date(transaction.created_at);
    const diffTime = Math.abs(today - date);
    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
    const weekNumber = Math.floor(diffDays / 7);

    const dayOfWeek = date.getDay();
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    const label = days[dayOfWeek];

    if (!weekGroups[label]) {
      weekGroups[label] = { label, income: 0 };
    }

    if (transaction.status === 'paid' || transaction.status === 'pending') {
      weekGroups[label].income += parseFloat(transaction.total_amount || 0);
    }
  });

  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return days.map(day => weekGroups[day] || { label: day, income: 0 });
};

/**
 * Group transactions by month (weeks in month)
 */
const groupByMonth = (transactions) => {
  const weekGroups = {};

  transactions.forEach((transaction) => {
    const date = new Date(transaction.created_at);
    const weekOfMonth = Math.ceil(date.getDate() / 7);
    const label = `Week ${weekOfMonth}`;

    if (!weekGroups[label]) {
      weekGroups[label] = { label, income: 0 };
    }

    if (transaction.status === 'paid' || transaction.status === 'pending') {
      weekGroups[label].income += parseFloat(transaction.total_amount || 0);
    }
  });

  const weeks = ['Week 1', 'Week 2', 'Week 3', 'Week 4'];
  return weeks.map(week => weekGroups[week] || { label: week, income: 0 });
};

/**
 * Group transactions by year (months)
 */
const groupByYear = (transactions) => {
  const monthGroups = {};

  transactions.forEach((transaction) => {
    const date = new Date(transaction.created_at);
    const monthIndex = date.getMonth();
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const label = months[monthIndex];

    if (!monthGroups[label]) {
      monthGroups[label] = { label, income: 0 };
    }

    if (transaction.status === 'paid' || transaction.status === 'pending') {
      monthGroups[label].income += parseFloat(transaction.total_amount || 0);
    }
  });

  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return months.map(month => monthGroups[month] || { label: month, income: 0 });
};

/**
 * Transform transactions to chart data based on period
 */
export const transformToChartData = (transactions, period) => {
  if (!transactions || transactions.length === 0) {
    return [];
  }

  switch (period) {
    case 'Week':
      return groupByWeek(transactions);
    case 'Month':
      return groupByMonth(transactions);
    case 'Year':
      return groupByYear(transactions);
    default:
      return [];
  }
};

/**
 * Main transformation function
 */
export const transformIncomeData = (transactions, period) => {
  if (!Array.isArray(transactions)) {
    console.warn('transformIncomeData: transactions is not an array', transactions);
    return {
      balance: 0,
      transferred: 0,
      chartData: [],
    };
  }

  const totals = calculateTotals(transactions);
  const chartData = transformToChartData(transactions, period);

  return {
    balance: totals.balance,
    transferred: totals.transferred,
    chartData,
  };
};
