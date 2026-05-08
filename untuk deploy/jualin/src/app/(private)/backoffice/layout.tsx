"use client";

import Navbar from "@/components/ui/Navbar";
import BackofficeSidebar from "./sections/backoffice-sidebar";

export default function BackofficeLayout({ children }) {
  return (
    <div className="min-h-screen bg-[#F5F6FA] text-gray-900">
      <Navbar />
      <div className="flex">
        <div className="sticky top-0 h-[calc(100vh-64px)] overflow-y-auto">
             <BackofficeSidebar />
        </div>
        <main className="flex-1 px-10 py-8 space-y-12 mb-10 overflow-x-hidden">
          {children}
        </main>
      </div>
    </div>
  );
}
