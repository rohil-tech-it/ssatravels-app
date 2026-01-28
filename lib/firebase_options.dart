import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return const FirebaseOptions(
          apiKey: "AIzaSyD-WiIM0Ga4U1sAHstnFYuWL9xeQm2KWxs",
          authDomain: "ssatravels-app-f1b43.firebaseapp.com",
          projectId: "ssatravels-app-f1b43",
          storageBucket: "ssatravels-app-f1b43.firebasestorage.app",
          messagingSenderId: "657612328394",
          appId: "1:657612328394:web:b4948b8e31b465bd34d333",
          measurementId: "G-YE0EHJTPCW");
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return const FirebaseOptions(
          apiKey: "AIzaSyD-WiIM0Ga4U1sAHstnFYuWL9xeQm2KWxs",
          authDomain: "ssatravels-app-f1b43.firebaseapp.com",
          projectId: "ssatravels-app-f1b43",
          storageBucket: "ssatravels-app-f1b43.firebasestorage.app",
          messagingSenderId: "657612328394",
          appId: "1:657612328394:web:b4948b8e31b465bd34d333",
          measurementId: "G-YE0EHJTPCW");
    }
    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      return const FirebaseOptions(
          apiKey: "AIzaSyD-WiIM0Ga4U1sAHstnFYuWL9xeQm2KWxs",
          authDomain: "ssatravels-app-f1b43.firebaseapp.com",
          projectId: "ssatravels-app-f1b43",
          storageBucket: "ssatravels-app-f1b43.firebasestorage.app",
          messagingSenderId: "657612328394",
          appId: "1:657612328394:web:b4948b8e31b465bd34d333",
          measurementId: "G-YE0EHJTPCW");
    }
    throw UnsupportedError(
        'DefaultFirebaseOptions are not supported for this platform.');
  }
}
