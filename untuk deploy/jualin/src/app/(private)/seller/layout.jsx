import React from "react";
import SellerGuard from "./dashboard/SellerGuard.jsx";

export const metadata = {
  title: "Jualin - Seller",
  description: "Seller workspace",
};

export default function SellerLayout({ children }) {
  return (
    <div className="min-h-screen bg-gray-50 font-sans antialiased">
      <SellerGuard>
        <div className="w-full">{children}</div>
      </SellerGuard>
    </div>
  );
}

