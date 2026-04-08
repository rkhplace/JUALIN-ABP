import { fetcher } from "@/lib/fetcher";

export const sellerService = {
  /**
   * Fetch products for a specific seller with pagination
   * Normalizes response into { products, totalProducts, totalPages, currentPage }
   */
  async fetchProducts(sellerId, limit = 6, page = 1) {
    const res = await fetcher.get("/api/v1/products", {
      params: {
        seller_id: sellerId,
        per_page: limit,
        page,
        sort_by: "created_at",
        sort_dir: "desc",
      },
    });

    if (res?.products) {
      return {
        products: Array.isArray(res.products) ? res.products : [],
        totalProducts: Number(res.totalProducts ?? 0),
        totalPages: Number(res.totalPages ?? 1),
        currentPage: Number(res.currentPage ?? page),
      };
    }

    const payload = res?.data;
    if (payload?.data && Array.isArray(payload.data)) {
      return {
        products: payload.data,
        totalProducts: Number(payload.total ?? payload.data.length ?? 0),
        totalPages: Number(payload.last_page ?? 1),
        currentPage: Number(payload.current_page ?? page),
      };
    }

    const list = Array.isArray(payload)
      ? payload
      : Array.isArray(res)
      ? res
      : [];
    return {
      products: list,
      totalProducts: list.length,
      totalPages: 1,
      currentPage: page,
    };
  },

  async fetchMyProducts(sellerId, limit = 6) {
    if (sellerId) {
      const result = await this.fetchProducts(sellerId, limit, 1);
      return Array.isArray(result.products) ? result.products : [];
    }

    const res = await fetcher.get("/api/v1/seller/products", {
      params: {
        per_page: limit,
        page: 1,
        sort_by: "created_at",
        sort_dir: "desc",
      },
    });

    if (res?.products) {
      return Array.isArray(res.products) ? res.products : [];
    }

    const payload = res?.data;
    if (payload?.data && Array.isArray(payload.data)) {
      return payload.data;
    }

    if (Array.isArray(payload)) {
      return payload;
    }

    return Array.isArray(res) ? res : [];
  },

  async deleteProduct(productId) {
    try {
      await fetcher.delete(`/api/v1/products/${productId}`);
      return true;
    } catch {
      return false;
    }
  },
};

export default sellerService;
