"use client";

import React, { useMemo, useState } from "react";
import { Circle, MapContainer, Marker, TileLayer } from "react-leaflet";
import L from "leaflet";
import { LocateFixed, MapPin, Navigation, Radar } from "lucide-react";

export default function ProductLocationMap({
  latitude,
  longitude,
  radiusKm = 10,
  label = "Lokasi produk",
}) {
  const [distanceStatus, setDistanceStatus] = useState("");
  const [checkingDistance, setCheckingDistance] = useState(false);
  const markerIcon = useMemo(
    () =>
      L.divIcon({
        className: "",
        html: '<div class="h-11 w-11 -translate-x-1/2 -translate-y-1/2 rounded-full bg-white/95 shadow-[0_16px_35px_rgba(232,48,48,0.28)] ring-1 ring-red-100 flex items-center justify-center"><div class="h-7 w-7 rounded-full bg-[#E83030] shadow-sm"></div></div>',
        iconSize: [44, 44],
        iconAnchor: [22, 22],
      }),
    []
  );

  const hasPoint =
    Number.isFinite(Number(latitude)) && Number.isFinite(Number(longitude));
  if (!hasPoint) {
    return (
      <div className="rounded-3xl border border-red-100 bg-gradient-to-br from-red-50 to-white px-5 py-6">
        <div className="flex items-center gap-3">
          <div className="flex h-11 w-11 items-center justify-center rounded-2xl bg-white text-[#E83030] shadow-sm">
            <MapPin className="h-5 w-5" />
          </div>
          <div>
            <div className="text-sm font-bold text-gray-900">Lokasi tawaran</div>
            <div className="text-xs font-medium text-gray-500">
              Lokasi produk belum ditentukan.
            </div>
          </div>
        </div>
      </div>
    );
  }

  const point = [Number(latitude), Number(longitude)];
  const radiusNumber = Number(radiusKm) || 0;

  return (
    <div className="relative z-0 overflow-hidden rounded-3xl border border-red-100 bg-white shadow-[0_18px_45px_rgba(15,23,42,0.08)]">
      <div className="flex items-start justify-between gap-4 border-b border-red-50 px-5 py-4">
        <div className="flex items-start gap-3">
          <div className="flex h-11 w-11 shrink-0 items-center justify-center rounded-2xl bg-red-50 text-[#E83030]">
            <MapPin className="h-5 w-5" />
          </div>
          <div>
            <div className="text-sm font-bold text-gray-950">Lokasi Tawaran</div>
            <div className="mt-0.5 text-xs font-medium text-gray-500">
              Pembeli hanya melihat area radius, bukan alamat lengkap.
            </div>
          </div>
        </div>
        <div className="hidden items-center gap-1.5 rounded-full bg-red-50 px-3 py-1.5 text-xs font-bold text-[#E83030] sm:flex">
          <Radar className="h-3.5 w-3.5" />
          {radiusNumber} km
        </div>
      </div>

      <div className="relative z-0">
        <MapContainer
          center={point}
          zoom={zoomForRadius(radiusNumber)}
          scrollWheelZoom={false}
          zoomControl={false}
          dragging
          className="jualin-leaflet-map h-64 w-full"
        >
          <TileLayer
            attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
            url="https://tile.openstreetmap.org/{z}/{x}/{y}.png"
          />
          <Circle
            center={point}
            radius={radiusNumber * 1000}
            pathOptions={{
              color: "#E83030",
              fillColor: "#E83030",
              fillOpacity: 0.13,
              weight: 2,
            }}
          />
          <Marker position={point} icon={markerIcon} />
        </MapContainer>

        <div className="pointer-events-none absolute inset-x-4 bottom-4 rounded-2xl border border-white/75 bg-white/95 p-3 shadow-[0_12px_32px_rgba(15,23,42,0.14)] backdrop-blur">
          <div className="flex items-center justify-between gap-3">
            <div className="min-w-0">
              <div className="truncate text-sm font-bold text-gray-950">{label}</div>
              <div className="mt-0.5 text-xs font-semibold text-[#E83030]">
                Radius penawaran {radiusNumber} km
              </div>
            </div>
            <div className="flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-red-50 text-[#E83030]">
              <Navigation className="h-4 w-4" />
            </div>
          </div>
        </div>
      </div>

      <div className="flex flex-col gap-3 px-5 py-4 sm:flex-row sm:items-center sm:justify-between">
        <div className="text-xs font-medium leading-relaxed text-gray-500">
          Gunakan pengecekan radius untuk melihat apakah lokasimu masih masuk area jangkauan seller.
        </div>
        <button
          type="button"
          onClick={() => {
            if (!navigator.geolocation) {
              setDistanceStatus("Browser tidak mendukung akses lokasi.");
              return;
            }

            setCheckingDistance(true);
            navigator.geolocation.getCurrentPosition(
              (position) => {
                const distance = haversineKm(
                  position.coords.latitude,
                  position.coords.longitude,
                  point[0],
                  point[1]
                );
                setDistanceStatus(
                  distance <= radiusNumber
                    ? `Kamu berada dalam radius seller (${distance.toFixed(1)} km).`
                    : `Kamu berada di luar radius seller (${distance.toFixed(1)} km).`
                );
                setCheckingDistance(false);
              },
              () => {
                setDistanceStatus(
                  "Lokasi tidak diizinkan. Detail produk tetap bisa dilihat."
                );
                setCheckingDistance(false);
              },
              { enableHighAccuracy: false, timeout: 10000 }
            );
          }}
          className="inline-flex shrink-0 items-center justify-center gap-2 rounded-full bg-[#E83030] px-4 py-2 text-xs font-bold text-white shadow-[0_10px_24px_rgba(232,48,48,0.22)] transition hover:bg-red-600 disabled:cursor-not-allowed disabled:opacity-70"
          disabled={checkingDistance}
        >
          <LocateFixed className="h-4 w-4" />
          {checkingDistance ? "Mengecek..." : "Cek radius dari lokasiku"}
        </button>
      </div>

      <div className="px-5 pb-4">
        {distanceStatus && (
          <div className="rounded-2xl bg-gray-50 px-4 py-3 text-xs font-semibold text-gray-700">
            {distanceStatus}
          </div>
        )}
      </div>
    </div>
  );
}

function haversineKm(lat1, lon1, lat2, lon2) {
  const earthRadiusKm = 6371;
  const toRadians = (degree) => (degree * Math.PI) / 180;
  const dLat = toRadians(lat2 - lat1);
  const dLon = toRadians(lon2 - lon1);
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRadians(lat1)) *
      Math.cos(toRadians(lat2)) *
      Math.sin(dLon / 2) ** 2;
  return earthRadiusKm * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

function zoomForRadius(radiusKm) {
  if (radiusKm <= 1) return 14;
  if (radiusKm <= 3) return 13;
  if (radiusKm <= 5) return 12;
  if (radiusKm <= 10) return 11;
  if (radiusKm <= 15) return 10;
  return 9;
}
