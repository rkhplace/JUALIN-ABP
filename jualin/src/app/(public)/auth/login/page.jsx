'use client';

import React, { useState } from 'react';
import Link from 'next/link';
import LoginForm from '../../../../components/auth/LoginForm';
import Logo from '../../../../components/ui/Logo';
import Toast from '../../../../components/ui/Toast';
import AuthBackground from '../../../../components/ui/AuthBackground';

export default function LoginPage() {
  const [toast, setToast] = useState(null);

  const handleSuccess = () => {
    setToast({ message: 'Masuk berhasil! Tunggu Sebentar...', type: 'success' });
  };

  const handleError = (error) => {
    setToast({ message: error, type: 'error' });
  };

  return (
    <div className="jualin-auth-bg min-h-screen flex items-center justify-center px-4 py-8">
      <AuthBackground />
      {toast && (
        <Toast
          message={toast.message}
          type={toast.type}
          onClose={() => setToast(null)}
        />
      )}

      <div className="relative z-10 w-full max-w-md mx-4">
        <div className="auth-card-shell bg-white p-8 md:p-10">
          <Logo size="xl" className="mb-6" />

          <div className="mb-6">
            <h1 className="text-xl md:text-2xl font-bold text-gray-900 mb-2">
              Selamat Datang Kembali !
            </h1>
            <p className="text-gray-600 text-xs md:text-base">
              Masuk untuk mendapatkan harga terbaik!
            </p>
          </div>

          <LoginForm onSuccess={handleSuccess} onError={handleError} />

          <p className="mt-6 text-center text-sm text-gray-600">
            Belum Punya Akun?{' '}
            <Link href="/auth/register" className="text-[#E83030] hover:text-red-600 font-medium">
              Daftar disini
            </Link>
          </p>
        </div>
      </div>
    </div>
  );
}
