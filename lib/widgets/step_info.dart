import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StepInfo extends StatelessWidget {
  final IconData icon;
  final String text;

  const StepInfo({required this.icon, required this.text, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 28, color: Colors.black54),
        SizedBox(height: 5),
        Text(text,
            style: GoogleFonts.poppins(
                fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
