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
      if (payload?.data && Array.isArray(payload.data)) return payload.data;
      if (Array.isArray(payload)) return payload;
      return [];
    } catch (error) {
      console.error("Error fetching seller orders:", error);
      return [];
    }
  },

  async fetchIncome(sellerId, period = "Month") {
    const resp = await fetcher.get("/api/v1/transactions", {
      params: { period, seller_id: sellerId },
    });
    return resp?.data;
  },
};

export default orderService;
