"use client";

import React, { useMemo, useState } from "react";
import { Circle, MapContainer, Marker, TileLayer } from "react-leaflet";
import L from "leaflet";

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
        html: '<div class="h-9 w-9 -translate-x-1/2 -translate-y-1/2 rounded-full bg-[#E83030] text-white shadow-lg ring-4 ring-white flex items-center justify-center font-bold">*</div>',
        iconSize: [36, 36],
        iconAnchor: [18, 18],
      }),
    []
  );

  const hasPoint =
    Number.isFinite(Number(latitude)) && Number.isFinite(Number(longitude));
  if (!hasPoint) {
    return (
      <div className="rounded-2xl border border-gray-100 bg-gray-50 px-5 py-6 text-sm text-gray-500">
        Lokasi produk belum ditentukan.
      </div>
    );
  }

  const point = [Number(latitude), Number(longitude)];
  const radiusNumber = Number(radiusKm) || 0;

  return (
    <div className="overflow-hidden rounded-2xl border border-red-100 bg-white shadow-sm">
      <MapContainer center={point} zoom={12} scrollWheelZoom className="h-72 w-full">
        <TileLayer
          attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
          url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
        />
        <Circle
          center={point}
          radius={radiusNumber * 1000}
          pathOptions={{
            color: "#E83030",
            fillColor: "#E83030",
            fillOpacity: 0.16,
            weight: 2,
          }}
        />
        <Marker position={point} icon={markerIcon} />
      </MapContainer>
      <div className="px-4 py-3">
        <div className="text-sm font-semibold text-gray-900">{label}</div>
        <div className="mt-1 text-xs font-medium text-[#E83030]">
          Radius jangkauan seller: {radiusNumber} km
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
          className="mt-3 rounded-full border border-red-200 px-3 py-1.5 text-xs font-semibold text-[#E83030] transition hover:bg-red-50"
        >
          {checkingDistance ? "Mengecek..." : "Cek radius dari lokasiku"}
        </button>
        {distanceStatus && (
          <div className="mt-2 text-xs font-medium text-gray-600">
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
