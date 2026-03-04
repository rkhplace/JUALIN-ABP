"use client";

import React, { useState, useContext } from "react";
import { useRouter } from "next/navigation";
import Input from "../ui/Input";
import Button from "../ui/Button";
import { authService } from "@/services/auth/authService";
import { useAuth } from "@/context/AuthProvider";

const LoginForm = ({ onSuccess, onError }) => {
  const router = useRouter();
  const { login, refetchUser } = useAuth();
  const [formData, setFormData] = useState({
    email: "",
    password: "",
    rememberMe: false,
  });
  const [isLoading, setIsLoading] = useState(false);

  const handleChange = (e) => {
    const { name, value, type, checked } = e.target;
    setFormData((prev) => ({
      ...prev,
      [name]: type === "checkbox" ? checked : value,
    }));
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setIsLoading(true);

    try {
      const data = await authService.login(formData.email, formData.password);
      if (!data?.access_token)
        throw new Error("Login gagal: token tidak ditemukan.");

      const role = String(
        data.role || data.user?.role || "customer"
      ).toLowerCase();
      const userData = {
        id: data.user?.id || null,
        email: data.user?.email || data.email,
        username: data.user?.username || data.username || data.email,
        name:
          data.user?.name || data.username || data.user?.email || data.email,
        role,
        avatar: data.user?.avatar || data.user?.profile_picture || null,
      };

      login(userData, data.access_token);
      await refetchUser();

      onSuccess?.();

      if (role === "admin") {
        router.push("/backoffice");
      } else if (role === "seller") {
        router.push("/seller/dashboard");
      } else {
        router.push("/dashboard");
      }
    } catch (error) {
      onError?.(
        error.message || "Login failed - please check your credentials"
      );
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      <Input
        label="Email"
        type="email"
        name="email"
        placeholder="Masukkan Alamat Email"
        value={formData.email}
        onChange={handleChange}
        required
      />
      <Input
        label="Kata Sandi"
        type="password"
        name="password"
        placeholder="Masukkan Kata Sandi"
        value={formData.password}
        onChange={handleChange}
        required
      />
      <div className="flex items-center justify-between">
        <label className="flex items-center">
          <input
            id="remember-me"
            name="rememberMe"
            type="checkbox"
            checked={formData.rememberMe}
            onChange={handleChange}
            className="h-4 w-4 text-[#E83030] focus:ring-[#E83030] border-gray-300 rounded"
          />
          <span className="ml-2 block text-sm text-gray-700">Ingat Saya</span>
        </label>
        <a
          href="/auth/forgot-password"
          className="text-sm text-[#E83030] hover:text-red-600 font-medium"
        >
          Lupa Kata Sandi?
        </a>
      </div>
      <Button type="submit" variant="primary" loading={isLoading}>
        {isLoading ? "Masuk..." : "Masuk"}
      </Button>
    </form>
  );
};

export default LoginForm;
