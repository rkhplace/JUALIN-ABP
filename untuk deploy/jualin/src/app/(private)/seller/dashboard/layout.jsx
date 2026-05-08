import React from "react";
import SellerGuard from "./SellerGuard.jsx";

export const metadata = {
  title: "Jualin - Seller Dashboard",
  description: "Manage your products and monitor buyers",
  icons: {
    icon: [
      { url: "/icon-light-32x32.png", media: "(prefers-color-scheme: light)" },
      { url: "/icon-dark-32x32.png", media: "(prefers-color-scheme: dark)" },
      { url: "/icon.svg", type: "image/svg+xml" },
    ],
    apple: "/apple-icon.png",
  },
};

export default function SellerDashboardLayout({ children }) {
  return (
    <div className="min-h-screen bg-gray-50 font-sans antialiased">
      <SellerGuard>
        <div className="w-full">{children}</div>
      </SellerGuard>
    </div>
  );
}
