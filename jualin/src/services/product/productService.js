import { fetcher } from "@/lib/fetcher";

const normalizeProduct = (product) => ({
  ...product,
  img: product.image,
  id: product.id,
  category: product.category?.toLowerCase() || "",
  stock: product.stock ?? product.stock_quantity ?? 0,
});

export const productService = {
  async fetchAll(params = {}) {
    const res = await fetcher.get("/api/v1/products", { params });

    if (res?.products) {
      return {
        products: Array.isArray(res.products)
          ? res.products.map(normalizeProduct)
          : [],
        totalProducts:
          res.totalProducts ?? res.total ?? res.products?.length ?? 0,
        totalPages: res.totalPages ?? res.last_page ?? 1,
        currentPage: res.currentPage ?? res.current_page ?? params.page ?? 1,
      };
    }

    const payload = res?.data;
    const list = Array.isArray(payload?.data)
      ? payload.data
      : Array.isArray(payload)
        ? payload
        : [];
    const products = list.map(normalizeProduct);

    return {
      products,
      totalProducts: res?.total ?? products.length,
      totalPages: res?.last_page ?? 1,
      currentPage: res?.current_page ?? params.page ?? 1,
    };
  },

  async fetchById(id) {
    const res = await fetcher.get(`/api/v1/products/${id}`);
    return normalizeProduct(res?.data || res);
  },

  async create(productData, imageFile = null) {
    const token =
      typeof window !== "undefined" ? localStorage.getItem("token") : null;
    if (!token) throw new Error("Please login as seller to create a product.");

    const storedUser =
      typeof window !== "undefined"
        ? JSON.parse(localStorage.getItem("user") || "null")
        : null;
    const sellerId =
      storedUser?.id || storedUser?.user_id || storedUser?.userId || null;
    if (!sellerId) throw new Error("Seller ID not found. Please login again.");

    if (imageFile) {
      const formData = new FormData();
      formData.append("seller_id", sellerId);
      Object.entries({
        name: productData.name,
        description: productData.description || "",
        price: productData.price,
        stock_quantity: productData.stock_quantity || 0,
        category: productData.category || "",
        condition: productData.condition || "new",
        status: productData.status || "active",
      }).forEach(([k, v]) => formData.append(k, v));
      formData.append("image", imageFile);

      const res = await fetcher.upload("/api/v1/products", formData);
      return normalizeProduct(res?.data || res);
    }

    const res = await fetcher.post("/api/v1/products", {
      seller_id: sellerId,
      name: productData.name,
      description: productData.description || "",
      price: productData.price,
      stock_quantity: productData.stock_quantity || 0,
      category: productData.category || "",
      condition: productData.condition || "new",
      status: productData.status || "active",
    });
    return normalizeProduct(res?.data || res);
  },

  async update(id, productData, imageFile = null) {
    if (imageFile) {
      const formData = new FormData();
      Object.entries({
        name: productData.name,
        description: productData.description || "",
        price: productData.price,
        stock_quantity: productData.stock_quantity || 0,
        category: productData.category || "",
        condition: productData.condition || "new",
        status: productData.status || "active",
      }).forEach(([k, v]) => formData.append(k, v));
      formData.append("image", imageFile);

      const res = await fetcher.upload(
        `/api/v1/products/${id}?_method=PATCH`,
        formData
      );
      return normalizeProduct(res?.data || res);
    }

    const res = await fetcher.patch(`/api/v1/products/${id}`, {
      name: productData.name,
      description: productData.description || "",
      price: productData.price,
      stock_quantity: productData.stock_quantity || 0,
      category: productData.category || "",
      condition: productData.condition || "new",
      status: productData.status || "active",
    });
    return normalizeProduct(res?.data || res);
  },

  async delete(id) {
    await fetcher.delete(`/api/v1/products/${id}/delete`);
    return true;
  },
};

export default productService;
