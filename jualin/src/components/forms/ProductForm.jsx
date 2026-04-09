"use client";

import React, { useState, useRef, useEffect } from "react";
import { getProductImageUrl } from "@/utils/imageHelper";

export default function ProductForm({
  initialData,
  onSubmit,
  loading = false,
  saving = false,
  error: paramsError,
  title = "Form Produk",
}) {
  const fileInputRef = useRef(null);
  const [formData, setFormData] = useState({
    name: "",
    price: "",
    description: "",
    images: [],
    stock_quantity: "",
    category: "",
    condition: "new",
    status: "active",
  });
  const [imagePreviews, setImagePreviews] = useState([]);
  const [localError, setLocalError] = useState("");

  useEffect(() => {
    if (initialData) {
      const initialImages = initialData.image || initialData.images || [];
      const images = Array.isArray(initialImages) ? initialImages : (initialImages ? [initialImages] : []);
      
      setFormData({
        name: initialData.name || "",
        price: initialData.price || "",
        description: initialData.description || "",
        images: images,
        stock_quantity: initialData.stock_quantity || initialData.stock || "",
        category: initialData.category || "",
        condition: initialData.condition || "new",
        status: initialData.status || "active",
      });
      
      // Convert image paths to preview URLs
      const previews = images.filter(img => img).map(img => {
        return getProductImageUrl(img);
      });
      setImagePreviews(previews);
    }
  }, [initialData]);

  const handleInputChange = (e) => {
    const { name, value } = e.target;
    setFormData((prev) => ({
      ...prev,
      [name]: value,
    }));
  };

  const handleImageSelect = (e) => {
    const files = Array.from(e.target.files || []);
    if (files.length === 0) return;

    const maxSize = 2 * 1024 * 1024; // 2MB
    const validFiles = [];
    const newPreviews = [...imagePreviews];
    let hasError = false;

    for (const file of files) {
      if (!file.type.startsWith("image/")) {
        setLocalError("Semua file harus berupa gambar (JPG atau PNG)");
        hasError = true;
        break;
      }
      if (file.size > maxSize) {
        setLocalError(
          "Ukuran gambar terlalu besar. Maksimal 2MB per gambar. Silakan gunakan gambar dengan ukuran lebih kecil atau kompres terlebih dahulu."
        );
        hasError = true;
        break;
      }
      validFiles.push(file);
      newPreviews.push(URL.createObjectURL(file));
    }

    if (hasError) return;

    // Store files for later submission
    setFormData((prev) => ({
      ...prev,
      imageFiles: [...(prev.imageFiles || []), ...validFiles],
    }));
    setImagePreviews(newPreviews);
    setLocalError("");
  };

  const handleRemoveImage = (index) => {
    setImagePreviews((prev) => prev.filter((_, i) => i !== index));
    setFormData((prev) => ({
      ...prev,
      imageFiles: (prev.imageFiles || []).filter((_, i) => i !== index),
      images: (prev.images || []).filter((_, i) => i !== index),
    }));
  };

  const handleUploadClick = () => {
    fileInputRef.current?.click();
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    setLocalError("");

    if (!formData.name.trim()) {
      setLocalError("Nama produk wajib diisi");
      return;
    }
    if (!formData.price || parseFloat(formData.price) <= 0) {
      setLocalError("Harga produk wajib diisi dan harus lebih dari 0");
      return;
    }
    if (!formData.description.trim()) {
      setLocalError("Deskripsi produk wajib diisi");
      return;
    }
    if (
      formData.stock_quantity === "" ||
      parseInt(formData.stock_quantity) < 0
    ) {
      setLocalError("Stok produk wajib diisi dan tidak boleh negatif");
      return;
    }

    onSubmit(formData);
  };

  if (loading) {
    return (
      <div className="max-w-4xl mx-auto px-4 py-8">
        <div className="h-8 bg-gray-200 rounded-lg w-48 mb-8 animate-pulse"></div>
        <div className="mb-8 p-8 border-2 border-gray-200 rounded-2xl bg-white shadow-lg">
          <div className="flex items-start gap-6">
            <div className="flex-shrink-0">
              <div className="w-32 h-32 rounded-full bg-gray-200 animate-pulse"></div>
            </div>
            <div className="flex-1 space-y-3">
              <div className="h-10 bg-gray-200 rounded-lg w-40 animate-pulse"></div>
              <div className="h-4 bg-gray-200 rounded w-64 animate-pulse"></div>
              <div className="h-4 bg-gray-200 rounded w-48 animate-pulse"></div>
            </div>
          </div>
        </div>
        <div className="mb-8 p-8 border-2 border-gray-200 rounded-2xl bg-white shadow-lg">
          <div className="h-7 bg-gray-200 rounded-lg w-40 mb-6 animate-pulse"></div>
          <div className="space-y-6">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div className="space-y-2">
                <div className="h-5 bg-gray-200 rounded w-32 animate-pulse"></div>
                <div className="h-12 bg-gray-200 rounded-lg animate-pulse"></div>
              </div>
              <div className="space-y-2">
                <div className="h-5 bg-gray-200 rounded w-32 animate-pulse"></div>
                <div className="h-12 bg-gray-200 rounded-lg animate-pulse"></div>
              </div>
            </div>
            <div className="space-y-2">
              <div className="h-5 bg-gray-200 rounded w-36 animate-pulse"></div>
              <div className="h-32 bg-gray-200 rounded-lg animate-pulse"></div>
            </div>
            <div className="pt-4">
              <div className="h-12 bg-gray-200 rounded-lg animate-pulse"></div>
            </div>
          </div>
        </div>
      </div>
    );
  }

  const error = localError || paramsError;

  return (
    <div className="max-w-4xl mx-auto px-4 py-8">
      <h1 className="text-2xl font-bold text-gray-900 mb-8">{title}</h1>

      {/* Photo Upload Section */}
      <div className="mb-8 p-8 border-2 border-gray-200 rounded-2xl bg-white shadow-lg hover:shadow-2xl transition-shadow duration-200">
        <div className="mb-6">
          <button
            type="button"
            onClick={handleUploadClick}
            className="px-6 py-2 bg-brand-red text-white rounded-lg hover:bg-red-600 transition-colors text-sm font-medium shadow-sm"
          >
            {imagePreviews.length > 0 ? "Add more photos" : "Upload photos"}
          </button>
          <input
            ref={fileInputRef}
            type="file"
            accept="image/jpeg,image/jpg,image/png"
            multiple
            className="hidden"
            onChange={handleImageSelect}
          />
          <p className="text-sm text-gray-600 mt-3">
            Dengan 'Ctrl' atau 'Cmd', Anda bisa memilih banyak foto sekaligus.
          </p>
          <p className="text-sm text-gray-600">JPG atau PNG (Min 800x800px, Max 2MB per gambar)</p>
        </div>

        {/* Image Previews Gallery */}
        {imagePreviews.length > 0 && (
          <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-4">
            {imagePreviews.map((preview, index) => (
              <div
                key={index}
                className="relative group rounded-lg overflow-hidden bg-gray-100 aspect-square border-2 border-gray-200 hover:border-brand-red transition-colors"
              >
                <img
                  src={preview}
                  alt={`Product preview ${index + 1}`}
                  className="w-full h-full object-cover"
                />
                <button
                  type="button"
                  onClick={() => handleRemoveImage(index)}
                  className="absolute inset-0 bg-black/50 flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity"
                >
                  <svg
                    className="w-6 h-6 text-white"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      strokeWidth={2}
                      d="M6 18L18 6M6 6l12 12"
                    />
                  </svg>
                </button>
                <span className="absolute top-2 right-2 bg-brand-red text-white text-xs font-semibold px-2 py-1 rounded">
                  {index + 1}
                </span>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Error Message */}
      {error && (
        <div className="mb-6 p-4 bg-red-50 border border-red-200 rounded-lg text-red-700 text-sm">
          {error}
        </div>
      )}

      {/* Product Details Form */}
      <div className="mb-8 p-8 border-2 border-gray-200 rounded-2xl bg-white shadow-lg hover:shadow-2xl transition-shadow duration-200">
        <h2 className="text-xl font-semibold text-gray-900 mb-6">
          Detail Produk
        </h2>

        <form onSubmit={handleSubmit} className="space-y-6">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            {/* Nama Produk */}
            <div>
              <label
                htmlFor="name"
                className="block text-sm font-medium text-gray-700 mb-2"
              >
                Nama Produk <span className="text-red-500">*</span>
              </label>
              <input
                type="text"
                id="name"
                name="name"
                value={formData.name}
                onChange={handleInputChange}
                placeholder="Enter your product"
                className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-brand-red focus:border-transparent hover:border-brand-red hover:shadow-md outline-none shadow-sm transition-all duration-300 ease-in-out"
                required
              />
            </div>

            {/* Harga Produk */}
            <div>
              <label
                htmlFor="price"
                className="block text-sm font-medium text-gray-700 mb-2"
              >
                Harga Produk <span className="text-red-500">*</span>
              </label>
              <input
                type="number"
                id="price"
                name="price"
                value={formData.price}
                onChange={handleInputChange}
                placeholder="Enter your price product"
                min="0"
                step="1"
                className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-brand-red focus:border-transparent hover:border-brand-red hover:shadow-md outline-none shadow-sm transition-all duration-300 ease-in-out"
                required
              />
            </div>

            {/* Stock Quantity */}
            <div>
              <label
                htmlFor="stock_quantity"
                className="block text-sm font-medium text-gray-700 mb-2"
              >
                Stok Produk <span className="text-red-500">*</span>
              </label>
              <input
                type="number"
                id="stock_quantity"
                name="stock_quantity"
                value={formData.stock_quantity}
                onChange={handleInputChange}
                placeholder="Enter stock quantity"
                min="0"
                step="1"
                className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-brand-red focus:border-transparent hover:border-brand-red hover:shadow-md outline-none shadow-sm transition-all duration-300 ease-in-out"
                required
              />
            </div>

            {/* Category */}
            <div>
              <label
                htmlFor="category"
                className="block text-sm font-medium text-gray-700 mb-2"
              >
                Kategori
              </label>
              <select
                id="category"
                name="category"
                value={formData.category}
                onChange={handleInputChange}
                className="w-full px-4 py-3 border border-gray-300 rounded-lg ..."
              >
                <option value="">Pilih kategori</option>
                <option value="Elektronik">Elektronik</option>
                <option value="Fashion">Fashion</option>
                <option value="Hobi & Olahraga">Hobi & Olahraga</option>
                <option value="Rumah Tangga">Rumah Tangga</option>
                <option value="Aksesoris">Aksesoris</option>
                <option value="Otomotif">Otomotif</option>
              </select>
            </div>

            {/* Condition */}
            <div>
              <label
                htmlFor="condition"
                className="block text-sm font-medium text-gray-700 mb-2"
              >
                Kondisi
              </label>
              <select
                id="condition"
                name="condition"
                value={formData.condition}
                onChange={handleInputChange}
                className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-brand-red focus:border-transparent hover:border-brand-red hover:shadow-md outline-none shadow-sm transition-all duration-300 ease-in-out"
              >
                <option value="new">Baru</option>
                <option value="used">Bekas</option>
              </select>
            </div>

            {/* Status */}
            <div>
              <label
                htmlFor="status"
                className="block text-sm font-medium text-gray-700 mb-2"
              >
                Status
              </label>
              <select
                id="status"
                name="status"
                value={formData.status}
                onChange={handleInputChange}
                className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-brand-red focus:border-transparent hover:border-brand-red hover:shadow-md outline-none shadow-sm transition-all duration-300 ease-in-out"
              >
                <option value="active">Aktif</option>
                <option value="inactive">Tidak Aktif</option>
              </select>
            </div>
          </div>

          {/* Deskripsi Produk */}
          <div>
            <label
              htmlFor="description"
              className="block text-sm font-medium text-gray-700 mb-2"
            >
              Deskripsi Produk <span className="text-red-500">*</span>
            </label>
            <textarea
              id="description"
              name="description"
              value={formData.description}
              onChange={handleInputChange}
              placeholder="Enter your description product"
              rows={6}
              className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-brand-red focus:border-transparent hover:border-brand-red hover:shadow-md outline-none shadow-sm transition-all duration-300 ease-in-out resize-none"
              required
            />
          </div>

          {/* Save Button */}
          <div className="pt-4">
            <button
              type="submit"
              disabled={saving}
              className="w-full bg-brand-red text-white py-3 rounded-lg font-medium hover:bg-red-600 transition-colors shadow-sm disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {saving ? "Menyimpan..." : "Simpan"}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
