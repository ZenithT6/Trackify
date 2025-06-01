import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class FirebaseChallengeService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static String get _uid => _auth.currentUser?.uid ?? 'anonymous';

  static DocumentReference<Map<String, dynamic>> _challengeDoc(String challengeId) {
    return _firestore.collection('challenges').doc(challengeId);
  }

  static DocumentReference<Map<String, dynamic>> _userChallengeDoc(String challengeId, [String? uidOverride]) {
    final uid = uidOverride ?? _uid;
    return _firestore.collection('users').doc(uid).collection('challenges').doc(challengeId);
  }

  static Future<void> syncChallengeToUser(String challengeId, Map<String, dynamic> challengeData) async {
    try {
      await _userChallengeDoc(challengeId).set(challengeData, SetOptions(merge: true));
      debugPrint("✅ Synced challenge to user: $challengeId");
    } catch (e) {
      debugPrint("❌ Failed to sync challenge to user: $e");
    }
  }

  static Future<void> syncChallengeResult(
    String challengeId,
    String result, {
    required int senderSteps,
    required int receiverSteps,
    required String senderIntensity,
    required String receiverIntensity,
    required double senderDistance,
    required double receiverDistance,
    required double senderCalories,
    required double receiverCalories,
  }) async {
    final resultData = {
      'result': result,
      'completedAt': FieldValue.serverTimestamp(),
      'finalSenderSteps': senderSteps,
      'finalReceiverSteps': receiverSteps,
      'finalSenderIntensity': senderIntensity,
      'finalReceiverIntensity': receiverIntensity,
      'finalSenderDistance': senderDistance,
      'finalReceiverDistance': receiverDistance,
      'finalSenderCalories': senderCalories,
      'finalReceiverCalories': receiverCalories,
      'status': 'ended',
    };

    try {
      await _challengeDoc(challengeId).update(resultData);
      await _userChallengeDoc(challengeId).set(resultData, SetOptions(merge: true));
      debugPrint("✅ Challenge result synced globally and locally");
    } catch (e) {
      debugPrint("❌ Error syncing challenge result: $e");
    }
  }

  static Future<void> markChallengeAcceptedByReceiver(String challengeId) async {
    try {
      await _challengeDoc(challengeId).update({
        'status': 'accepted',
        'acceptedAt': FieldValue.serverTimestamp(),
      });
      await _userChallengeDoc(challengeId).set({'status': 'accepted'}, SetOptions(merge: true));
      debugPrint("✅ Challenge marked as accepted");
    } catch (e) {
      debugPrint("❌ Failed to mark as accepted: $e");
    }
  }

  static Future<void> endChallengeByUser(
    String challengeId, {
    required bool isSender,
    required int mySteps,
    required int opponentSteps,
    required double myDistance,
    required double opponentDistance,
    required double myCalories,
    required double opponentCalories,
    required String myIntensity,
    required String opponentIntensity,
    String? opponentUid,
  }) async {
    final endedBy = isSender ? 'sender' : 'receiver';

    final result = mySteps > opponentSteps
        ? (isSender ? 'won' : 'lost')
        : mySteps < opponentSteps
            ? (isSender ? 'lost' : 'won')
            : 'tie';

    final update = {
      'status': 'ended',
      'endedBy': endedBy,
      'result': result,
      'completedAt': FieldValue.serverTimestamp(),
      'finalSenderSteps': isSender ? mySteps : opponentSteps,
      'finalReceiverSteps': isSender ? opponentSteps : mySteps,
      'finalSenderDistance': isSender ? myDistance : opponentDistance,
      'finalReceiverDistance': isSender ? opponentDistance : myDistance,
      'finalSenderCalories': isSender ? myCalories : opponentCalories,
      'finalReceiverCalories': isSender ? opponentCalories : myCalories,
      'finalSenderIntensity': isSender ? myIntensity : opponentIntensity,
      'finalReceiverIntensity': isSender ? opponentIntensity : myIntensity,
    };

    try {
      await _challengeDoc(challengeId).update(update);
      await _userChallengeDoc(challengeId).set(update, SetOptions(merge: true));

      if (opponentUid != null) {
        await _userChallengeDoc(challengeId, opponentUid).set(update, SetOptions(merge: true));
      }

      debugPrint("✅ Challenge manually ended and synced to both users");
    } catch (e) {
      debugPrint("❌ Error ending challenge: $e");
    }
  }

  static Future<List<Map<String, dynamic>>> fetchUserChallenges() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_uid)
          .collection('challenges')
          .orderBy('startTime', descending: true)
          .get();

      return snapshot.docs.map((doc) => {
            ...doc.data(),
            'challengeId': doc.id,
          }).toList();
    } catch (e) {
      debugPrint("❌ Failed to fetch user challenges: $e");
      return [];
    }
  }

  static Future<Map<String, dynamic>?> fetchChallengeById(String challengeId) async {
    try {
      final doc = await _challengeDoc(challengeId).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      debugPrint("❌ Failed to fetch challenge by ID: $e");
      return null;
    }
  }

  /// ✅ Updated: Exclude already-ended or left challenges from showing as live
  static bool isChallengeStillLive(Map<String, dynamic> data) {
    try {
      final status = (data['status'] ?? '').toString().toLowerCase();
      if (status == 'ended' || status == 'left') return false;

      final startRaw = data['startTime'];
      final durationMinutes = data['durationMinutes'] ?? 1440;
      final type = data['type'] ?? 'daily';

      DateTime start;
      if (startRaw is Timestamp) {
        start = startRaw.toDate();
      } else if (startRaw is String) {
        start = DateTime.tryParse(startRaw) ?? DateTime.now();
      } else if (startRaw is DateTime) {
        start = startRaw;
      } else {
        return false;
      }

      final now = DateTime.now();
      final end = start.add(Duration(minutes: durationMinutes));

      if (type == 'daily') {
        final startDay = DateTime(start.year, start.month, start.day);
        final today = DateTime(now.year, now.month, now.day);
        return startDay == today && now.isBefore(end);
      } else {
        return now.isBefore(end);
      }
    } catch (e) {
      debugPrint("❌ isChallengeStillLive() failed: $e");
      return false;
    }
  }
}
