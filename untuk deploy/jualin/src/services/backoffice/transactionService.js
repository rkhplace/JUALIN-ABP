import { fetcher } from "@/lib/fetcher";

export const transactionService = {
  async fetchAllTransactions(params = {}) {
    const { status = "all", limit = 10, page = 1 } = params;
    
    // Explicitly fetching all transactions without seller constraint
    const resp = await fetcher.get("/api/v1/transactions", {
      params: {
        per_page: limit,
        page,
        status: status === "all" ? undefined : status,
      },
    });
    
    const payload = resp?.data;
    
    if (payload?.data && Array.isArray(payload.data)) return payload.data;
    if (Array.isArray(payload)) return payload;
    return [];
  },
  
  async deleteTransaction(transactionId) {
     // Placeholder for future delete functionality
     // const resp = await fetcher.delete(\`/api/v1/transactions/\${transactionId}\`);
     // return resp;
  }
};

export default transactionService;
