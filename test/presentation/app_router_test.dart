import 'package:flutter_test/flutter_test.dart';
import 'package:nutrease_flutter/presentation/navigation/app_router.dart';
import 'package:nutrease_flutter/presentation/navigation/routes.dart';

void main() {
  group('resolveRedirect', () {
    test('redirects an unauthenticated user away from a protected route', () {
      expect(
        resolveRedirect(isLoggedIn: false, location: Routes.patientHome),
        Routes.login,
      );
    });

    test('keeps an unauthenticated user on a public route', () {
      expect(
        resolveRedirect(isLoggedIn: false, location: Routes.login),
        isNull,
      );
    });

    test('routes an authenticated user on a public route through splash', () {
      // The redirect can't resolve the role synchronously, so it hands off to
      // splash, which re-resolves and forwards to the role-specific home.
      expect(
        resolveRedirect(isLoggedIn: true, location: Routes.login),
        Routes.splash,
      );
      expect(
        resolveRedirect(isLoggedIn: true, location: Routes.register),
        Routes.splash,
      );
    });

    test('never redirects the splash route', () {
      expect(
        resolveRedirect(isLoggedIn: false, location: Routes.splash),
        isNull,
      );
      expect(
        resolveRedirect(isLoggedIn: true, location: Routes.splash),
        isNull,
      );
    });

    test('never redirects the reset-password route', () {
      // Reachable while logged out, and not bounced when the transient recovery
      // session appears mid-flow.
      expect(
        resolveRedirect(isLoggedIn: false, location: Routes.resetPassword),
        isNull,
      );
      expect(
        resolveRedirect(isLoggedIn: true, location: Routes.resetPassword),
        isNull,
      );
    });
  });
}
