import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('stores and restores remembered email', () async {
    final service = AuthService();

    await service.saveRememberedLogin(' User@Example.COM ', true);
    final remembered = await service.getRememberedLogin();

    expect(remembered['rememberMe'], isTrue);
    expect(remembered['email'], 'user@example.com');
  });

  test('session cleanup preserves remembered email', () async {
    final service = AuthService();

    await service.saveRememberedLogin('user@example.com', true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AuthService.tokenKey, 'token');

    await service.clearLocalSession();
    final remembered = await service.getRememberedLogin();

    expect(prefs.getString(AuthService.tokenKey), isNull);
    expect(remembered['rememberMe'], isTrue);
    expect(remembered['email'], 'user@example.com');
  });

  test('disabling remember me removes stored email', () async {
    final service = AuthService();

    await service.saveRememberedLogin('user@example.com', true);
    await service.saveRememberedLogin('user@example.com', false);
    final remembered = await service.getRememberedLogin();

    expect(remembered['rememberMe'], isFalse);
    expect(remembered['email'], isEmpty);
  });
}
