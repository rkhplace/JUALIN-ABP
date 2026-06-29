'use client';

import React, { useState } from 'react';
import Link from 'next/link';
import RegisterForm from '../../../../components/auth/RegisterForm';
import Logo from '../../../../components/ui/Logo';
import Toast from '../../../../components/ui/Toast';
import AuthBackground from '../../../../components/ui/AuthBackground';

export default function RegisterPage() {
  const [toast, setToast] = useState(null);

  const handleSuccess = () => {
    setToast({ message: 'Pendaftaran berhasil! Tunggu Sebentar...', type: 'success' });
  };

  const handleError = (error) => {
    setToast({ message: error, type: 'error' });
  };

  return (
    <div className="jualin-auth-bg min-h-dvh flex items-center justify-center p-4 sm:p-6">
      <AuthBackground />
      {toast && (
        <Toast
          message={toast.message}
          type={toast.type}
          onClose={() => setToast(null)}
        />
      )}

      <div className="relative z-10 w-full max-w-[390px] md:max-w-4xl">
        <div className="auth-card-shell bg-white p-5 sm:p-8 md:p-10">
          <Logo
            size="xl"
            className="mb-4 sm:mb-6 [&_img]:!h-20 [&_img]:!w-20 sm:[&_img]:!h-36 sm:[&_img]:!w-36"
          />

          <div className="mb-4 sm:mb-6">
            <h1 className="text-2xl md:text-3xl font-bold text-gray-900 mb-2">
              Daftar Akun
            </h1>
            <p className="text-gray-600 text-sm md:text-base">
              Mulai Jual atau Beli Sekarang!
            </p>
          </div>

          <RegisterForm onSuccess={handleSuccess} onError={handleError} />

          <p className="mt-4 sm:mt-6 text-center text-sm text-gray-600">
            Sudah Punya Akun?{' '}
            <Link href="/auth/login" className="text-[#E83030] hover:text-red-600 font-medium">
              Masuk disini
            </Link>
          </p>
        </div>
      </div>
    </div>
  );
}
