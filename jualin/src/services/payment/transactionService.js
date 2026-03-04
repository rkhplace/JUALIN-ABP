import { fetcher } from "@/lib/fetcher";

export const transactionService = {
  async create({ seller_id, items }) {
    const resp = await fetcher.post("/api/v1/transactions", {
      seller_id,
      items,
    });
    return resp?.data || resp;
  },
};

export default transactionService;
