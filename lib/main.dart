import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'data/book_repository.dart';
import 'firebase_options.dart';

/// Run against the local Firebase emulators (no billing needed):
///   flutter run --dart-define=USE_EMULATOR=true
const bool useEmulator = bool.fromEnvironment('USE_EMULATOR');

// 10.0.2.2 is how the Android emulator reaches the host computer.
const String _emulatorHost = '10.0.2.2';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (useEmulator) {
    await FirebaseAuth.instance.useAuthEmulator(_emulatorHost, 9099);
    FirebaseFirestore.instance.useFirestoreEmulator(_emulatorHost, 8080);
    FirebaseFunctions.instanceFor(region: functionsRegion)
        .useFunctionsEmulator(_emulatorHost, 5001);
  }

  runApp(const BookSwapApp());
}
