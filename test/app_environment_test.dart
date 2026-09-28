import 'package:flutter_test/flutter_test.dart';
import 'package:kallisto_design_system/config/app_environment.dart';
import 'package:kallisto_design_system/firebase_options.dart';

AppEnvironment config({
  String url = 'https://api.example.com',
  String key = 'test-public-key',
  String appId = '1:123456:web:abc123',
  String bucket = '',
}) => AppEnvironment(
  backendUrl: url,
  apiKey: key,
  authDomain: 'example.firebaseapp.com',
  projectId: 'example',
  appId: appId,
  messagingSenderId: '123456',
  storageBucket: bucket,
);

void main() {
  test('maps supplied web settings without guessing a storage bucket', () {
    final options = DefaultFirebaseOptions.forWeb(config());
    expect(options.projectId, 'example');
    expect(options.appId, '1:123456:web:abc123');
    expect(options.storageBucket, isNull);
    expect(
      DefaultFirebaseOptions.forWeb(
        config(bucket: 'actual-bucket'),
      ).storageBucket,
      'actual-bucket',
    );
  });

  test('allows HTTP only for local backend development', () {
    for (final host in ['localhost', '127.0.0.1', '[::1]']) {
      expect(
        () => config(url: 'http://$host:4000').validate(),
        returnsNormally,
      );
    }
    for (final url in [
      'http://api.example.com',
      '/api',
      'https://user:password@example.com',
      'https://example.com?token=secret',
      'https://example.com#fragment',
    ]) {
      expect(() => config(url: url).validate(), throwsStateError);
    }
  });

  test('rejects missing settings and native or inconsistent app IDs', () {
    expect(() => config(key: ' ').validate(), throwsStateError);
    expect(
      () => config(appId: '1:123456:android:abc').validate(),
      throwsStateError,
    );
    expect(
      () => config(appId: '1:999999:web:abc').validate(),
      throwsStateError,
    );
  });

  test('does not silently use a web registration on a native platform', () {
    expect(
      () => DefaultFirebaseOptions.currentPlatform,
      throwsUnsupportedError,
    );
  });
}
