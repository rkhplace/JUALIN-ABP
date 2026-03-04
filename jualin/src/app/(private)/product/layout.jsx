"use client";
import React from "react";

export default function ProductLayout({ children }) {
  return (
    <main className="bg-[#fafafa] min-h-screen">
      <div className="w-full">{children}</div>
    </main>
  );
}
