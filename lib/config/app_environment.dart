/// Client-visible compile-time settings. Never load the server environment here.
class AppEnvironment {
  const AppEnvironment({
    required this.backendUrl,
    required this.apiKey,
    required this.authDomain,
    required this.projectId,
    required this.appId,
    required this.messagingSenderId,
    this.storageBucket = '',
  });

  static const current = AppEnvironment(
    backendUrl: String.fromEnvironment('BACKEND_URL'),
    apiKey: String.fromEnvironment('FIREBASE_API_KEY'),
    authDomain: String.fromEnvironment('FIREBASE_AUTH_DOMAIN'),
    projectId: String.fromEnvironment('FIREBASE_PROJECT_ID'),
    appId: String.fromEnvironment('FIREBASE_APP_ID'),
    messagingSenderId: String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID'),
    storageBucket: String.fromEnvironment('FIREBASE_STORAGE_BUCKET'),
  );

  final String backendUrl;
  final String apiKey;
  final String authDomain;
  final String projectId;
  final String appId;
  final String messagingSenderId;
  final String storageBucket;

  void validate() {
    final fields = {
      'BACKEND_URL': backendUrl,
      'FIREBASE_API_KEY': apiKey,
      'FIREBASE_AUTH_DOMAIN': authDomain,
      'FIREBASE_PROJECT_ID': projectId,
      'FIREBASE_APP_ID': appId,
      'FIREBASE_MESSAGING_SENDER_ID': messagingSenderId,
    };
    final missing = fields.entries
        .where((entry) => entry.value.trim().isEmpty)
        .map((entry) => entry.key);
    if (missing.isNotEmpty) {
      throw StateError('Missing client settings: ${missing.join(', ')}');
    }
    final uri = Uri.tryParse(backendUrl);
    final loopback =
        uri != null &&
        const ['localhost', '127.0.0.1', '::1'].contains(uri.host);
    if (uri == null ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        (uri.scheme != 'https' && !(uri.scheme == 'http' && loopback))) {
      throw StateError('BACKEND_URL requires HTTPS, or HTTP on loopback.');
    }
    final id = RegExp(r'^1:(\d+):web:[a-zA-Z0-9]+$').firstMatch(appId);
    if (id == null || id.group(1) != messagingSenderId) {
      throw StateError(
        'Firebase web app ID and messaging sender do not match.',
      );
    }
  }
}
