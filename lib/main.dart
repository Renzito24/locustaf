import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart' show kReleaseMode;

import 'firebase_options.dart';
import 'app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await FirebaseAppCheck.instance.activate(
    providerAndroid: kReleaseMode
        ? AndroidPlayIntegrityProvider()
        : AndroidDebugProvider(),
    providerApple: kReleaseMode
        ? AppleAppAttestWithDeviceCheckFallbackProvider()
        : AppleDebugProvider(),
    providerWeb: ReCaptchaV3Provider('TU_RECAPTCHA_SITE_KEY_AQUI'),
  );

  runApp(
    const ProviderScope(
      child: LocustafApp(),
    ),
  );
}