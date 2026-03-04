"use client";
import React, { useState } from "react";
import { useRouter } from "next/navigation";
import { productService } from "@/services/product/productService";
import ProductForm from "@/components/forms/ProductForm";

export default function BackofficeNewProductPage() {
  const router = useRouter();
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState("");

  const handleSubmit = async (formData) => {
    try {
      setSaving(true);
      setError("");

      const productData = {
        name: formData.name.trim(),
        description: formData.description.trim(),
        price: parseFloat(formData.price),
        stock_quantity: parseInt(formData.stock_quantity),
        category: formData.category.trim() || "",
        condition: formData.condition,
        status: formData.status,
      };

      const result = await productService.create(
        productData,
        formData.imageFile
      );

      if (result) {
        router.push("/backoffice/products");
      } else {
        setError("Gagal menambahkan produk");
      }
    } catch (err) {
      console.error("Failed to create product:", err);

      const validationErrors = err.originalError?.response?.data?.errors;
      if (validationErrors) {
        const firstError = Object.values(validationErrors).flat()[0];
        setError(firstError);
      } else {
        setError(err.message || "Gagal menambahkan produk");
      }
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="bg-[#F5F6FA] min-h-screen">
      <ProductForm
        title="Tambah Produk (Backoffice)"
        onSubmit={handleSubmit}
        saving={saving}
        error={error}
      />
    </div>
  );
}
