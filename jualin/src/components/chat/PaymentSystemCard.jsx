"use client";

import Image from "next/image";
import { BadgeCheck, Package, TriangleAlert } from "lucide-react";
import { getProductImageUrl } from "@/utils/imageHelper";
import { formatCurrency } from "@/utils/formatters/currency";

export function PaymentSystemCard({ message, userRole }) {
  const data = message.product || {};
  const isSeller = String(userRole || "customer").toLowerCase() === "seller";
  const instruction = isSeller ? data.seller_message : data.customer_message;
  const imageUrl = data.image ? getProductImageUrl(data.image) : null;
  const otherItems = Number(data.other_items_count || 0);

  return (
    <article className="mx-auto mb-5 w-full max-w-xl shrink-0 overflow-hidden rounded-3xl border border-emerald-200 bg-gradient-to-br from-emerald-50 via-white to-white shadow-[0_18px_45px_-24px_rgba(5,150,105,0.55)]">
      <div className="p-4 sm:p-5">
        <header className="flex items-center gap-3">
          <span className="grid h-11 w-11 shrink-0 place-items-center rounded-full bg-emerald-600 text-white shadow-lg shadow-emerald-200">
            <BadgeCheck className="h-6 w-6" aria-hidden="true" />
          </span>
          <div>
            <p className="text-[11px] font-black uppercase tracking-[0.14em] text-emerald-700">Pembayaran berhasil</p>
            <h3 className="mt-0.5 text-sm font-bold text-gray-800 sm:text-base">Terverifikasi oleh Jualin</h3>
          </div>
        </header>

        <div className="mt-4 flex items-center gap-3 rounded-2xl border border-emerald-100 bg-white p-3 shadow-sm">
          <div className="relative grid h-16 w-16 shrink-0 place-items-center overflow-hidden rounded-xl bg-gray-100 text-gray-400">
            {imageUrl ? (
              <Image src={imageUrl} alt={data.name || "Barang transaksi"} fill sizes="64px" className="object-cover" unoptimized />
            ) : (
              <Package className="h-6 w-6" aria-hidden="true" />
            )}
          </div>
          <div className="min-w-0 flex-1">
            <p className="line-clamp-2 text-sm font-extrabold text-gray-900">{data.name || "Pesanan Jualin"}</p>
            {otherItems > 0 && <p className="mt-0.5 text-xs text-gray-500">+{otherItems} barang lainnya</p>}
            <p className="mt-1 text-sm font-black text-[#E53935]">{formatCurrency(data.amount || 0)}</p>
          </div>
        </div>

        <p className="mt-4 text-sm leading-6 text-gray-700">{instruction || message.content}</p>

        <div className="mt-3 flex items-start gap-2 rounded-xl bg-amber-50 px-3 py-2.5 text-amber-800 ring-1 ring-amber-100">
          <TriangleAlert className="mt-0.5 h-4 w-4 shrink-0" aria-hidden="true" />
          <p className="text-xs font-semibold leading-5">{data.warning}</p>
        </div>
      </div>
      <footer className="border-t border-emerald-100 bg-emerald-50/70 px-5 py-2 text-center text-[11px] font-semibold text-emerald-700">
        Pesan sistem ini dibuat otomatis dan tidak dapat diedit
      </footer>
    </article>
  );
}
