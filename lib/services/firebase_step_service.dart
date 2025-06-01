import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';

class FirebaseStepService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static String get _uid => _auth.currentUser?.uid ?? 'anonymous';

  static CollectionReference<Map<String, dynamic>> get _userStepsRef =>
      _firestore.collection('users').doc(_uid).collection('steps');

  // 🔁 Sync cache to prevent unnecessary writes
  static int? _lastSyncedSteps;
  static double? _lastSyncedDistance;
  static double? _lastSyncedCalories;
  static int? _lastSyncedActiveTime;

  /// ✅ Save today's metrics (only if data has changed)
  static Future<void> saveTodayMetrics({
    required int steps,
    required double distance,
    required double calories,
    required int activeTimeSeconds,
    required String intensity,
  }) async {
    final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // Skip redundant syncs
    if (_lastSyncedSteps == steps &&
        _lastSyncedDistance == distance &&
        _lastSyncedCalories == calories &&
        _lastSyncedActiveTime == activeTimeSeconds) {
      debugPrint("⏩ No changes in metrics — skipping Firebase sync.");
      return;
    }

    try {
      await _userStepsRef.doc(todayKey).set({
        'uid': _uid,
        'steps': steps,
        'distance': distance,
        'calories': calories,
        'activeTimeSeconds': activeTimeSeconds,
        'intensity': intensity,
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Update sync cache
      _lastSyncedSteps = steps;
      _lastSyncedDistance = distance;
      _lastSyncedCalories = calories;
      _lastSyncedActiveTime = activeTimeSeconds;

      debugPrint("✅ Synced metrics to Firebase for $todayKey (Intensity: $intensity)");
    } catch (e) {
      debugPrint("❌ Failed to sync metrics: $e");
    }
  }

  /// 🗓️ Get all metrics for a specific date
  static Future<Map<String, dynamic>> getMetricsForDate(String dateKey) async {
    try {
      final doc = await _userStepsRef.doc(dateKey).get();
      return doc.data() ?? {};
    } catch (e) {
      debugPrint("❌ Failed to fetch metrics for $dateKey: $e");
      return {};
    }
  }

  /// 📊 Get steps for the past 7 days
  static Future<Map<String, int>> getWeeklySteps() async {
    final now = DateTime.now();
    final Map<String, int> weeklySteps = {};

    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: i));
      final key = DateFormat('yyyy-MM-dd').format(date);
      try {
        final doc = await _userStepsRef.doc(key).get();
        final steps = doc.data()?['steps'];
        weeklySteps[key] = (steps is int) ? steps : 0;
      } catch (_) {
        weeklySteps[key] = 0;
      }
    }

    debugPrint("📆 Weekly steps fetched: $weeklySteps");
    return weeklySteps;
  }

  /// 🧹 Delete a day’s step data (for dev/debug use)
  static Future<void> deleteStepEntry(String dateKey) async {
    try {
      await _userStepsRef.doc(dateKey).delete();
      debugPrint("🗑️ Deleted step data for $dateKey");
    } catch (e) {
      debugPrint("❌ Failed to delete steps for $dateKey: $e");
    }
  }
}
