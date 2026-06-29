"use client";
import React from "react";

const FILTERS = [
  { label: "Semua", value: "all" },
  { label: "Elektronik", value: "Elektronik" },
  { label: "Fashion", value: "Fashion" },
  { label: "Hobi & Olahraga", value: "Hobi & Olahraga" },
  { label: "Rumah Tangga", value: "Rumah Tangga" },
  { label: "Aksesoris", value: "Aksesoris" },
  { label: "Otomotif", value: "Otomotif" },
];

export default function ProductFilter({ activeFilter, setActiveFilter }) {
  return (
    <div className="mb-5 flex gap-2 overflow-x-auto px-1 pb-2 -mx-1 scrollbar-hide sm:gap-3 sm:mb-6 md:mx-0 md:flex-wrap md:justify-center md:overflow-x-visible md:px-0 md:pb-0">
      {FILTERS.map((filter) => (
        <button
          key={filter.value}
          className={`flex-shrink-0 rounded-full border px-3 py-1 text-sm font-semibold shadow transition-all duration-200 hover:-translate-y-0.5 hover:shadow-lg active:scale-95 cursor-pointer sm:px-4 sm:text-base
            ${activeFilter === filter.value
              ? "bg-red-500 text-white border-red-500 shadow-md hover:shadow-lg"
              : "bg-white text-gray-700 border-gray-300 hover:bg-gray-100 hover:border-gray-400 shadow-sm"
            }
          `}
          onClick={() => setActiveFilter(filter.value)}
          type="button"
        >
          {filter.label}
        </button>
      ))}
    </div>
  );
}
