import { fetcher } from "@/lib/fetcher";

export const passwordService = {
  async sendResetLink(email) {
    try {
      const res = await fetcher.post("/api/v1/password/email", { email });
      return res; 
    } catch (err) {
      if (err.code === "ECONNABORTED" || err.message?.toLowerCase().includes("timeout")) {
        throw new Error("Request timeout. If email arrives, please check your inbox.");
      }
      throw new Error(err.message || "Gagal mengirim tautan reset password");
    }
  },

  async resetPassword({ token, email, password, password_confirmation }) {
    try {
      const res = await fetcher.post("/api/v1/password/reset", {
        token, email, password, password_confirmation
      });
      return res;
    } catch (err) {
      throw new Error(err.message || "Gagal mereset password");
    }
  },
};

export default passwordService;