/// Keeps post-auth navigation inside the ManaLoom router.
///
/// External URLs, the root route and auth routes are intentionally rejected so
/// a crafted `redirect` query parameter cannot turn login into an open
/// redirect or create an authentication loop.
String? normalizePostAuthRedirect(String? redirectPath) {
  final trimmed = redirectPath?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }

  final uri = Uri.tryParse(trimmed);
  if (uri == null || uri.hasScheme || uri.hasAuthority) {
    return null;
  }

  final path = uri.path;
  if (!path.startsWith('/') ||
      path == '/' ||
      path == '/login' ||
      path == '/register') {
    return null;
  }

  return uri.toString();
}

/// Builds an auth route while preserving a validated internal destination.
String buildAuthLocation(String authPath, String? redirectPath) {
  final redirect = normalizePostAuthRedirect(redirectPath);
  return Uri(
    path: authPath,
    queryParameters: redirect == null ? null : {'redirect': redirect},
  ).toString();
}
