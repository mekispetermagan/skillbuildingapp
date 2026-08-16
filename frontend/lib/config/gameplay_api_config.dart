class GameplayApiConfig {
  final Uri baseUri;
  final String apiKey;

  const GameplayApiConfig({required this.baseUri, required this.apiKey});

  factory GameplayApiConfig.fromEnvironment() {
    const baseUrl = String.fromEnvironment(
      'GAMEPLAY_API_BASE_URL',
      defaultValue: 'http://10.0.2.2:8000',
    );
    const apiKey = String.fromEnvironment(
      'GAMEPLAY_API_KEY',
      defaultValue: 'dev-key',
    );
    return GameplayApiConfig(baseUri: Uri.parse(baseUrl), apiKey: apiKey);
  }

  Uri endpoint(String path) {
    final normalizedBase = baseUri.toString().replaceFirst(RegExp(r'/$'), '');
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$normalizedBase$normalizedPath');
  }
}
