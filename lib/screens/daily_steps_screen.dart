import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../widgets/circular_progress.dart';
import '../widgets/progress_graph.dart';
import '../widgets/step_info.dart';
import '../widgets/bottom_navbar.dart';

class DailyStepsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFD4F1F4),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Back button & title
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, size: 28, color: Colors.black),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            SizedBox(height: 10),
            Text("Daily Steps",
                style: GoogleFonts.poppins(
                    fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),

            // Circular Progress Indicator
            CircularProgressWidget(),

            SizedBox(height: 20),

            // Step Details Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: const [
                StepInfo(icon: FontAwesomeIcons.clock, text: "2hrs 07 mins"),
                StepInfo(icon: FontAwesomeIcons.locationDot, text: "3.1 km"),
                StepInfo(icon: FontAwesomeIcons.fireFlameSimple, text: "175 kcal"),
              ],
            ),
            SizedBox(height: 20),

            // Progress Graph Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("My Progress",
                      style: GoogleFonts.poppins(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text("Week",
                        style: GoogleFonts.poppins(
                            fontSize: 14, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10),
            const Expanded(child: ProgressGraph()),

            SizedBox(height: 10),
            const BottomNavBar(),
          ],
        ),
      ),
    );
  }
}
