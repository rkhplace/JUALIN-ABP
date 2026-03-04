"use client";
import React, { useState, useEffect } from "react";
import { useRouter, useSearchParams, usePathname } from "next/navigation";

function SearchBar({ inline = false, className = "" }) {
  const router = useRouter();
  const searchParams = useSearchParams();
  const pathname = usePathname();
  const initialValue = searchParams.get("q") || "";

  const [value, setValue] = useState(initialValue);
  const [isFocused, setIsFocused] = useState(false);

  useEffect(() => {
    setValue(initialValue);
  }, [initialValue]);

  const handleSearch = () => {
    const trimmedValue = value.trim();

    if (!pathname.startsWith("/products")) {
      const target = trimmedValue
        ? `/products?q=${encodeURIComponent(trimmedValue)}`
        : "/products";
      router.push(target);
      return;
    }

    const params = new URLSearchParams(searchParams.toString());

    if (trimmedValue) {
      params.set("q", trimmedValue);  
      params.delete("category");
      params.set("page", "1");
    } else {
      params.delete("q");
      params.set("page", "1");
    }

    const queryString = params.toString();
    const url = queryString ? `${pathname}?${queryString}` : pathname;
    router.push(url);
  };

  const handleKeyDown = (e) => {
    if (e.key === "Enter") {
      handleSearch();
    }
  };

  const inputEl = (
    <input
      type="text"
      value={value}
      onChange={(e) => setValue(e.target.value)}
      onKeyDown={handleKeyDown}
      onFocus={() => setIsFocused(true)}
      onBlur={() => setIsFocused(false)}
      placeholder="Cari produk, merek, atau deskripsi"
      className={`w-full px-4 py-2.5 sm:py-3 bg-white border border-gray-300 rounded-2xl shadow-sm text-gray-800 placeholder-gray-400 focus:outline-none focus:shadow-xl focus:border-gray-300 focus:-translate-y-1 transition-all duration-200 hover:shadow-md hover:border-gray-400 hover:bg-gray-50 ${className}`}
      aria-label="Search products"
    />
  );

  if (inline) {
    return (
      <div className="w-full pl-2 sm:pl-4 pr-4 sm:pr-12">
        <div className="max-w-7xl mx-auto">{inputEl}</div>
      </div>
    );
  }

  return (
    <section className="mt-4 sm:mt-6 mb-8 w-full">
      <div className="max-w-7xl mx-auto px-2 sm:px-4 py-3">
        <div className="w-full px-12 flex justify-center">{inputEl}</div>
      </div>
    </section>
  );
}

export default SearchBar;
