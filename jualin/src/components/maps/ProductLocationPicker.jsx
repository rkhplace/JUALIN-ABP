"use client";

import React, { useEffect, useMemo } from "react";
import {
  Circle,
  MapContainer,
  Marker,
  TileLayer,
  useMap,
  useMapEvents,
} from "react-leaflet";
import L from "leaflet";

const DEFAULT_CENTER = [-6.9175, 107.6191];

function MapSync({ center, zoom }) {
  const map = useMap();

  useEffect(() => {
    map.invalidateSize();
    map.setView(center, zoom, { animate: false });
  }, [center, map, zoom]);

  return null;
}

function TapHandler({ onPick }) {
  useMapEvents({
    click(event) {
      onPick(event.latlng.lat, event.latlng.lng);
    },
  });
  return null;
}

export default function ProductLocationPicker({
  latitude,
  longitude,
  radiusKm = 10,
  onChange,
}) {
  const hasPoint =
    Number.isFinite(Number(latitude)) && Number.isFinite(Number(longitude));
  const point = useMemo(
    () => (hasPoint ? [Number(latitude), Number(longitude)] : DEFAULT_CENTER),
    [hasPoint, latitude, longitude]
  );
  const radiusMeters = Math.max(Number(radiusKm) || 0, 0) * 1000;
  const zoom = hasPoint ? zoomForRadius(Number(radiusKm) || 10) : 11;
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

  return (
    <div className="overflow-hidden rounded-2xl border border-red-100 bg-white">
      <MapContainer
        center={point}
        zoom={zoom}
        scrollWheelZoom
        className="jualin-leaflet-map h-72 w-full"
      >
        <MapSync center={point} zoom={zoom} />
        <TileLayer
          attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
          url="/map-tiles/{z}/{x}/{y}.png"
        />
        <TapHandler
          onPick={(lat, lng) =>
            onChange?.({
              latitude: lat,
              longitude: lng,
              location_label: "Area sekitar titik peta",
            })
          }
        />
        {hasPoint && (
          <>
            <Circle
              center={point}
              radius={radiusMeters}
              pathOptions={{
                color: "#E83030",
                fillColor: "#E83030",
                fillOpacity: 0.16,
                weight: 2,
              }}
            />
            <Marker position={point} icon={markerIcon} />
          </>
        )}
      </MapContainer>
      <div className="flex items-center justify-between gap-3 px-4 py-3 text-sm">
        <span className="font-medium text-gray-700">
          {hasPoint
            ? "Titik lokasi sudah dipilih"
            : "Klik peta untuk memilih titik lokasi"}
        </span>
        <span className="rounded-full bg-red-50 px-3 py-1 font-semibold text-[#E83030]">
          Radius {radiusKm || 0} km
        </span>
      </div>
    </div>
  );
}

function zoomForRadius(radiusKm) {
  if (radiusKm <= 1) return 14;
  if (radiusKm <= 3) return 13;
  if (radiusKm <= 5) return 12;
  if (radiusKm <= 10) return 11;
  if (radiusKm <= 15) return 10;
  return 9;
}
