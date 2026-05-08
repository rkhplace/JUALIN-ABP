import { fetcher } from "@/lib/fetcher";

export const paymentService = {
  async getHistory() {
    const resp = await fetcher.get("/api/v1/payments/history");
    return Array.isArray(resp?.data) ? resp.data : [];
  },

  async createOrContinuePayment(transactionId, customerDetails = {}) {
    const resp = await fetcher.post("/api/v1/payments/create", {
      transaction_id: transactionId,
      customer_details: customerDetails,
    });
    return resp?.data || {};
  },

  async checkStatus(orderId) {
    const resp = await fetcher.get(`/api/v1/payments/status/${orderId}`);
    return resp?.data || {};
  },

  async reissueToken(paymentId, customerDetails = {}) {
    const resp = await fetcher.post(`/api/v1/payments/reissue/${paymentId}`, {
      customer_details: customerDetails,
    });
    return resp?.data || {};
  },
};

export default paymentService;
