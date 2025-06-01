// 📁 live_challenge_screen.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/step_tracker_service.dart';
import '../services/firebase_challenge_service.dart';

class LiveChallengeScreen extends StatefulWidget {
  final String challengeId;
  final Map<String, dynamic> challengeData;
  final StepTracker stepTracker;
  final bool isSender;

  const LiveChallengeScreen({
    super.key,
    required this.challengeId,
    required this.challengeData,
    required this.stepTracker,
    required this.isSender,
  });

  @override
  State<LiveChallengeScreen> createState() => _LiveChallengeScreenState();
}

class _LiveChallengeScreenState extends State<LiveChallengeScreen> {
  late StreamSubscription<DocumentSnapshot> _challengeListener;
  late Timer _syncTimer;

  int mySteps = 0;
  int friendSteps = 0;
  String friendDistance = "-";
  String friendCalories = "-";
  String friendIntensity = "-";
  bool _challengeEnded = false;
  int _lastSyncedSteps = -1;

  late DateTime startTime;
  late DateTime endTime;
  late String challengeType;
  late int durationMinutes;

  @override
  void initState() {
    super.initState();
    _initializeChallengeData();
    _startChallengeListener();
    _syncTimer = Timer.periodic(const Duration(seconds: 10), (_) => _fetchMySteps());
  }

  void _initializeChallengeData() {
    final startRaw = widget.challengeData['startTime'];
    durationMinutes = widget.challengeData['durationMinutes'] ?? 1440;
    challengeType = widget.challengeData['type'] ?? 'daily';

    try {
      startTime = (startRaw is Timestamp)
          ? startRaw.toDate()
          : (startRaw is String)
              ? DateTime.tryParse(startRaw) ?? DateTime.now()
              : (startRaw as DateTime);
    } catch (_) {
      startTime = DateTime.now();
    }

    endTime = startTime.add(Duration(minutes: durationMinutes));
  }

  void _startChallengeListener() {
    _challengeListener = FirebaseFirestore.instance
        .collection('challenges')
        .doc(widget.challengeId)
        .snapshots()
        .listen((doc) async {
      if (!doc.exists) return;
      final data = doc.data()!;
      final now = DateTime.now();
      final status = data['status'];

      if (!_challengeEnded && (status == 'ended' || status == 'endedByUser')) {
        _challengeEnded = true;
        _syncTimer.cancel();
        _challengeListener.cancel();

        final result = data['result'] ?? 'tie';
        final message = (status == 'endedByUser' && data['endedBy'] != widget.isSender)
            ? "Opponent ended the challenge.\nResult: You $result the challenge."
            : "Challenge Ended.\nResult: You $result the challenge.";

        if (mounted) {
          _showDialog("Challenge Ended", message);
        }
        return;
      }

      if (now.isAfter(endTime) && !_challengeEnded) {
        _challengeEnded = true;
        _syncTimer.cancel();
        _challengeListener.cancel();
        await _syncFinalResult(data);
        if (mounted) {
          final result = data['result'] ?? 'tie';
          _showDialog("Challenge Completed", "Result: You $result the challenge.");
        }
        return;
      }

      setState(() {
        friendSteps = widget.isSender
            ? data['receiverSteps'] ?? widget.challengeData['fromSteps'] ?? 0
            : data['senderSteps'] ?? widget.challengeData['fromSteps'] ?? 0;

        friendDistance = ((widget.isSender ? data['receiverDistance'] : data['senderDistance']) ?? 0).toStringAsFixed(1);
        friendCalories = ((widget.isSender ? data['receiverCalories'] : data['senderCalories']) ?? 0).toStringAsFixed(1);
        friendIntensity = (widget.isSender ? data['receiverIntensity'] : data['senderIntensity']) ?? "-";
      });
    });
  }

  Future<void> _fetchMySteps() async {
    final localSteps = widget.stepTracker.steps;
    setState(() => mySteps = localSteps);

    if (localSteps != _lastSyncedSteps) {
      _lastSyncedSteps = localSteps;

      await FirebaseFirestore.instance.collection('challenges').doc(widget.challengeId).update({
        widget.isSender ? 'senderSteps' : 'receiverSteps': localSteps,
        widget.isSender ? 'senderDistance' : 'receiverDistance': widget.stepTracker.totalDistance,
        widget.isSender ? 'senderCalories' : 'receiverCalories': widget.stepTracker.totalCalories,
        widget.isSender ? 'senderIntensity' : 'receiverIntensity': widget.stepTracker.status.name,
        widget.isSender ? 'senderActiveTime' : 'receiverActiveTime': widget.stepTracker.activeTime.inMinutes,
      });
    }
  }

