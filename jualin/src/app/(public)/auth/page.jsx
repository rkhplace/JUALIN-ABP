"use client";

import React, { useState } from "react";
import Link from "next/link";
import RegisterForm from "../../../components/auth/RegisterForm";
import Logo from "../../../components/ui/Logo";
import Toast from "../../../components/ui/Toast";

export default function RegisterPage() {
  const [toast, setToast] = useState(null);

  const handleSuccess = () => {
    setToast({
      message: "Registration successful! Redirecting...",
      type: "success",
    });
  };

  const handleError = (error) => {
    setToast({ message: error, type: "error" });
  };

  return (
    <div className="min-h-screen bg-white flex items-center justify-center relative overflow-hidden">
      {/* Background paint splashes */}
      <div className="absolute top-0 -right-48 w-96 h-96 bg-[#E83030] rounded-full mix-blend-multiply filter blur-3xl opacity-20"></div>
      <div className="absolute bottom-0 -left-24 w-48 h-48 bg-[#E83030] rounded-full mix-blend-multiply filter blur-3xl opacity-20"></div>

      {toast && (
        <Toast
          message={toast.message}
          type={toast.type}
          onClose={() => setToast(null)}
        />
      )}

      <div className="relative z-10 w-full max-w-4xl mx-4">
        <div className="bg-white rounded-2xl shadow-2xl p-8 md:p-10">
          <Logo size="xl" className="mb-6" />

          <div className="mb-6">
            <h1 className="text-2xl md:text-3xl font-bold text-gray-900 mb-2">
              Create your account
            </h1>
            <p className="text-gray-600 text-sm md:text-base">
              Start selling or buying today!
            </p>
          </div>

          <RegisterForm onSuccess={handleSuccess} onError={handleError} />

          <p className="mt-6 text-center text-sm text-gray-600">
            Already have an account?{" "}
            <Link
              href="/login"
              className="text-[#E83030] hover:text-red-600 font-medium"
            >
              Login here
            </Link>
          </p>
        </div>
      </div>
    </div>
  );
}
