"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { LayoutDashboard, Users, Package, MessageSquareWarning } from "lucide-react";

export default function BackofficeSidebar() {
  const pathname = usePathname();

  const isActive = (path) => pathname === path;

  return (
    <aside className="w-64 bg-[#E83030] min-h-screen flex flex-col rounded-r-3xl z-10 transition-all duration-300">
      <div className="p-6">
        <div className="mb-8">
          <h3 className="text-xs font-bold text-white/90 uppercase tracking-wider mb-4 px-1">
            ADMIN
          </h3>
          <nav className="space-y-3">
            {/* Dashboard */}
            <Link
              href="/backoffice"
              className={`w-full flex items-center px-4 py-3 text-sm font-medium rounded-xl transition-all duration-200 shadow-sm hover:shadow-md hover:scale-[1.02] cursor-pointer ${isActive("/backoffice")
                ? "bg-white text-[#E83030] font-bold ring-2 ring-white/20"
                : "bg-white text-gray-700 hover:bg-gray-50"
                }`}
            >
              <LayoutDashboard
                className={`mr-3 h-5 w-5 ${isActive("/backoffice") ? "text-[#E83030]" : "text-gray-500"
                  }`}
              />
              Management User
            </Link>

            {/* Super Admin */}
            <Link
              href="/backoffice/super-admin"
              className={`w-full flex items-center px-4 py-3 text-sm font-medium rounded-xl transition-all duration-200 shadow-sm hover:shadow-md hover:scale-[1.02] cursor-pointer ${isActive("/backoffice/super-admin")
                ? "bg-white text-[#E83030] font-bold ring-2 ring-white/20"
                : "bg-white text-gray-700 hover:bg-gray-50"
                }`}
            >
              <Users
                className={`mr-3 h-5 w-5 ${isActive("/backoffice/super-admin")
                  ? "text-[#E83030]"
                  : "text-gray-500"
                  }`}
              />
              Super Admin
            </Link>

            {/* Reports */}
            <Link
              href="/backoffice/reports"
              className={`w-full flex items-center px-4 py-3 text-sm font-medium rounded-xl transition-all duration-200 shadow-sm hover:shadow-md hover:scale-[1.02] cursor-pointer ${isActive("/backoffice/reports")
                ? "bg-white text-[#E83030] font-bold ring-2 ring-white/20"
                : "bg-white text-gray-700 hover:bg-gray-50"
                }`}
            >
              <MessageSquareWarning
                className={`mr-3 h-5 w-5 ${isActive("/backoffice/reports")
                  ? "text-[#E83030]"
                  : "text-gray-500"
                  }`}
              />
              Laporan
            </Link>
          </nav>
        </div>
      </div>
    </aside>
  );
}
