// 📁 challenge_history_screen.dart
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/firebase_challenge_service.dart';
import '../services/step_tracker_service.dart';
import 'live_challenge_screen.dart';

class ChallengeHistoryScreen extends StatefulWidget {
  const ChallengeHistoryScreen({super.key});

  @override
  State<ChallengeHistoryScreen> createState() => _ChallengeHistoryScreenState();
}

class _ChallengeHistoryScreenState extends State<ChallengeHistoryScreen> {
  late StepTracker stepTracker;
  List<Map<String, dynamic>> allChallenges = [];
  List<Map<String, dynamic>> filteredChallenges = [];
  String filter = 'All';
  bool loading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    stepTracker = Provider.of<StepTracker>(context, listen: false);
    _loadChallenges();
  }

  Future<void> _loadChallenges() async {
    setState(() => loading = true);
    try {
      final firebaseData = await FirebaseChallengeService.fetchUserChallenges();
      if (firebaseData.isNotEmpty) {
        setState(() {
          allChallenges = firebaseData;
          _applyFilter();
          loading = false;
        });
        return;
      }
    } catch (e) {
      debugPrint("⚠️ Firebase fetch failed: $e");
    }

    final box = Hive.box('scannedChallengesBox');
    final localList = box.toMap().entries.map((e) {
      return Map<String, dynamic>.from(e.value)..['challengeId'] = e.key;
    }).toList();

    setState(() {
      allChallenges = localList;
      _applyFilter();
      loading = false;
    });
  }

  void _applyFilter() {
    if (filter == 'All') {
      filteredChallenges = allChallenges;
    } else if (filter == 'Live') {
      filteredChallenges = allChallenges.where((c) {
        return FirebaseChallengeService.isChallengeStillLive(c) && c['status'] != 'ended' && c['status'] != 'left';
      }).toList();
    } else if (filter == 'Completed') {
      filteredChallenges = allChallenges.where((c) {
        return c['status'] == 'ended';
      }).toList();
    } else if (filter == 'Left') {
      filteredChallenges = allChallenges.where((c) => c['status'] == 'left').toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    filteredChallenges.sort((a, b) {
      final aTime = DateTime.tryParse(a['timestamp'] ?? '') ?? DateTime.now();
      final bTime = DateTime.tryParse(b['timestamp'] ?? '') ?? DateTime.now();
      return bTime.compareTo(aTime);
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text("Challenge History"),
        actions: [
          DropdownButton<String>(
            value: filter,
            underline: const SizedBox(),
            onChanged: (value) {
              setState(() {
                filter = value!;
                _applyFilter();
              });
            },
            items: ['All', 'Live', 'Completed', 'Left']
                .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                .toList(),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: filteredChallenges.length,
              itemBuilder: (context, index) {
                final item = filteredChallenges[index];
                final challengeId = item['challengeId'];
                final name = item['from'] ?? 'Unknown';
                final isSender = item['isSender'] ?? false;
                final status = item['status'] ?? 'unknown';

                final isLive = FirebaseChallengeService.isChallengeStillLive(item) &&
                    status != 'ended' &&
                    status != 'left';

                final mySteps = isSender
                    ? item['finalSenderSteps'] ?? 0
                    : item['finalReceiverSteps'] ?? 0;
                final friendSteps = isSender
                    ? item['finalReceiverSteps'] ?? 0
                    : item['finalSenderSteps'] ?? 0;

                final displayTitle = isSender ? "You vs $name" : "$name vs You";

                final type = item['type'] ?? 'daily';
                final duration = item['durationMinutes'] ?? 1440;

                DateTime start;
                try {
                  final raw = item['startTime'];
                  start = raw is Timestamp
                      ? raw.toDate()
                      : (raw is String)
                          ? DateTime.tryParse(raw) ?? DateTime.now()
                          : DateTime.now();
                } catch (_) {
                  start = DateTime.now();
                }

                final result = isLive
                    ? (mySteps > friendSteps
                        ? '🏆 Winning'
                        : (mySteps < friendSteps ? '📉 Behind' : '🤝 Tie'))
                    : (status == 'left'
                        ? '❌ You Left'
                        : (status == 'ended'
                            ? (item['endedBy'] == 'sender' && isSender ||
                                    item['endedBy'] == 'receiver' && !isSender
                                ? '⛔ You Ended'
                                : '❗ Opponent Ended')
                            : (mySteps > friendSteps
                                ? '🏆 Won'
                                : (mySteps < friendSteps ? '😞 Lost' : '🤝 Tie'))));

                return Dismissible(
                  key: ValueKey(challengeId),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  confirmDismiss: (_) async {
                    final confirm = await showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text("Delete Challenge"),
                        content: const Text("Are you sure you want to delete this challenge?"),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
                          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete")),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      Hive.box('scannedChallengesBox').delete(challengeId);
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(FirebaseAuth.instance.currentUser?.uid ?? 'anonymous')
                          .collection('challenges')
                          .doc(challengeId)
                          .delete();
                      setState(() {
                        filteredChallenges.removeAt(index);
                      });
                      return true;
                    }
                    return false;
                  },
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 3,
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      title: Row(
                        children: [
                          Expanded(child: Text(displayTitle)),
                          if (isLive)
                            _buildChip("LIVE", Colors.green)
                          else if (status == 'ended')
                            _buildChip("ENDED", Colors.orange)
                          else if (status == 'left')
                            _buildChip("LEFT", Colors.red),
                        ],
                      ),
                      subtitle: Text(
                        "${type == 'timed' ? '$duration Min Timed Challenge' : '24 Hour Daily Challenge'}\nResult: $result",
                      ),
                      isThreeLine: true,
                      trailing: isLive
                          ? PopupMenuButton(
                              onSelected: (value) async {
                                if (value == 'leave') {
                                  final confirm = await showDialog(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: const Text("Leave Challenge"),
                                      content: const Text("Do you want to leave this challenge?"),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
                                        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Leave")),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    item['status'] = 'left';
                                    await FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(FirebaseAuth.instance.currentUser?.uid ?? 'anonymous')
                                        .collection('challenges')
                                        .doc(challengeId)
                                        .set(item);
                                    await Hive.box('scannedChallengesBox').put(challengeId, item);
                                    setState(() => _applyFilter());
                                  }
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(value: 'leave', child: Text('Leave Challenge')),
                              ],
                            )
                          : null,
                      onTap: () {
                        if (isLive) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => LiveChallengeScreen(
                                challengeId: challengeId,
                                challengeData: item,
                                isSender: isSender,
                                stepTracker: stepTracker,
                              ),
                            ),
                          ).then((_) => _loadChallenges());
                        } else {
                          _showSummaryDialog(name, start, mySteps, friendSteps, duration, type, result);
                        }
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  void _showSummaryDialog(String name, DateTime date, int my, int friend, int minutes, String type, String result) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Challenge Summary"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("👤 Opponent: $name"),
            Text("📅 Date: ${DateFormat('yyyy-MM-dd').format(date)}"),
            const SizedBox(height: 10),
            Text("🧍 You: $my steps"),
            Text("👤 Opponent: $friend steps"),
            const SizedBox(height: 10),
            Text("⏱ Duration: ${type == 'timed' ? "$minutes Min" : "24 Hour"}"),
            const SizedBox(height: 10),
            Text("🎯 Result: $result"),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close")),
        ],
      ),
    );
  }
}
