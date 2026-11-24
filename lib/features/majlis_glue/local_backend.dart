import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

/// For developers only: runs the whole app against the local Firebase
/// emulators and LiveKit started by `tool/dev.sh` in the Majlis test repo
/// (Learnistan/wellmate-majlis-demo), instead of the real wellmate-56205.
///
///     flutter run --profile --dart-define=WELLMATE_LOCAL_BACKEND=10.0.2.2
///
/// Profile builds only: there Firebase is not started automatically from
/// google-services.json (see android/app/src/profile/AndroidManifest.xml).
///
/// 10.0.2.2 is the Mac as seen from the Android emulator. Without the
/// define (every store build) this does nothing.
class LocalBackend {
  static const host = String.fromEnvironment('WELLMATE_LOCAL_BACKEND');

  static bool get enabled => host.isNotEmpty;

  /// Starts Firebase on the local-only project "demo-wellmate". Nothing can
  /// reach the real project from here.
  static Future<void> initialize() async {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyMajlisLocalEmulatorOnly0000000000', // placeholder; emulators don't check it
        appId: '1:123456789012:android:0123456789abcdef',
        messagingSenderId: '123456789012',
        projectId: 'demo-wellmate',
      ),
    );
    await FirebaseAuth.instance.useAuthEmulator(host, 9099);
    FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
    FirebaseFunctions.instanceFor(region: 'us-central1').useFunctionsEmulator(host, 5001);
  }
}
