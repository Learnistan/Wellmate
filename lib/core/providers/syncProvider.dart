import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../sync/syncData.dart';

class SyncProvider extends ChangeNotifier {
  final SyncData syncData;
  final FirebaseAuth firebaseAuth;

  SyncProvider(this.syncData, this.firebaseAuth);

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  bool _hasUnsynced = false;
  bool get hasUnsynced => _hasUnsynced;

  Future<bool> sync() async {
    final uid = firebaseAuth.currentUser?.uid;
    if (uid == null || _isSyncing) return false;

    _isSyncing = true;
    notifyListeners();

    try {
      final ok = await syncData(uid);
      await refreshStatus();
      return ok;
    } catch (_) {
      return false;
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> refreshStatus() async {
    final uid = firebaseAuth.currentUser?.uid;
    if (uid == null) return;

    try {
      _hasUnsynced = await syncData.hasUnsynced(uid);
    } catch (_) {}

    notifyListeners();
  }
}