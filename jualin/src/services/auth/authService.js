import { fetcher } from "@/lib/fetcher";

const REMEMBER_ME_KEY = "remember_me";
const REMEMBERED_EMAIL_KEY = "remembered_email";

export const authService = {
  async login(email, password, remember = false) {
    const response = await fetcher.post(
      "/api/v1/login",
      { email, password, remember },
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

  getRememberedLogin() {
    if (typeof window === "undefined") {
      return { rememberMe: false, email: "" };
    }

    const rememberMe = localStorage.getItem(REMEMBER_ME_KEY) === "true";
    return {
      rememberMe,
      email: rememberMe
        ? localStorage.getItem(REMEMBERED_EMAIL_KEY) || ""
        : "",
    };
  },

  saveRememberedLogin(email, rememberMe) {
    if (typeof window === "undefined") return;

    if (rememberMe) {
      localStorage.setItem(REMEMBER_ME_KEY, "true");
      localStorage.setItem(
        REMEMBERED_EMAIL_KEY,
        String(email || "").trim().toLowerCase()
      );
      return;
    }

    localStorage.removeItem(REMEMBER_ME_KEY);
    localStorage.removeItem(REMEMBERED_EMAIL_KEY);
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

  async becomeSeller() {
    const response = await fetcher.post("/api/v1/me/become-seller");
    return response?.data || response;
  },
};
export default authService;
