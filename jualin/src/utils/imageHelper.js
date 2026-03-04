/**
 * Image Helper Utilities
 * Handles image URL construction and validation
 */

/**
 * Get full image URL from relative path
 * @param {string|null} imagePath - Relative image path from API
 * @returns {string} Full image URL or empty string
 */
export const getImageUrl = (imagePath) => {
  if (!imagePath) return '';

  if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
    return imagePath;
  }
  const baseUrl = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';
  const cleanBaseUrl = baseUrl.replace(/\/$/, '');
  const cleanImagePath = imagePath.replace(/^\//, '');
  return `${cleanBaseUrl}/storage/${cleanImagePath}`;
};

/**
 * Get profile picture URL with fallback
 * @param {string|null} profilePicture - Profile picture path
 * @param {string} fallback - Fallback image path
 * @returns {string} Full image URL
 */
export const getProfilePictureUrl = (profilePicture, fallback = '/ProfilePhoto.png') => {
  if (!profilePicture) return fallback;
  return getImageUrl(profilePicture);
};

/**
 * Get product image URL with fallback
 * @param {string|null} productImage - Product image path
 * @param {string} fallback - Fallback image path
 * @returns {string} Full image URL
 */
export const getProductImageUrl = (productImage, fallback = '/placeholder.svg') => {
  if (!productImage) return fallback;
  return getImageUrl(productImage);
};

export default {
  getImageUrl,
  getProfilePictureUrl,
  getProductImageUrl,
};
