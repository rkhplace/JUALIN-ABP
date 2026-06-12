import { authService } from '@/services/auth/authService';

describe('Remember Me storage', () => {
  beforeEach(() => {
    localStorage.clear();
  });

  test('stores and restores normalized email', () => {
    authService.saveRememberedLogin(' User@Example.COM ', true);

    expect(authService.getRememberedLogin()).toEqual({
      rememberMe: true,
      email: 'user@example.com',
    });
  });

  test('does not expose remembered email when flag is disabled', () => {
    localStorage.setItem('remembered_email', 'user@example.com');

    expect(authService.getRememberedLogin()).toEqual({
      rememberMe: false,
      email: '',
    });
  });

  test('removes remembered data when disabled', () => {
    authService.saveRememberedLogin('user@example.com', true);
    authService.saveRememberedLogin('user@example.com', false);

    expect(localStorage.getItem('remember_me')).toBeNull();
    expect(localStorage.getItem('remembered_email')).toBeNull();
  });
});
