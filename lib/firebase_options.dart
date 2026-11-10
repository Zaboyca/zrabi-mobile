// Replace via `flutterfire configure` with the real Firebase project.
// Placeholder values keep the app compiling until FCM is wired.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Web push is not configured for zrabi.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'Push notifications are only set up for Android and iOS.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyPlaceholderReplaceWithFlutterFire',
    appId: '1:000000000000:android:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'zrabi-placeholder',
    storageBucket: 'zrabi-placeholder.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyPlaceholderReplaceWithFlutterFire',
    appId: '1:000000000000:ios:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'zrabi-placeholder',
    storageBucket: 'zrabi-placeholder.appspot.com',
    iosBundleId: 'by.zrabi.zrabi',
  );
}
