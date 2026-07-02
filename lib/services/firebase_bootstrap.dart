import 'package:firebase_core/firebase_core.dart';

import '../firebase_options.dart';

abstract final class FirebaseBootstrap {
  static Future<void> ensureInitialized() async {
    if (Firebase.apps.isNotEmpty) {
      return;
    }

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
}
