class ApiConfig {
  const ApiConfig._();

  static const baseUrl = String.fromEnvironment(
    'NEXORA_API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/api/v1',
  );

  static Uri endpoint(String path, [Map<String, String>? query]) {
    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final normalizedPath = path.startsWith('/') ? path.substring(1) : path;
    return Uri.parse('$normalizedBase/$normalizedPath').replace(
      queryParameters: query?.isEmpty == true ? null : query,
    );
  }
}
