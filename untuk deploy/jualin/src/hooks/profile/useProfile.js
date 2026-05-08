import { useAsync } from '../common/useAsync';
import { profileService } from '@/services';

/**
 * Hook to fetch current user profile
 * @param {boolean} immediate - Fetch immediately on mount (default: true)
 * @returns {Object} { profile, isLoading, error, refetch, reset }
 */
export const useProfile = (immediate = true) => {
  const {
    data,
    isLoading,
    error,
    execute,
    reset
  } = useAsync(
    () => profileService.fetchCurrentProfile(),
    { immediate }
  );

  return {
    profile: data,
    isLoading,
    error,
    refetch: execute,
    reset
  };
};

export default useProfile;
