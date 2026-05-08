import { fetcher } from "@/lib/fetcher";

export const escrowService = {
    async claimPayment(transactionId, authCode) {
        const resp = await fetcher.post(`/api/v1/escrow/${transactionId}/claim`, {
            auth_code: authCode,
        });
        return resp;
    },

    async refundPayment(transactionId) {
        const resp = await fetcher.post(`/api/v1/escrow/${transactionId}/refund`);
        return resp;
    },
};

export default escrowService;
