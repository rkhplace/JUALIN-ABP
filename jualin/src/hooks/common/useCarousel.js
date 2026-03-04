import { useState, useEffect, useCallback } from 'react';
import { CAROUSEL_CONFIG } from '@/constants/animations';

/**
 * Carousel hook for managing carousel state and auto-play
 * @param {Object} options - Carousel options
 * @param {number} options.itemCount - Number of carousel items
 * @param {boolean} options.autoPlay - Enable auto-play (default: true)
 * @param {number} options.interval - Auto-play interval in ms
 * @param {number} options.animationDuration - Animation duration in ms
 */
export const useCarousel = (options) => {
  const {
    itemCount,
    autoPlay = true,
    interval = CAROUSEL_CONFIG.AUTO_PLAY_INTERVAL,
    animationDuration = CAROUSEL_CONFIG.ANIMATION_DURATION,
  } = options;

  const [activeIndex, setActiveIndex] = useState(0);
  const [isAnimating, setIsAnimating] = useState(false);
  const [isPaused, setIsPaused] = useState(false);

  const goToNext = useCallback(() => {
    if (isAnimating) return;
    setIsAnimating(true);
    setActiveIndex((prev) => (prev === itemCount - 1 ? 0 : prev + 1));
    setTimeout(() => setIsAnimating(false), animationDuration);
  }, [isAnimating, itemCount, animationDuration]);

  const goToPrev = useCallback(() => {
    if (isAnimating) return;
    setIsAnimating(true);
    setActiveIndex((prev) => (prev === 0 ? itemCount - 1 : prev - 1));
    setTimeout(() => setIsAnimating(false), animationDuration);
  }, [isAnimating, itemCount, animationDuration]);

  const goToIndex = useCallback(
    (index) => {
      if (isAnimating || index < 0 || index >= itemCount) return;
      setIsAnimating(true);
      setActiveIndex(index);
      setTimeout(() => setIsAnimating(false), animationDuration);
    },
    [isAnimating, itemCount, animationDuration]
  );

  const pause = useCallback(() => setIsPaused(true), []);
  const resume = useCallback(() => setIsPaused(false), []);

  useEffect(() => {
    if (!autoPlay || isPaused || isAnimating) return;

    const timer = setInterval(() => {
      goToNext();
    }, interval);

    return () => clearInterval(timer);
  }, [autoPlay, isPaused, isAnimating, interval, goToNext]);

  return {
    activeIndex,
    isAnimating,
    isPaused,
    goToNext,
    goToPrev,
    goToIndex,
    pause,
    resume,
  };
};
