"use client";
import React, { useEffect, useState } from "react";

function BannerSection({ banners, isLoading = false }) {
  const [active, setActive] = useState(0);
  const [animating, setAnimating] = useState(false);
  const [paused, setPaused] = useState(false);
  const [dragStartX, setDragStartX] = useState(null);
  const [dragDeltaX, setDragDeltaX] = useState(0);

  const handlePrev = () => {
    if (animating) return;
    setAnimating(true);
    setActive((prev) => (prev === 0 ? banners.length - 1 : prev - 1));
    setTimeout(() => setAnimating(false), 300);
  };

  const handleNext = () => {
    if (animating) return;
    setAnimating(true);
    setActive((prev) => (prev === banners.length - 1 ? 0 : prev + 1));
    setTimeout(() => setAnimating(false), 300);
  };

  const handleDragStart = (event) => {
    const point = event.touches?.[0] || event;
    event.currentTarget?.setPointerCapture?.(event.pointerId);
    setPaused(true);
    setDragStartX(point.clientX);
    setDragDeltaX(0);
  };

  const handleDragMove = (event) => {
    if (dragStartX === null) return;
    const point = event.touches?.[0] || event;
    setDragDeltaX(point.clientX - dragStartX);
  };

  const handleDragEnd = () => {
    if (dragStartX === null) return;

    const threshold = 40;
    if (dragDeltaX <= -threshold) {
      handleNext();
    } else if (dragDeltaX >= threshold) {
      handlePrev();
    }

    setDragStartX(null);
    setDragDeltaX(0);
    setPaused(false);
  };

  useEffect(() => {
    if (paused) return;
    const id = setInterval(() => {
      handleNext();
    }, 5000);
    return () => clearInterval(id);
  }, [paused, animating, banners.length]);

  const onMouseMove = null;

  if (isLoading) {
    return (
      <section className="w-full mt-3 sm:mt-8 mb-5 sm:mb-6 px-2 sm:px-4">
        <div className="w-full max-w-7xl mx-auto overflow-hidden relative h-[210px] sm:h-[300px] lg:h-[420px] bg-gray-200 rounded-xl sm:rounded-2xl animate-pulse flex items-center justify-start">
          <div className="relative z-20 text-white px-4 sm:px-10 py-8 max-w-xl text-left">
            <div className="h-10 sm:h-14 bg-gray-300 rounded-lg w-64 mb-4 animate-pulse"></div>
            <div className="h-6 bg-gray-300 rounded w-80 mb-2 animate-pulse"></div>
            <div className="h-6 bg-gray-300 rounded w-72 animate-pulse"></div>
          </div>
          <div className="absolute bottom-6 left-1/2 -translate-x-1/2 flex gap-2 z-30">
            {[1, 2, 3].map((idx) => (
              <span
                key={idx}
                className="w-3 h-3 rounded-full bg-gray-400 animate-pulse"
              />
            ))}
          </div>
        </div>
      </section>
    );
  }

  return (
    <section className="w-full mt-3 sm:mt-8 mb-5 sm:mb-6 px-2 sm:px-4">
      <div
        className="w-full max-w-7xl mx-auto overflow-hidden relative h-[210px] sm:h-[300px] lg:h-[420px] flex items-center justify-start bg-gray-100 rounded-xl sm:rounded-2xl cursor-grab active:cursor-grabbing select-none touch-pan-y"
        onMouseEnter={() => setPaused(true)}
        onMouseLeave={() => setPaused(false)}
        onPointerDown={handleDragStart}
        onPointerMove={handleDragMove}
        onPointerUp={handleDragEnd}
        onPointerCancel={handleDragEnd}
      >
        <div
          className="absolute inset-0 h-full w-full flex"
          style={{
            transform: `translateX(-${active * 100}%)`,
            transition: "transform 500ms ease-in-out",
          }}
        >
          {banners.map((banner, idx) => (
            <div key={idx} className="min-w-full h-full relative">
              <img
                src={banner.src}
                alt={banner.alt}
                className={`absolute inset-0 w-full h-full object-cover object-left sm:object-center rounded-xl sm:rounded-2xl ${idx === active ? "" : ""}`}
                style={idx === active ? undefined : { transform: "scale(0.995)" }}
              />
            </div>
          ))}
        </div>
        {/* Carousel indicator */}
        <div className="absolute bottom-4 sm:bottom-6 left-1/2 -translate-x-1/2 flex gap-2 z-30">
          {banners.map((_, idx) => (
            <span
              key={idx}
              className={`h-2.5 w-2.5 sm:h-3 sm:w-3 rounded-full bg-white transition-opacity ${active === idx ? "opacity-80" : "opacity-40"
                }`}
              onClick={() => !animating && setActive(idx)}
              style={{ cursor: "pointer" }}
            />
          ))}
        </div>
      </div>
    </section>
  );
}

export default BannerSection;
