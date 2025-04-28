import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAX8gMrySF5-ehSnDRGf6kFaBfTjImwjlU',
    appId: '1:258357895249:android:41f84bf1b8462adc411870',
    messagingSenderId: '258357895249',
    projectId: 'beautymarine-6355a',
    storageBucket: 'beautymarine-6355a.firebasestorage.app',
  );
}