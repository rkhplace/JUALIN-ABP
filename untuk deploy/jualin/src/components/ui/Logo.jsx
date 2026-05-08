import React from "react";
import Image from "next/image";
import Link from "next/link";

const Logo = ({ size = "xl", className = "", href = "/dashboard" }) => {
  const sizeClasses = {
    small: "w-12 h-12",
    medium: "w-20 h-20",
    large: "w-28 h-28",
    xl: "w-36 h-36",
  };

  return (
    <div className={`flex items-center gap-3 ${className}`}>
      <Link
        href={href}
        aria-label="Go to Dashboard"
        className="relative cursor-pointer hover:opacity-80 transition-opacity duration-200 hover:scale-105 transform"
      >
        <Image
          src="/Logo.png"
          alt="Jualin"
          width={parseInt(sizeClasses[size].split("w-")[1]) * 4}
          height={parseInt(sizeClasses[size].split("h-")[1]) * 4}
          className="object-contain"
          priority
        />
      </Link>
    </div>
  );
};

export default Logo;
