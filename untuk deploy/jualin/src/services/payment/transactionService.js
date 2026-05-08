import { fetcher } from "@/lib/fetcher";

export const transactionService = {
  async create({ seller_id, items }) {
    const resp = await fetcher.post("/api/v1/transactions", {
      seller_id,
      items,
    });
    return resp?.data || resp;
  },

  async payWallet({ seller_id, product_id }) {
    const resp = await fetcher.post("/api/v1/transactions/pay-wallet", {
      seller_id,
      product_id,
    });
    return resp?.data || resp;
  },

  async withdrawWallet(payload) {
    const resp = await fetcher.post("/api/v1/transactions/withdraw", payload);
    return resp?.data || resp;
  },
};

export default transactionService;
