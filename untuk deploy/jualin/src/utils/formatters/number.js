export const formatNumber = (num) => {
  return new Intl.NumberFormat('id-ID').format(num);
};

export const formatCompactNumber = (num) => {
  if (num >= 1000000) {
    return `${(num / 1000000).toFixed(1)}M`;
  }
  if (num >= 1000) {
    return `${(num / 1000).toFixed(1)}K`;
  }
  return num.toString();
};
