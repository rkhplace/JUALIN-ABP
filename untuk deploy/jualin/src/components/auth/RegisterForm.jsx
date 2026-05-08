"use client";

import React, { useState } from "react";
import { useRouter } from "next/navigation";
import Input from "../ui/Input";
import Button from "../ui/Button";
import Select from "../ui/Select";
import { useAuth } from "@/context/AuthProvider";
import { authService } from "@/services/auth/authService";

const RegisterForm = ({ onSuccess, onError }) => {
  const router = useRouter();
  const { login } = useAuth();

  const [formData, setFormData] = useState({
    name: "",
    email: "",
    password: "",
    password_confirmation: "",
    role: "customer",
  });
  const [isLoading, setIsLoading] = useState(false);
  const [errors, setErrors] = useState({});

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData((prev) => ({ ...prev, [name]: value }));
    if (errors[name]) setErrors((prev) => ({ ...prev, [name]: "" }));
  };

  const handleRoleChange = (value) => {
    setFormData((prev) => ({ ...prev, role: value }));
    if (errors.role) setErrors((prev) => ({ ...prev, role: "" }));
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setIsLoading(true);
    setErrors({});

    const newErrors = {};
    const rawUsername = formData.name.toLowerCase().replace(/\s+/g, "");
    if (!formData.name.trim()) newErrors.name = "nama tidak boleh kosong";
    else if (rawUsername.length < 3)
      newErrors.name = "nama menghasilkan username minimal 3 karakter";
    if (!formData.email.trim()) newErrors.email = "email tidak boleh kosong";
    if (!formData.password || formData.password.length < 8)
      newErrors.password = "password minimal 8 karakter";
    if (!formData.password_confirmation)
      newErrors.password_confirmation = "konfirmasi kata sandi wajib";
    if (formData.password !== formData.password_confirmation)
      newErrors.password_confirmation = "password tidak sesuai";
    if (!formData.role) newErrors.role = "role tidak boleh kosong";

    if (Object.keys(newErrors).length) {
      setErrors(newErrors);
      setIsLoading(false);
      return;
    }

    try {
      const payload = {
        username: rawUsername,
        email: formData.email,
        password: formData.password,
        password_confirmation: formData.password_confirmation,
        role: formData.role,
      };

      const result = await authService.register(payload);
      if (!result?.access_token || !result?.user) {
        throw new Error("Registrasi berhasil namun token/user tidak tersedia.");
      }

      const role = String(
        result.role || result.user?.role || formData.role || "customer"
      ).toLowerCase();

      const userData = {
        id: result.user.id,
        email: result.user.email,
        username: result.user.username || payload.username,
        name: result.user.name || result.user.username || result.user.email,
        role,
        avatar: result.user.avatar || result.user.profile_picture || null,
      };

      login(userData, result.access_token);
      onSuccess?.();
      router.push(role === "seller" ? "/seller/dashboard" : "/dashboard");
    } catch (err) {
      const status = err?.statusCode || err?.originalError?.response?.status;
      const apiMessage = err?.message || "terjadi kesalahan";
      const fieldErrors =
        err?.errors || err?.originalError?.response?.data?.errors || null;

      if (fieldErrors && typeof fieldErrors === "object") {
        const mapped = {};
        Object.entries(fieldErrors).forEach(([field, messages]) => {
          const firstMsg = Array.isArray(messages)
            ? messages[0]
            : String(messages);
          if (field === "username") mapped.name = firstMsg;
          else if (field in formData) mapped[field] = firstMsg;
          else mapped.email = mapped.email || firstMsg;
        });
        setErrors(mapped);
      }

      if (status !== 422) onError?.(apiMessage);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        <Input
          label="Nama Lengkap"
          type="text"
          name="name"
          placeholder="Masukkan Nama Lengkap"
          value={formData.name}
          onChange={handleChange}
          required
          error={errors.name}
        />

        <Input
          label="Kata Sandi"
          type="password"
          name="password"
          placeholder="Buat Kata Sandi"
          value={formData.password}
          onChange={handleChange}
          required
          error={errors.password}
        />

        <Input
          label="Email"
          type="email"
          name="email"
          placeholder="Masukkan Alamat Email"
          value={formData.email}
          onChange={handleChange}
          required
          error={errors.email}
        />

        <Input
          label="Konfirmasi Kata Sandi"
          type="password"
          name="password_confirmation"
          placeholder="Konfirmasi Kata Sandi"
          value={formData.password_confirmation}
          onChange={handleChange}
          required
          error={errors.password_confirmation}
        />
      </div>

      <div className="mb-4">
        <Select
          label="Role"
          value={formData.role}
          onChange={handleRoleChange}
          options={[
            { value: "customer", label: "Customer (Buyer)" },
            { value: "seller", label: "Seller" },
          ]}
          placeholder="Pilih Role"
          required
          error={errors.role}
        />
      </div>

      <Button type="submit" variant="primary" loading={isLoading}>
        {isLoading ? "Mendaftar..." : "Daftar"}
      </Button>
    </form>
  );
};

export default RegisterForm;
