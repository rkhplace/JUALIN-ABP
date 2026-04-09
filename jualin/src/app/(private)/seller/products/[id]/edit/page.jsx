"use client";
import React, { useEffect, useState } from "react";
import { useRouter, useParams } from "next/navigation";
import { productService } from "@/services/product/productService";
import ProductForm from "@/components/forms/ProductForm";

export default function EditProductPage() {
  const router = useRouter();
  const params = useParams();
  const productId = params.id;

  const [productData, setProductData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState("");

  useEffect(() => {
    const loadProduct = async () => {
      try {
        setLoading(true);
        const product = await productService.fetchById(productId);
        if (product) {
          setProductData(product);
        } else {
          setError("Produk tidak ditemukan");
        }
      } catch (err) {
        console.error("Failed to load product:", err);
        setError("Gagal memuat data produk");
      } finally {
        setLoading(false);
      }
    };

    if (productId) {
      loadProduct();
    }
  }, [productId]);

  const handleSubmit = async (formData) => {
    try {
      setSaving(true);
      setError("");

      const payload = {
        name: formData.name.trim(),
        price: parseFloat(formData.price),
        description: formData.description.trim(),
        stock_quantity: parseInt(formData.stock_quantity),
        category: formData.category,
        condition: formData.condition,
        status: formData.status,
      };

      const updatedProduct = await productService.update(
        productId,
        payload,
        formData.imageFiles || []
      );

      if (updatedProduct) {
        router.push("/seller/products");
      } else {
        setError("Gagal menyimpan perubahan");
      }
    } catch (err) {
      console.error("Failed to update product:", err);

      const validationErrors = err.originalError?.response?.data?.errors;
      if (validationErrors) {
        const firstError = Object.values(validationErrors).flat()[0];
        setError(firstError);
      } else {
        setError("Gagal menyimpan perubahan");
      }
    } finally {
      setSaving(false);
    }
  };

  return (
    <main className="bg-white min-h-screen">
      <ProductForm
        title="Edit Produk"
        initialData={productData}
        onSubmit={handleSubmit}
        loading={loading}
        saving={saving}
        error={error}
      />
    </main>
  );
}
