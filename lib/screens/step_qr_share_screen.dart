import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../services/user_service.dart';
import '../services/step_tracker_service.dart';
import '../services/firebase_step_service.dart';
import 'live_challenge_screen.dart';

class StepQrShareScreen extends StatefulWidget {
  const StepQrShareScreen({super.key});

  @override
  State<StepQrShareScreen> createState() => _StepQrShareScreenState();
}

class _StepQrShareScreenState extends State<StepQrShareScreen> {
  int stepCount = 0;
  String? qrData;
  late Timer _timer;
  bool loading = true;
  String challengeType = 'daily';
  int selectedDuration = 15;
  bool isChallenge = false;
  Future<String>? _displayNameFuture;
  StreamSubscription<DocumentSnapshot>? _challengeListener;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadSteps();
      await _generateQR();
    });
    _displayNameFuture = UserService().getDisplayName();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _loadSteps());
  }

  Future<void> _loadSteps() async {
    final box = await Hive.openBox('stepBox');
    final now = DateTime.now();
    final key = '${now.year}-${now.month}-${now.day}';
    final current = box.get(key, defaultValue: 0);
    if (mounted) setState(() => stepCount = current);
  }

  Future<void> _generateQR() async {
    if (!mounted) return;
    setState(() => loading = true);

    try {
      final userService = UserService();
      final displayName = await userService.getDisplayName();
      final userId = await userService.getOrCreateUserId();

      final now = DateTime.now();
      final tracker = Provider.of<StepTracker>(context, listen: false);
      final distance = tracker.totalDistance;
      final calories = tracker.totalCalories;
      final activeTimeSeconds = tracker.activeTime.inSeconds;
      final intensity = tracker.status.name;

      final challengeData = {
        "type": challengeType,
        "from": displayName,
        "fromId": userId,
        "fromSteps": stepCount,
        "fromDistance": distance,
        "fromCalories": calories,
        "fromActiveTime": activeTimeSeconds,
        "fromIntensity": intensity,
        "timestamp": now.toIso8601String(),
        "status": "pending",
        "startTime": now.toIso8601String(),
        "durationMinutes": challengeType == 'timed' ? selectedDuration : 1440,
      };

      final docRef = await FirebaseFirestore.instance.collection('challenges').add(challengeData);

      await FirebaseStepService.saveTodayMetrics(
        steps: stepCount,
        distance: distance,
        calories: calories,
        activeTimeSeconds: activeTimeSeconds,
        intensity: intensity,
      );

      final qrPayload = {
        'challengeId': docRef.id,
        'type': challengeType,
      };

      if (mounted) {
        setState(() {
          qrData = jsonEncode(qrPayload);
          loading = false;
        });
      }

      // Listen for receiver to accept challenge
      _challengeListener?.cancel(); // avoid duplicate listeners
      _challengeListener = docRef.snapshots().listen((snapshot) {
        final data = snapshot.data();
        if (data != null && data['status'] == 'accepted') {
          final tracker = Provider.of<StepTracker>(context, listen: false);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => LiveChallengeScreen(
                challengeId: docRef.id,
                challengeData: data,
                stepTracker: tracker,
                isSender: true,
              ),
            ),
          );
        }
      });
    } catch (e) {
      debugPrint("❌ Error generating QR: $e");
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    _challengeListener?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Share Your Steps")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text("Scan this QR to accept the challenge"),
                  const SizedBox(height: 20),
                  if (qrData != null)
                    QrImageView(
                      data: qrData!,
                      version: QrVersions.auto,
                      size: 250,
                      backgroundColor: Colors.white,
                    ),
                  const SizedBox(height: 20),
                  FutureBuilder<String>(
                    future: _displayNameFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Text("Loading user...");
                      } else if (snapshot.hasError) {
                        return const Text("Error loading user");
                      } else {
                        return Text(
                          "Steps: $stepCount\nUser: ${snapshot.data}",
                          textAlign: TextAlign.center,
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 30),
                  Divider(color: Colors.grey[400]),
                  const SizedBox(height: 10),
                  SwitchListTile(
                    title: const Text("Send as Challenge"),
                    value: isChallenge,
                    onChanged: (val) {
                      setState(() => isChallenge = val);
                      _generateQR();
                    },
                  ),
                  const SizedBox(height: 10),
                  if (isChallenge)
                    Column(
                      children: [
                        Text("Select Challenge Mode",
                            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        ToggleButtons(
                          isSelected: [
                            challengeType == 'daily',
                            challengeType == 'timed'
                          ],
                          onPressed: (index) {
                            setState(() {
                              challengeType = index == 0 ? 'daily' : 'timed';
                              selectedDuration = (challengeType == 'daily') ? 1440 : 15;
                              _generateQR();
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          selectedColor: Colors.white,
                          fillColor: Colors.deepPurple,
                          children: const [
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text("24 Hour"),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text("Timed"),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (challengeType == 'timed')
                          Column(
                            children: [
                              Text("Duration", style: GoogleFonts.poppins(fontSize: 16)),
                              const SizedBox(height: 8),
                              DropdownButton<int>(
                                value: selectedDuration,
                                items: const [
                                  DropdownMenuItem(value: 15, child: Text("15 minutes")),
                                  DropdownMenuItem(value: 30, child: Text("30 minutes")),
                                  DropdownMenuItem(value: 60, child: Text("60 minutes")),
                                  DropdownMenuItem(value: 1440, child: Text("24 hours")),
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      selectedDuration = value;
                                      _generateQR();
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                      ],
                    ),
                ],
              ),
            ),
    );
  }
}
