import 'dart:async';

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

  Timer? _retryTimer;
  int _retries = 0;
  bool _syncAgain = false;

  Future<bool> sync() async {
    final uid = firebaseAuth.currentUser?.uid;
    if (uid == null) return false;

    if (_isSyncing) {
      _syncAgain = true; // run once more when the current sync ends
      return false;
    }

    _isSyncing = true;
    notifyListeners();

    var ok = false;

    try {
      ok = await syncData(uid);
      await refreshStatus();
    } catch (_) {
      ok = false;
    } finally {
      _isSyncing = false;
      notifyListeners();
    }

    if (ok) {
      _retries = 0;
    } else {
      _scheduleRetry();
    }

    if (_syncAgain) {
      _syncAgain = false;
      sync();
    }

    return ok;
  }

  void _scheduleRetry() {
    if (_retries >= 3) return; // resume/launch will try again later
    _retries++;
    _retryTimer?.cancel();
    _retryTimer = Timer(Duration(seconds: 10 * _retries), sync);
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    super.dispose();
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