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
 * Get first product image URL with fallback (for single image display)
 * @param {string|array|null} productImage - Product image path(s)
 * @param {string} fallback - Fallback image path
 * @returns {string} Full image URL or fallback
 */
export const getFirstProductImageUrl = (productImage, fallback = '/placeholder.svg') => {
  if (!productImage) return fallback;
  
  // Handle array of images - return first one
  if (Array.isArray(productImage)) {
    const firstImage = productImage.find(img => img);
    return firstImage ? getImageUrl(firstImage) : fallback;
  }
  
  // Handle single image
  return getImageUrl(productImage);
};

/**
 * Get all product image URLs
 * @param {string|array|null} productImage - Product image path(s)
 * @returns {array} Array of full image URLs
 */
export const getProductImagesUrls = (productImage) => {
  if (!productImage) return [];
  
  // Handle array of images
  if (Array.isArray(productImage)) {
    return productImage.filter(img => img).map(img => getImageUrl(img));
  }
  
  // Handle single image - return as array
  return [getImageUrl(productImage)];
};

/**
 * Get product image URL with fallback (BACKWARD COMPATIBLE - returns single image)
 * @param {string|array|null} productImage - Product image path(s)
 * @param {string} fallback - Fallback image path
 * @returns {string} Full image URL or fallback
 */
export const getProductImageUrl = (productImage, fallback = '/placeholder.svg') => {
  return getFirstProductImageUrl(productImage, fallback);
};

export default {
  getImageUrl,
  getProfilePictureUrl,
  getProductImageUrl,
};
