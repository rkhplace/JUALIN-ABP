import { fetcher } from "@/lib/fetcher";

export const userService = {
  async fetchAll(page = 1, limit = 10, search = "") {
    const response = await fetcher.get("/api/v1/users", {
      params: { page, per_page: limit, search },
    });
    console.debug("userService.fetchAll response:", response);
    return response;
  },
  async fetchById(id) {
    const response = await fetcher.get(`/api/v1/users/${id}`);
    return response?.data || response;
  },

  async fetchCurrentUser() {
    const response = await fetcher.get("/api/v1/users/me");
    return response?.data || response;
  },
};

export default userService;
