"use client";

import Navbar from "@/components/ui/Navbar";
import BackofficeSidebar from "./sections/backoffice-sidebar";

export default function BackofficeLayout({ children }) {
  return (
    <div className="min-h-screen bg-[#F5F6FA] text-gray-900">
      <Navbar />
      <div className="flex">
        <div className="sticky top-0 hidden h-[calc(100vh-64px)] overflow-y-auto md:block">
          <BackofficeSidebar />
        </div>
        <main className="w-full min-w-0 flex-1 px-4 py-6 sm:px-6 lg:px-10 lg:py-8 space-y-8 lg:space-y-12 mb-10 overflow-x-hidden">
          {children}
        </main>
      </div>
    </div>
  );
}
