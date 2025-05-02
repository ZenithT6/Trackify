import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F9FF),
      appBar: AppBar(
        title: const Text("About App", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Trackify",
                style: GoogleFonts.poppins(
                    fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text("Version 1.0.0",
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600])),
            const SizedBox(height: 20),
            Text(
              "Trackify is a fitness and wellness tracker that helps you stay on top of your daily goals. Monitor your steps, calories, sleep, and heart rate—all in one place.",
              style: GoogleFonts.poppins(fontSize: 15),
            ),
            const SizedBox(height: 20),
            Text(
              "Developed by Zenith Thapa",
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600, color: Colors.deepPurple),
            ),
            const Spacer(),
            Center(
              child: Text(
                "© 2025 Trackify. All rights reserved.",
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
              ),
            )
          ],
        ),
      ),
    );
  }
}
