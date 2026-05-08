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

  /**
   * Fetch current seller's own products using the authenticated endpoint.
   * Always returns { products, totalProducts, totalPages, currentPage }
   */
  async fetchMyProducts(limit = 6, page = 1) {
    const res = await fetcher.get("/api/v1/seller/products", {
      params: {
        per_page: limit,
        page,
        sort_by: "created_at",
        sort_dir: "desc",
      },
    });

    // Response format from ProductController::indexMe
    if (res?.products) {
      return {
        products: Array.isArray(res.products) ? res.products : [],
        totalProducts: Number(res.totalProducts ?? 0),
        totalPages: Number(res.totalPages ?? 1),
        currentPage: Number(res.currentPage ?? page),
      };
    }

    // Fallback: Laravel paginated response
    const payload = res?.data;
    if (payload?.data && Array.isArray(payload.data)) {
      return {
        products: payload.data,
        totalProducts: Number(payload.total ?? payload.data.length ?? 0),
        totalPages: Number(payload.last_page ?? 1),
        currentPage: Number(payload.current_page ?? page),
      };
    }

    // Final fallback
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
