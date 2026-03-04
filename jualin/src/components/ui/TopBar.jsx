"use client";
import { useState, useEffect } from "react";
import { TOP_BAR_MESSAGES } from "@/constants/messages";
import { CAROUSEL_CONFIG } from "@/constants/animations";

const SLIDE_INTERVAL = 3000;
const ANIMATION_DURATION = CAROUSEL_CONFIG.ANIMATION_DURATION;

function TopBar() {
  const [currentIndex, setCurrentIndex] = useState(0);
  const [isSlidingOut, setIsSlidingOut] = useState(false);
  const [justChanged, setJustChanged] = useState(false);

  useEffect(() => {
    const interval = setInterval(() => {
      setIsSlidingOut(true);
      setJustChanged(false);

      setTimeout(() => {
        setCurrentIndex((prevIndex) => (prevIndex + 1) % TOP_BAR_MESSAGES.length);
        setJustChanged(true);
        setIsSlidingOut(false);
      }, ANIMATION_DURATION);
    }, SLIDE_INTERVAL);

    return () => clearInterval(interval);
  }, []);

  return (
    <div className="w-full bg-black text-white text-xs py-2 px-4 text-center overflow-hidden relative h-8">
      <div
        className={`absolute inset-0 flex items-center justify-center transition-all duration-300 ease-in-out ${
          isSlidingOut
            ? "-translate-y-full opacity-0"
            : justChanged
            ? "animate-slide-in-from-bottom translate-y-0 opacity-100"
            : "translate-y-0 opacity-100"
        }`}
        key={currentIndex}
      >
        Most News: {TOP_BAR_MESSAGES[currentIndex]}
      </div>
    </div>
  );
}

export default TopBar;
