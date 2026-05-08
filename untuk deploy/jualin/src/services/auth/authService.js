import { fetcher } from "@/lib/fetcher";

export const authService = {
  async login(email, password) {
    const response = await fetcher.post(
      "/api/v1/login",
      { email, password },
      { auth: false, skipAuthRedirect: true }
    );
    const data = response?.data || response;
    return {
      username: data.username,
      email: data.email,
      access_token: data.access_token,
      refresh_token: data.refresh_token,
      role: data.role,
      user: data.user || null,
    };
  },

  async register({ username, email, password, password_confirmation, role }) {
    const response = await fetcher.post(
      "/api/v1/register",
      { username, email, password, password_confirmation, role },
      { auth: false, skipAuthRedirect: true }
    );
    return {
      username: response?.user?.username,
      email: response?.user?.email,
      access_token: response?.access_token,
      refresh_token: response?.refresh_token,
      role: response?.role || response?.user?.role,
      user: response?.user || null,
    };
  },

  async logout() {
    try {
      await fetcher.post("/api/v1/logout", null);
    } catch {}
  },

  async me() {
    return await fetcher.get("/api/v1/me");
  },
};
export default authService;
