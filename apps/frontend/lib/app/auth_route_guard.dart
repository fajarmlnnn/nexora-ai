class AuthRouteGuard {
  const AuthRouteGuard._();

  static const publicRoutes = <String>{
    '/splash',
    '/onboarding',
    '/auth',
  };

  static String? resolve({
    required bool isAuthenticated,
    required String location,
  }) {
    final path = Uri.tryParse(location)?.path ?? location;
    final isPublic = publicRoutes.contains(path);

    if (!isAuthenticated && !isPublic) {
      final encoded = Uri.encodeComponent(location);
      return '/auth?redirect=$encoded';
    }

    if (isAuthenticated && path == '/auth') {
      final uri = Uri.tryParse(location);
      final redirect = uri?.queryParameters['redirect'];
      if (redirect != null && redirect.startsWith('/')) {
        return redirect;
      }
      return '/';
    }

    return null;
  }
}
