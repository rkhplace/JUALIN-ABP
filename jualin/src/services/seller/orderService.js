import { fetcher } from "@/lib/fetcher";

export const orderService = {
  async verifyOrder(orderId) {
    try {
      const resp = await fetcher.post(`/api/v1/transactions/${orderId}`, {
        status: "verified",
      });
      return !!resp?.success;
    } catch (error) {
      console.error(`Error verifying order ${orderId}:`, error);
      return false;
    }
  },

  async fetchSellerOrders({ sellerId, status = 'all', limit = 10 }) {
    try {
      const resp = await fetcher.get("/api/v1/transactions", {
        params: {
          seller_id: sellerId,
          status: status === 'all' ? undefined : status,
          per_page: limit
        },
      });
      const payload = resp?.data;
      const list = payload?.data && Array.isArray(payload.data)
        ? payload.data
        : Array.isArray(payload)
          ? payload
          : [];
      return list.filter((order) => {
        if (!sellerId) return true;
        return String(order?.seller_id ?? order?.seller?.id ?? "") === String(sellerId);
      });
    } catch (error) {
      console.error("Error fetching seller orders:", error);
      return [];
    }
  },

  async fetchIncome(_sellerId, period = "Month", type = "withdraw") {
    const resp = await fetcher.get("/api/v1/transactions/income/statistics", {
      params: { period, type },
    });
    return resp?.data || resp;
  },
};

export default orderService;
