import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'config/app_environment.dart';

/// Maintained configuration adapter; values come from --dart-define-from-file.
/// The supplied credentials register a web app, not Android/iOS/Windows apps.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (!kIsWeb) {
      throw UnsupportedError(
        'Register this native app with FlutterFire before enabling Firebase.',
      );
    }
    return forWeb(AppEnvironment.current);
  }

  static FirebaseOptions forWeb(AppEnvironment environment) {
    environment.validate();
    return FirebaseOptions(
      apiKey: environment.apiKey,
      appId: environment.appId,
      messagingSenderId: environment.messagingSenderId,
      projectId: environment.projectId,
      authDomain: environment.authDomain,
      storageBucket: environment.storageBucket.isEmpty
          ? null
          : environment.storageBucket,
    );
  }
}
