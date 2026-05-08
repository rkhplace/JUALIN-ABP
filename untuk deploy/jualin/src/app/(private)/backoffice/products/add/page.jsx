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
      console.log("🚀 Starting product creation (backoffice)...", formData);

      const productData = {
        name: formData.name.trim(),
        description: formData.description.trim(),
        price: parseFloat(formData.price),
        stock_quantity: parseInt(formData.stock_quantity),
        category: formData.category.trim() || "",
        condition: formData.condition,
        status: formData.status,
      };

      console.log("📦 Product data prepared:", productData);
      console.log("🖼️ Image files:", formData.imageFiles);

      // Call service and await for completion
      const createdProduct = await productService.create(
        productData,
        formData.imageFiles || []
      );
      
      console.log("✅ Product created successfully:", createdProduct);
      console.log("🔄 Redirecting to /backoffice/products...");
      
      // Use window.location.href directly - most reliable method
      setTimeout(() => {
        console.log("⏸️ Executing redirect via window.location.href");
        window.location.href = "/backoffice/products";
      }, 300);
      
    } catch (err) {
      console.error("❌ Error creating product:", err);
      console.error("Error details:", {
        message: err?.message,
        statusCode: err?.statusCode,
        response: err?.originalError?.response?.data,
      });

      // Show user-friendly error
      if (err?.statusCode === 422) {
        // Validation errors
        const validationErrors = err?.originalError?.response?.data?.errors;
        if (validationErrors && typeof validationErrors === 'object') {
          const firstError = Object.values(validationErrors).flat()[0];
          setError(firstError || "Validasi gagal");
        } else {
          setError(err?.message || "Data tidak valid");
        }
      } else {
        setError(err?.message || "Gagal menambahkan produk. Silakan coba lagi.");
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
