import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class CircularProgressWidget extends StatelessWidget {
  const CircularProgressWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          height: 120,
          width: 120,
          child: CircularProgressIndicator(
            value: 5500 / 8000, // Steps Progress
            strokeWidth: 10,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation(Colors.blue),
          ),
        ),
        Column(
          children: [
            Icon(FontAwesomeIcons.personWalking, size: 30),
            SizedBox(height: 5),
            Text("5500 Steps",
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.bold)),
            Text("Goal - 8000 Steps",
                style: GoogleFonts.poppins(fontSize: 12)),
          ],
        ),
      ],
    );
  }
}
