import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/app/auth_route_guard.dart';

void main() {
  group('AuthRouteGuard', () {
    test('unauthenticated users are redirected from protected routes', () {
      expect(
        AuthRouteGuard.resolve(
          isAuthenticated: false,
          location: '/wallet',
        ),
        '/auth?redirect=%2Fwallet',
      );
    });

    test('query parameters are preserved when protecting a deep link', () {
      final result = AuthRouteGuard.resolve(
        isAuthenticated: false,
        location: '/transactions?type=expense&page=2',
      );

      expect(result, contains('/auth?redirect='));
      expect(result, contains('%2Ftransactions%3Ftype%3Dexpense%26page%3D2'));
    });

    test('unauthenticated users can access public routes', () {
      expect(
        AuthRouteGuard.resolve(
          isAuthenticated: false,
          location: '/auth',
        ),
        isNull,
      );
      expect(
        AuthRouteGuard.resolve(
          isAuthenticated: false,
          location: '/onboarding',
        ),
        isNull,
      );
    });

    test('authenticated users are sent home from auth', () {
      expect(
        AuthRouteGuard.resolve(
          isAuthenticated: true,
          location: '/auth',
        ),
        '/',
      );
    });

    test('authenticated users return to a safe deep link', () {
      expect(
        AuthRouteGuard.resolve(
          isAuthenticated: true,
          location: '/auth?redirect=%2Fwallet%2F123',
        ),
        '/wallet/123',
      );
    });

    test('external redirects are never accepted', () {
      expect(
        AuthRouteGuard.resolve(
          isAuthenticated: true,
          location: '/auth?redirect=https%3A%2F%2Fevil.example',
        ),
        '/',
      );
    });
  });
}
