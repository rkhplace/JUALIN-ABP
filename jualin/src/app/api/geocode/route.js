import { NextResponse } from "next/server";

export async function GET(request) {
  const { searchParams } = new URL(request.url);
  const query = searchParams.get("q")?.trim();

  if (!query || query.length < 3) {
    return NextResponse.json(
      { message: "Query lokasi minimal 3 karakter." },
      { status: 400 }
    );
  }

  const nominatimUrl = new URL("https://nominatim.openstreetmap.org/search");
  nominatimUrl.searchParams.set("q", query);
  nominatimUrl.searchParams.set("format", "jsonv2");
  nominatimUrl.searchParams.set("limit", "1");
  nominatimUrl.searchParams.set("countrycodes", "id");

  const response = await fetch(nominatimUrl, {
    headers: {
      "User-Agent": "JualinWeb/1.0 (student-demo)",
      Accept: "application/json",
    },
    next: { revalidate: 60 * 60 * 24 },
  });

  if (!response.ok) {
    return NextResponse.json(
      { message: "Gagal mencari lokasi." },
      { status: response.status }
    );
  }

  const results = await response.json();
  const item = Array.isArray(results) ? results[0] : null;
  const latitude = Number(item?.lat);
  const longitude = Number(item?.lon);

  if (!Number.isFinite(latitude) || !Number.isFinite(longitude)) {
    return NextResponse.json(
      { message: "Lokasi tidak ditemukan." },
      { status: 404 }
    );
  }

  return NextResponse.json({
    latitude,
    longitude,
    display_name: item.display_name || query,
  });
}
