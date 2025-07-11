// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBm1CLlw_sujrc6h__1eHeFX_3nL4c4mFU',
    appId: '1:315070944581:web:af8e9d6e988296127c9a2c',
    messagingSenderId: '315070944581',
    projectId: 'dr-shakoor-portfolio',
    authDomain: 'dr-shakoor-portfolio.firebaseapp.com',
    storageBucket: 'dr-shakoor-portfolio.firebasestorage.app',
    measurementId: 'G-5KPKZXKZ2Z',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCwDFFGOQ-EnMvs5Td2_yMt1HhCnItqTrc',
    appId: '1:315070944581:android:c0c8c630e2bb7b957c9a2c',
    messagingSenderId: '315070944581',
    projectId: 'dr-shakoor-portfolio',
    storageBucket: 'dr-shakoor-portfolio.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBLH0lq3aR4hbr_EZpiE1dz_YGuNLX7lRc',
    appId: '1:315070944581:ios:a2dd28f67cdf3c657c9a2c',
    messagingSenderId: '315070944581',
    projectId: 'dr-shakoor-portfolio',
    storageBucket: 'dr-shakoor-portfolio.firebasestorage.app',
    iosBundleId: 'muhtamim.com.drmdabdusshakoor',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBLH0lq3aR4hbr_EZpiE1dz_YGuNLX7lRc',
    appId: '1:315070944581:ios:a2dd28f67cdf3c657c9a2c',
    messagingSenderId: '315070944581',
    projectId: 'dr-shakoor-portfolio',
    storageBucket: 'dr-shakoor-portfolio.firebasestorage.app',
    iosBundleId: 'muhtamim.com.drmdabdusshakoor',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBm1CLlw_sujrc6h__1eHeFX_3nL4c4mFU',
    appId: '1:315070944581:web:753408a7bb3b5fb87c9a2c',
    messagingSenderId: '315070944581',
    projectId: 'dr-shakoor-portfolio',
    authDomain: 'dr-shakoor-portfolio.firebaseapp.com',
    storageBucket: 'dr-shakoor-portfolio.firebasestorage.app',
    measurementId: 'G-P6BBBVP159',
  );
}
