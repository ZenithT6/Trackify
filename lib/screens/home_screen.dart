import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../widgets/health_score_card.dart';
import '../widgets/metric_card.dart';
import '../widgets/bottom_navbar.dart';
import '../screens/daily_steps_screen.dart';
import '../screens/heart_rate_screen.dart' as hr;

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _healthScoreAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _healthScoreAnimation = Tween<double>(begin: 0, end: 0.82).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5FCFF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 16,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Welcome Back, ZENITH",
          style: GoogleFonts.poppins(
            fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black,
          ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 20.0, top: 10),
            child: Icon(Icons.menu, color: Colors.black, size: 30),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedBuilder(
              animation: _healthScoreAnimation,
              builder: (context, child) {
                return HealthScoreCard(scorePercent: _healthScoreAnimation.value);
              },
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Today",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold, fontSize: 18,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => DailyStepsScreen()),
                      );
                    },
                    child: Text(
                      "Daily Steps →",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                childAspectRatio: 1.1,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const hr.HeartRateScreen()),
                      );
                    },
                    child: const MetricCard(
                      title: "Heart Rate",
                      value: "85 BPM",
                      icon: FontAwesomeIcons.heartPulse,
                      color: Colors.red,
                    ),
                  ),
                  const MetricCard(
                    title: "Calories",
                    value: "1500 kcal",
                    icon: FontAwesomeIcons.fireFlameSimple,
                    color: Colors.pink,
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => DailyStepsScreen()),
                      );
                    },
                    child: const MetricCard(
                      title: "Daily Steps",
                      value: "5500 Steps",
                      icon: FontAwesomeIcons.personWalking,
                      color: Colors.blue,
                    ),
                  ),
                  const MetricCard(
                    title: "Sleep",
                    value: "7hrs 54 Secs",
                    icon: FontAwesomeIcons.bed,
                    color: Colors.purple,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBar(),
    );
  }
}