  Future<void> _syncFinalResult(Map<String, dynamic> data) async {
    if (data.containsKey('result')) return;

    String result;
    if (mySteps > friendSteps) {
      result = 'won';
    } else if (mySteps < friendSteps) {
      result = 'lost';
    } else {
      result = 'tie';
    }

    await FirebaseChallengeService.syncChallengeResult(
      widget.challengeId,
      result,
      senderSteps: widget.isSender ? mySteps : friendSteps,
      receiverSteps: widget.isSender ? friendSteps : mySteps,
      senderIntensity: widget.isSender ? widget.stepTracker.status.name : friendIntensity,
      receiverIntensity: widget.isSender ? friendIntensity : widget.stepTracker.status.name,
      senderDistance: widget.isSender ? widget.stepTracker.totalDistance : double.tryParse(friendDistance) ?? 0,
      receiverDistance: widget.isSender ? double.tryParse(friendDistance) ?? 0 : widget.stepTracker.totalDistance,
      senderCalories: widget.isSender ? widget.stepTracker.totalCalories : double.tryParse(friendCalories) ?? 0,
      receiverCalories: widget.isSender ? double.tryParse(friendCalories) ?? 0 : widget.stepTracker.totalCalories,
    );
  }

  void _onEndChallengePressed() async {
    if (_challengeEnded) return;

    final confirm = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("End Challenge"),
        content: const Text("Are you sure you want to end the challenge early?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("End")),
        ],
      ),
    );

    if (confirm == true && !_challengeEnded) {
      _challengeEnded = true;
      _syncTimer.cancel();
      _challengeListener.cancel();

      await FirebaseChallengeService.endChallengeByUser(
        widget.challengeId,
        isSender: widget.isSender,
        mySteps: mySteps,
        opponentSteps: friendSteps,
        myDistance: widget.stepTracker.totalDistance,
        opponentDistance: double.tryParse(friendDistance) ?? 0,
        myCalories: widget.stepTracker.totalCalories,
        opponentCalories: double.tryParse(friendCalories) ?? 0,
        myIntensity: widget.stepTracker.status.name,
        opponentIntensity: friendIntensity,
      );

      if (mounted) {
        _showDialog("Challenge Ended", "You ended the challenge early.");
      }
    }
  }

  void _showDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))],
      ),
    );
  }

  @override
  void dispose() {
    _syncTimer.cancel();
    _challengeListener.cancel();
    super.dispose();
  }

  Widget _buildVersusCard(String label, int steps, String distance, String calories, String intensity, bool isYou) {
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: isYou ? Colors.green[50] : Colors.red[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isYou ? Colors.green : Colors.red, width: 2),
        ),
        child: Column(
          children: [
            Text(label, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("👣 $steps steps", style: GoogleFonts.poppins(fontSize: 14)),
            Text("🔥 $calories kcal", style: GoogleFonts.poppins(fontSize: 14)),
            Text("📏 $distance m", style: GoogleFonts.poppins(fontSize: 14)),
            Text("🏃 $intensity", style: GoogleFonts.poppins(fontSize: 14)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final percent = (mySteps + friendSteps) == 0 ? 0.5 : mySteps / (mySteps + friendSteps);
    final remaining = endTime.difference(DateTime.now());
    final timeLeft = remaining.isNegative
        ? "Challenge Ended"
        : "${remaining.inHours.toString().padLeft(2, '0')}:${(remaining.inMinutes % 60).toString().padLeft(2, '0')}:${(remaining.inSeconds % 60).toString().padLeft(2, '0')}";

    final status = mySteps > friendSteps
        ? "🏆 You are winning!"
        : (mySteps < friendSteps ? "📉 You are behind!" : "🤝 It’s a tie!");

    return Scaffold(
      appBar: AppBar(title: const Text("Live Challenge")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              challengeType == 'timed'
                  ? "⏱ Timed Challenge ($durationMinutes mins)"
                  : "📅 24 Hour Daily Challenge",
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(timeLeft, style: GoogleFonts.poppins(color: Colors.red)),
            const SizedBox(height: 14),
            LinearProgressIndicator(
              value: percent,
              backgroundColor: Colors.grey[300],
              color: Colors.deepPurple,
              minHeight: 8,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _buildVersusCard(
                  "You",
                  mySteps,
                  widget.stepTracker.totalDistance.toStringAsFixed(1),
                  widget.stepTracker.totalCalories.toStringAsFixed(1),
                  widget.stepTracker.status.name,
                  true,
                ),
                const Text("⚔️", style: TextStyle(fontSize: 32)),
                _buildVersusCard(
                  "Opponent",
                  friendSteps,
                  friendDistance,
                  friendCalories,
                  friendIntensity,
                  false,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              status,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _challengeEnded ? null : _onEndChallengePressed,
              icon: const Icon(Icons.flag),
              label: Text(_challengeEnded ? "Challenge Ended" : "End Challenge"),
              style: ElevatedButton.styleFrom(
                backgroundColor: _challengeEnded ? Colors.grey : Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
