import { fetcher } from "@/lib/fetcher";

export const escrowService = {
    async claimPayment(transactionId, authCode) {
        const resp = await fetcher.post(`/api/v1/escrow/${transactionId}/claim`, {
            auth_code: authCode,
        });
        return resp;
    },

    async refundPayment(transactionId, refundReason) {
        const resp = await fetcher.post(`/api/v1/escrow/${transactionId}/refund`, {
            refund_reason: refundReason,
        });
        return resp;
    },

    async revealAuthCode(transactionId, password) {
        const resp = await fetcher.post(
            `/api/v1/transactions/${transactionId}/reveal-auth-code`,
            { verification_method: "password", password }
        );
        return resp?.data || resp;
    },
};

export default escrowService;
