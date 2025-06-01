import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';

import 'models/user_model.dart'; // 
import 'services/step_tracker_service.dart';
import 'services/lifecycle_observer.dart';
import 'models/interval_step_entry.dart';
import 'screens/welcome_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/set_goals_screen.dart';
import 'screens/step_qr_share_screen.dart';
import 'screens/step_qr_scan_screen.dart';
import 'screens/challenge_history_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Initialize Firebase
  await Firebase.initializeApp();

  // ✅ Initialize Hive
  await Hive.initFlutter();

  // ✅ Register Hive Adapters
  Hive.registerAdapter(IntervalStepEntryAdapter());
  Hive.registerAdapter(UserAdapter()); // ✅ NEW: Register user adapter

  // ✅ Open Hive Boxes
  await Hive.openBox('stepBox');
  await Hive.openBox('step_history');
  await Hive.openBox('goalBox');
  await Hive.openBox<User>('usersBox'); // ✅ NEW: User box
  await Hive.openBox('userBox'); // optionally for session
  await Hive.openBox('settingsBox');
  await Hive.openBox('scannedChallengesBox');
  await Hive.openBox<List>('intervalStepsBox');
  await Hive.openBox('sessionBox');

  // ✅ Create StepTracker instance
  final stepTracker = StepTracker();

  // ✅ Attach lifecycle observer
  final lifecycleObserver = MyAppLifecycleObserver(stepTracker);
  lifecycleObserver.start();

  runApp(
    ChangeNotifierProvider.value(
      value: stepTracker,
      child: const TrackifyApp(),
    ),
  );
}

class TrackifyApp extends StatelessWidget {
  const TrackifyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trackify',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        fontFamily: 'Poppins',
      ),
      initialRoute: '/welcome',
      routes: {
        '/welcome': (context) => const WelcomeScreen(),
        '/home': (context) => const HomeScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/set-goals': (context) => const SetGoalsScreen(),
        '/qr-share': (context) => const StepQrShareScreen(),
        '/qr-scan': (context) => const StepQrScanScreen(),
        '/history': (context) => const ChallengeHistoryScreen(),
      },
    );
  }
}
