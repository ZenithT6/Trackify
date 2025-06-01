import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:vibration/vibration.dart';

import '../services/step_tracker_service.dart';
import 'daily_steps_screen.dart';
import 'heart_rate_screen.dart';
import 'calories_screen.dart';
import 'sleep_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int bpm = 0;
  double sleepHours = 0.0;
  String name = "Zenith";

  late AnimationController _greetingController;
  late Animation<double> _greetingAnimation;

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _loadHeartAndSleep();
    _greetingController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _greetingAnimation = CurvedAnimation(
      parent: _greetingController,
      curve: Curves.easeOutBack,
    );
    _greetingController.forward();
  }

  Future<void> _loadUserName() async {
    final userBox = await Hive.openBox('userBox');
    setState(() {
      name = userBox.get('name', defaultValue: 'Zenith');
    });
  }

  Future<void> _loadHeartAndSleep() async {
    final heartBox = await Hive.openBox('heartBox');
    final sleepBox = await Hive.openBox('sleepBox');
    final now = DateTime.now();
    final key = '${now.year}-${now.month}-${now.day}';

    setState(() {
      bpm = heartBox.get(key, defaultValue: 0);
      final sleepData = sleepBox.get(key);
      if (sleepData is Map && sleepData.containsKey('total')) {
        sleepHours = (sleepData['total'] as num).toDouble();
      } else if (sleepData is num) {
        sleepHours = sleepData.toDouble();
      } else {
        sleepHours = 0.0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final tracker = Provider.of<StepTracker>(context);
    final steps = tracker.steps;
    final calories = (steps * 0.04).toInt();

    final greeting = _getGreeting();
    final date = DateFormat('EEEE, MMMM d').format(DateTime.now());

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4FB),
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const SizedBox(height: 10),
                ScaleTransition(
                  scale: _greetingAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$greeting, $name 👋',
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        date,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _buildSummaryCard(steps, calories),
                const SizedBox(height: 20),
                _buildMetricGrid(context),
                const SizedBox(height: 30),
                _buildTipCard(),
                const SizedBox(height: 80),
              ],
            ),
            _buildFloatingActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(int steps, int calories) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFDEE8F7), Color(0xFFE9F0FB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text("🏃 $steps", style: _summaryStyle()),
              Text("🔥 $calories", style: _summaryStyle()),
              Text("❤️ $bpm", style: _summaryStyle()),
              Text("😴 ${sleepHours.toStringAsFixed(1)}", style: _summaryStyle()),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _getMotivationMessage(steps),
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.green[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 20,
      crossAxisSpacing: 20,
      children: [
        _wiggleCard(context, FontAwesomeIcons.shoePrints, 'Steps', Colors.blue, const DailyStepsScreen()),
        _wiggleCard(context, FontAwesomeIcons.fire, 'Calories', Colors.orange, const CaloriesScreen()),
        _wiggleCard(context, FontAwesomeIcons.heartPulse, 'Heart Rate', Colors.redAccent, const HeartRateScreen()),
        _wiggleCard(context, FontAwesomeIcons.bed, 'Sleep', Colors.deepPurple, const SleepScreen()),
      ],
    );
  }

  Widget _buildTipCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(FontAwesomeIcons.lightbulb, color: Colors.amber, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _getTipOfTheDay(),
              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActions() {
    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          FloatingActionButton(
            heroTag: "qrMenu",
            backgroundColor: Colors.white,
            onPressed: () => _showQrOptions(context),
            child: const Icon(Icons.qr_code, color: Colors.deepPurple),
          ),
          FloatingActionButton(
            heroTag: "profile",
            backgroundColor: Colors.white,
            onPressed: () async {
              await Navigator.pushNamed(context, '/profile');
              _loadUserName();
            },
            child: const Icon(Icons.person, color: Colors.deepPurple),
          ),
        ],
      ),
    );
  }

  void _showQrOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.qr_code),
            title: const Text("Share Steps via QR"),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/qr-share');
            },
          ),
          ListTile(
            leading: const Icon(Icons.qr_code_scanner),
            title: const Text("Scan Friend's QR"),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/qr-scan');
            },
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text("Challenge History"),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/history');
            },
          ),
        ],
      ),
    );
  }

  Widget _wiggleCard(BuildContext context, IconData icon, String label, Color color, Widget route) {
    return StatefulBuilder(
      builder: (context, setState) {
        double scale = 1.0;
        bool pressed = false;
        return GestureDetector(
          onTapDown: (_) => setState(() => scale = 1.05),
          onTapUp: (_) => setState(() => scale = 1.0),
          onTapCancel: () => setState(() => scale = 1.0),
          onLongPressStart: (_) async {
            setState(() {
              pressed = true;
              scale = 1.1;
            });
            if (await Vibration.hasVibrator()) {
              Vibration.vibrate(duration: 50);
            }
          },
          onLongPressEnd: (_) => setState(() {
            pressed = false;
            scale = 1.0;
          }),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => route)),
          child: AnimatedScale(
            scale: scale,
            duration: const Duration(milliseconds: 300),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                color: pressed ? color.withOpacity(0.1) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 30, color: color),
                  const SizedBox(height: 10),
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  TextStyle _summaryStyle() {
    return GoogleFonts.poppins(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: Colors.black87,
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _getMotivationMessage(int steps) {
    if (steps >= 6000 && sleepHours >= 7) {
      return "Great job, you’re on track! 💪";
    } else if (steps < 2000 || sleepHours < 5) {
      return "Let’s get moving! You got this 🚀";
    } else {
      return "Keep it up — you're doing well! 🙌";
    }
  }

  String _getTipOfTheDay() {
    final tips = [
      "Take a 10-minute walk to refresh your mind.",
      "Stay hydrated — your body will thank you.",
      "Stretch for 5 minutes to boost flexibility.",
      "Sleep well to recover stronger.",
      "Consistency beats intensity. Keep going!",
      "Avoid screens before bed for better sleep.",
      "Eat a healthy breakfast to start your day strong.",
    ];
    final today = DateTime.now();
    final index = (today.day + today.month + today.year) % tips.length;
    return tips[index];
  }
}
