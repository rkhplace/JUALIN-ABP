"use client";

import { useMemo, useState } from "react";
import { getProfilePictureUrl } from "@/utils/imageHelper";

export default function UserAvatar({
  name = "User",
  src,
  sizeClass = "w-9 h-9",
  className = "",
}) {
  const [failed, setFailed] = useState(false);
  const imageUrl = src ? getProfilePictureUrl(src, "") : "";
  const initial = useMemo(() => {
    const text = (name || "User").trim();
    return (text[0] || "U").toUpperCase();
  }, [name]);

  if (!imageUrl || failed) {
    return (
      <div
        className={`${sizeClass} ${className} inline-flex shrink-0 items-center justify-center rounded-full border-2 border-red-100 bg-red-50 text-red-600 shadow-sm`}
      >
        <span className="font-black leading-none">{initial}</span>
      </div>
    );
  }

  return (
    <img
      src={imageUrl}
      alt={name || "User"}
      className={`${sizeClass} ${className} shrink-0 rounded-full object-cover border-2 border-red-100 shadow-sm`}
      onError={() => setFailed(true)}
    />
  );
}
