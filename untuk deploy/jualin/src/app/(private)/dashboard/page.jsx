"use client";
import { Suspense } from "react";
import BannerSection from "./sections/banner.jsx";
import RecommendedSection from "./sections/recommended.jsx";
import { banners } from "../../dummydata.jsx";
import { ProductCardSkeleton } from "@/components/ui/skeleton";

export default function DashboardPage() {
  return (
    <main className="bg-white">
      <BannerSection banners={banners} />
      <div className="max-w-7xl mx-auto px-2 sm:px-4">
        <Suspense
          fallback={
            <div className="w-full my-8">
              <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-8">
                {[...Array(6)].map((_, idx) => (
                  <ProductCardSkeleton key={idx} />
                ))}
              </div>
            </div>
          }
        >
          <RecommendedSection />
        </Suspense>
      </div>
    </main>
  );
}
