import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import 'live_challenge_screen.dart';
import '../services/step_tracker_service.dart';
import '../services/firebase_challenge_service.dart';
import '../services/user_service.dart';

class StepQrScanScreen extends StatefulWidget {
  const StepQrScanScreen({super.key});

  @override
  State<StepQrScanScreen> createState() => _StepQrScanScreenState();
}

class _StepQrScanScreenState extends State<StepQrScanScreen> {
  bool scanned = false;
  late StepTracker stepTracker;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    stepTracker = Provider.of<StepTracker>(context, listen: false);
  }

  void _handleBarcode(BarcodeCapture capture) async {
    if (scanned) return;
    final rawValue = capture.barcodes.first.rawValue;

    if (rawValue == null || rawValue.trim().isEmpty) {
      _showInvalidQRDialog("Empty QR Code");
      return;
    }

    setState(() => scanned = true);

    try {
      final data = jsonDecode(rawValue);
      final challengeId = data['challengeId'];
      final type = data['type'];

      if (challengeId == null || type == null || (type != 'daily' && type != 'timed')) {
        _showInvalidQRDialog("Invalid or unsupported QR format.");
        return;
      }

      final challengeSnapshot =
          await FirebaseFirestore.instance.collection('challenges').doc(challengeId).get();
      if (!challengeSnapshot.exists) {
        _showInvalidQRDialog("Challenge not found.");
        return;
      }

      final challengeData = challengeSnapshot.data()!;
      final name = challengeData['from'] ?? 'Unknown';
      final fromId = challengeData['fromId'];
      final myId = await UserService().getOrCreateUserId();

      if (fromId == myId) {
        _showInvalidQRDialog("You cannot challenge yourself.");
        return;
      }

      if (!FirebaseChallengeService.isChallengeStillLive(challengeData)) {
        _showInvalidQRDialog("This challenge has expired.");
        return;
      }

      final userChallengeDoc = FirebaseFirestore.instance
          .collection('users')
          .doc(myId)
          .collection('challenges')
          .doc(challengeId);
      if ((await userChallengeDoc.get()).exists) {
        _showInfoSnack("You've already accepted or scanned this challenge.");
        return;
      }

      // Challenge info from Firebase
      final friendSteps = challengeData['fromSteps'] ?? 0;
      final friendDistance = challengeData['fromDistance'] ?? 0.0;
      final friendCalories = challengeData['fromCalories'] ?? 0.0;
      final friendActiveTime = challengeData['fromActiveTime'] ?? 0;
      final friendIntensity = challengeData['fromIntensity'] ?? '-';
      final challengeType = challengeData['type'] ?? 'daily';
      final durationMinutes = challengeData['durationMinutes'] ?? 1440;
      final startTime = challengeData['startTime'];

      final now = DateTime.now();
      final stepBox = Hive.box('stepBox');
      final todayKey = '${now.year}-${now.month}-${now.day}';
      final mySteps = stepBox.get(todayKey, defaultValue: 0);
      final myDistance = stepTracker.totalDistance;
      final myCalories = stepTracker.totalCalories;
      final myActiveTime = stepTracker.activeTime.inSeconds;
      final myIntensity = stepTracker.status.name;

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Step Challenge"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("👤 $name walked $friendSteps steps."),
              Text("🧍 You walked $mySteps steps."),
              const SizedBox(height: 12),
              const Text("Do you want to accept this challenge?"),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final denyData = {
                  'from': name,
                  'steps': friendSteps,
                  'mySteps': mySteps,
                  'timestamp': now.toIso8601String(),
                  'status': 'denied',
                  'challengeId': challengeId,
                };
                await Hive.box('scannedChallengesBox').put(challengeId, denyData);
                if (mounted) Navigator.pop(context);
                _showInfoSnack("Challenge denied.");
              },
              child: const Text("No"),
            ),
            ElevatedButton(
              onPressed: () async {
                final metadata = {
                  'from': name,
                  'fromId': fromId, // ✅ Needed for live challenge syncing
                  'fromSteps': friendSteps,
                  'fromDistance': friendDistance,
                  'fromCalories': friendCalories,
                  'fromActiveTime': friendActiveTime,
                  'fromIntensity': friendIntensity,
                  'mySteps': mySteps,
                  'distance': myDistance,
                  'calories': myCalories,
                  'activeTime': myActiveTime,
                  'intensity': myIntensity,
                  'timestamp': now.toIso8601String(),
                  'status': 'accepted',
                  'challengeId': challengeId,
                  'isSender': false,
                  'type': challengeType,
                  'durationMinutes': durationMinutes,
                  'startTime': startTime,
                };

                await FirebaseChallengeService.syncChallengeToUser(challengeId, metadata);
                await FirebaseChallengeService.markChallengeAcceptedByReceiver(challengeId);
                await Hive.box('scannedChallengesBox').put(challengeId, metadata);

                if (!mounted) return;
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LiveChallengeScreen(
                      challengeData: metadata,
                      challengeId: challengeId,
                      isSender: false,
                      stepTracker: stepTracker,
                    ),
                  ),
                );
              },
              child: const Text("Accept"),
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint("❌ Invalid QR: $e");
      _showInvalidQRDialog("Invalid QR format.");
    }
  }

  void _showInvalidQRDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Invalid QR"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => scanned = false);
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _showInfoSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.orange),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scan QR Code")),
      body: Column(
        children: [
          Expanded(
            child: MobileScanner(
              controller: MobileScannerController(
                facing: CameraFacing.back,
                detectionSpeed: DetectionSpeed.normal,
              ),
              onDetect: _handleBarcode,
            ),
          ),
          if (!scanned)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                "Point your camera at a Trackify QR to accept a step challenge.",
                style: GoogleFonts.poppins(fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}
