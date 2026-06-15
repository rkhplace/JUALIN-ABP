"use client";
import React, { useState } from 'react';
import { useRouter } from 'next/navigation';
import { getProductImageUrl } from '@/utils/imageHelper';
import { formatCurrency } from '@/utils/formatters/currency';
import { X, ExternalLink, Tag, Package } from 'lucide-react';

export function ProductBubble({ message, userRole }) {
  const [isOpen, setIsOpen] = useState(false);
  const router = useRouter();
  const product = message.product;

  if (!product) return null;

  const imageUrl = getProductImageUrl(product.image || product.img);
  const isCustomer = userRole === 'customer';
  const isMe = message.isMe;

  const handleProductClick = () => {
    setIsOpen(true);
  };

  const handleViewDetail = () => {
    setIsOpen(false);
    const identifier = product.slug || product.id;
    if (identifier) {
      router.push(`/product/${identifier}`);
    }
  };

  return (
    <>
      {/* Product Bubble in Message List */}
      <div className={`flex ${isMe ? 'justify-end' : 'justify-start'} mb-4 px-3 md:px-6 min-w-0`}>
        <div className={`flex min-w-0 flex-col ${isMe ? 'items-end' : 'items-start'} max-w-[82%] md:max-w-[75%]`}>
          {/* Timestamp */}
          <span className="text-xs text-gray-400 mb-1.5 px-1">
            {message.time}
          </span>

          {/* Product Card Bubble */}
          <div
            onClick={handleProductClick}
            className={`
              rounded-2xl overflow-hidden cursor-pointer transition-all duration-200 
              hover:shadow-lg group border
              ${isMe
                ? 'bg-gradient-to-br from-red-500 to-red-600 border-red-400 rounded-br-md shadow-md'
                : 'bg-white border-gray-200 rounded-bl-md shadow-sm hover:border-red-300'
              }
            `}
            style={{ width: 'min(300px, 100%)', minWidth: 'min(240px, 100%)' }}
          >
            {/* Product Image */}
            <div className="relative w-full h-36 overflow-hidden bg-gray-100">
              <img
                src={imageUrl}
                alt={product.name}
                className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300"
                onError={(e) => {
                  e.target.src = "https://via.placeholder.com/300x144?text=No+Image";
                }}
              />
              {/* Product Badge */}
              <div className={`
                absolute top-2 left-2 flex items-center gap-1 px-2 py-1 rounded-full text-xs font-semibold
                ${isMe
                  ? 'bg-white/90 text-red-600'
                  : 'bg-red-500/90 text-white'
                }
              `}>
                <Package className="w-3 h-3" />
                <span>Produk</span>
              </div>
            </div>

            {/* Product Info */}
            <div className="p-3">
              <h4 className={`text-sm font-bold truncate mb-1 ${isMe ? 'text-white' : 'text-gray-900'}`}>
                {product.name}
              </h4>
              <div className="flex items-center justify-between">
                <p className={`text-sm font-bold ${isMe ? 'text-red-100' : 'text-red-500'}`}>
                  {formatCurrency(product.price)}
                </p>
                <ExternalLink className={`w-4 h-4 ${isMe ? 'text-red-200 group-hover:text-white' : 'text-gray-400 group-hover:text-red-500'} transition-colors`} />
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Modal (reused from ProductHighlight) */}
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
