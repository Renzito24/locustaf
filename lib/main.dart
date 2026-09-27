import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode;

import 'firebase_options.dart';
import 'app/app.dart';

/// Site key de reCAPTCHA v3 para App Check en web.
///
/// Se inyecta en build, nunca hardcodeada en el repo:
///   flutter run -d chrome --dart-define=RECAPTCHA_SITE_KEY=6Lc...
///   flutter build web --release --dart-define=RECAPTCHA_SITE_KEY=6Lc...
///
/// La key se registra en Firebase Console -> Build -> App Check -> Web.
/// Sin esta key, web corre SIN App Check (las reglas no lo exigen).
const String _recaptchaSiteKey = String.fromEnvironment('RECAPTCHA_SITE_KEY');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await _activateAppCheck();

  runApp(
    const ProviderScope(
      child: LocustafApp(),
    ),
  );
}

Future<void> _activateAppCheck() async {
  if (kIsWeb) {
    if (_recaptchaSiteKey.isEmpty) {
      debugPrint(
        'App Check: web corre sin App Check '
        '(falta --dart-define=RECAPTCHA_SITE_KEY).',
      );
      return;
    }
    await FirebaseAppCheck.instance.activate(
      providerWeb: ReCaptchaV3Provider(_recaptchaSiteKey),
    );
    return;
  }

  await FirebaseAppCheck.instance.activate(
    providerAndroid: kReleaseMode
        ? AndroidPlayIntegrityProvider()
        : AndroidDebugProvider(),
    providerApple: kReleaseMode
        ? AppleAppAttestWithDeviceCheckFallbackProvider()
        : AppleDebugProvider(),
  );
}
