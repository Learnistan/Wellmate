/// Majlis: live voice spaces for WellMate.
///
/// In WellMate, add `const MajlisPage()` as a tab in MainShell. It uses the
/// signed-in Firebase user, Firestore and Cloud Functions, and LiveKit for
/// voice. See INTEGRATION.md at the root of this repository.
library;

export 'domain/majlis_models.dart' show MajlisLeaveResult, MajlisSpace;
export 'data/majlis_keep_alive.dart' show MajlisKeepAlive, ForegroundServiceKeepAlive;
export 'majlis_config.dart';
export 'presentation/pages/majlis_hallway_page.dart' show MajlisPage;
