export const formatCurrency = (amount) => {
  const num = Number(amount) || 0;
  return "Rp " + num.toLocaleString("id-ID");
};

export const formatPrice = (price) => {
  const numPrice = typeof price === 'string' ? parseFloat(price) : price;
  return formatCurrency(numPrice);
};
