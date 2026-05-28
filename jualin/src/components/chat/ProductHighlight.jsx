"use client";
import React, { useState } from 'react';
import { useRouter } from 'next/navigation';
import { getProductImageUrl } from '@/utils/imageHelper';
import { formatCurrency } from '@/utils/formatters/currency';
import { X, ExternalLink, Tag } from 'lucide-react';

export function ProductHighlight({ product, userRole }) {
  const [isOpen, setIsOpen] = useState(false);
  const router = useRouter();

  if (!product) return null;

  const imageUrl = getProductImageUrl(product.image || product.img);
  const isCustomer = userRole === 'customer';

  const handleProductClick = () => {
    setIsOpen(true);
  };

  const handleViewDetail = () => {
    setIsOpen(false);
    // Use slug if available, else id
    const identifier = product.slug || product.id;
    if (identifier) {
      router.push(`/product/${identifier}`);
    }
  };

  return (
    <>
      {/* Mini Product Card inside Chat */}
      <div 
        onClick={handleProductClick}
        className="mx-4 mt-2 mb-6 p-3 bg-white border border-gray-200 rounded-xl shadow-sm hover:shadow-md hover:border-red-300 transition-all cursor-pointer flex items-center gap-4 group shrink-0"
      >
        <div className="w-14 h-14 shrink-0 rounded-lg overflow-hidden bg-gray-100 border border-gray-100 group-hover:border-red-200 transition-colors">
          <img src={imageUrl} alt={product.name} className="w-full h-full object-cover" />
        </div>
        <div className="flex-1 min-w-0">
          <h4 className="text-sm font-bold text-gray-900 truncate group-hover:text-red-600 transition-colors">
            {product.name}
          </h4>
          <p className="text-xs font-semibold text-red-500 mt-0.5">
            {formatCurrency(product.price)}
          </p>
        </div>
        <div className="shrink-0 text-gray-400 group-hover:text-red-500 transition-colors pr-1">
          <ExternalLink className="w-5 h-5" />
        </div>
      </div>

      {/* Modal */}
      {isOpen && (
        <div className="fixed inset-0 z-[100] flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm">
          <div 
            className="bg-white rounded-2xl shadow-2xl w-full max-w-sm overflow-hidden animate-in fade-in zoom-in duration-300 flex flex-col"
            role="dialog"
            aria-modal="true"
          >
            {/* Modal Header */}
            <div className="relative">
              <div className="w-full h-56 bg-gray-100">
                <img src={imageUrl} alt={product.name} className="w-full h-full object-cover" />
              </div>
              <button
                onClick={(e) => {
                  e.stopPropagation();
                  setIsOpen(false);
                }}
                className="absolute top-3 right-3 p-1.5 bg-black/20 hover:bg-black/40 backdrop-blur-md rounded-full text-white transition-colors"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            {/* Modal Body */}
            <div className="p-5 flex-1 max-h-60 overflow-y-auto">
              <div className="flex items-start justify-between gap-3 mb-2">
                <h3 className="text-lg font-bold text-gray-900 leading-tight">
                  {product.name}
                </h3>
              </div>
              
              <div className="flex items-center gap-1.5 mb-4 text-red-600">
                <Tag className="w-4 h-4" />
                <span className="text-xl font-black tracking-tight">{formatCurrency(product.price)}</span>
              </div>

              {product.description && (
                <div className="mb-2">
                  <p className="text-sm text-gray-600 leading-relaxed font-normal whitespace-pre-wrap">
                    {product.description}
                  </p>
                </div>
              )}
            </div>

            {/* Modal Footer */}
            {isCustomer ? (
              <div className="p-5 border-t border-gray-100 bg-gray-50/50">
                <button
                  onClick={handleViewDetail}
                  className="w-full text-white bg-red-500 hover:bg-red-600 focus:ring-4 focus:outline-none focus:ring-red-300 font-bold rounded-xl text-sm px-5 py-3 transition-colors shadow-sm"
                >
                  View Detail
                </button>
              </div>
            ) : (
              <div className="p-4 border-t border-gray-100 bg-blue-50/50 text-center">
                <p className="text-xs font-medium text-blue-600">
                  Quick View Mode (Seller)
                </p>
              </div>
            )}
          </div>
        </div>
      )}
    </>
  );
}
