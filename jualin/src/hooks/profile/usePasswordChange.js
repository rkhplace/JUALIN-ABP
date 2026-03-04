import { useState } from 'react';
import { profileService } from '@/services';

/**
 * Hook to manage password change form and submission
 * @returns {Object} { form, errors, isLoading, updateField, submit, reset }
 */
export const usePasswordChange = () => {
  const [form, setForm] = useState({
    currentPassword: '',
    newPassword: '',
    confirmPassword: ''
  });
  const [errors, setErrors] = useState({});
  const [isLoading, setIsLoading] = useState(false);

  /**
   * Update a form field
   * @param {string} key - Field name
   * @param {string} value - Field value
   */
  const updateField = (key, value) => {
    setForm(prev => ({ ...prev, [key]: value }));
    if (errors[key]) {
      setErrors(prev => {
        const newErrors = { ...prev };
        delete newErrors[key];
        return newErrors;
      });
    }
  };

  /**
   * Validate password form
   * @returns {boolean} True if valid
   */
  const validate = () => {
    const e = {};
    if (!form.currentPassword) e.currentPassword = 'Current password required';
    if (!form.newPassword || form.newPassword.length < 6) {
      e.newPassword = 'Password must be at least 6 characters';
    }
    if (form.newPassword !== form.confirmPassword) {
      e.confirmPassword = 'Passwords do not match';
    }
    setErrors(e);
    return Object.keys(e).length === 0;
  };

  /**
   * Submit password change
   * @returns {Promise<Object>} { success, message }
   */
  const submit = async () => {
    if (!validate()) return { success: false };

    setIsLoading(true);
    try {
      const result = await profileService.changePassword(
        form.currentPassword,
        form.newPassword
      );

      if (result?.success) {
        setForm({ currentPassword: '', newPassword: '', confirmPassword: '' });
        return { success: true, message: result.message || 'Password changed successfully' };
      } else {
        return { success: false, message: result?.message || 'Failed to change password' };
      }
    } catch (err) {
      return { success: false, message: err.message || 'Failed to change password' };
    } finally {
      setIsLoading(false);
    }
  };

  /**
   * Reset form to initial state
   */
  const reset = () => {
    setForm({ currentPassword: '', newPassword: '', confirmPassword: '' });
    setErrors({});
  };

  return {
    form,
    errors,
    isLoading,
    updateField,
    submit,
    reset,
  };
};

export default usePasswordChange;
