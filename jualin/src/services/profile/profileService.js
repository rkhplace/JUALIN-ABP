import { fetcher } from '@/lib/fetcher';

export const profileService = {
  async fetchCurrentProfile() {
    const response = await fetcher.get('/api/v1/me');
    return response?.data || response;
  },

  async updateProfile(profileData, imageFile = null) {
    const storedUser = typeof window !== 'undefined'
      ? JSON.parse(localStorage.getItem('user') || 'null')
      : null;
    const userId = storedUser?.id;
    if (!userId) throw new Error('User ID not found. Please login again.');

    let response;
    if (imageFile) {
      const formData = new FormData();
      formData.append('username', profileData.username);
      formData.append('email', profileData.email);
      formData.append('gender', profileData.gender || 'male');
      if (profileData.birthday) {
        formData.append('birthday', profileData.birthday);
      }
      formData.append('region', profileData.region || '');
      formData.append('city', profileData.city || '');
      formData.append('bio', profileData.bio || '');
      formData.append('profile_picture', imageFile);

      response = await fetcher.upload(`/api/v1/users/${userId}/update?_method=PATCH`, formData);
    } else {
      response = await fetcher.post(`/api/v1/users/${userId}/update?_method=PATCH`, {
        username: profileData.username,
        email: profileData.email,
        gender: profileData.gender || 'male',
        birthday: profileData.birthday || null,
        region: profileData.region || '',
        city: profileData.city || '',
        bio: profileData.bio || '',
      });
    }
    return response ?? {};
  },
};

export default profileService;