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
    <div className="flex gap-3 mb-6 overflow-x-auto pb-2 -mx-1 px-1 scrollbar-hide md:overflow-x-visible md:flex-wrap md:justify-center md:pb-0 md:mx-0 md:px-0">
      {FILTERS.map((filter) => (
        <button
          key={filter.value}
          className={`flex-shrink-0 rounded-full px-4 py-1 font-semibold border transition-all duration-200 shadow hover:shadow-lg hover:-translate-y-0.5 active:scale-95 cursor-pointer
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
