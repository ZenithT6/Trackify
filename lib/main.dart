import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'services/step_tracker_service.dart';
import 'services/lifecycle_observer.dart';
import 'screens/welcome_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/set_goals_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Initialize Hive
  await Hive.initFlutter();
  await Hive.openBox('step_history');
  await Hive.openBox('goalBox');
  await Hive.openBox('userBox');
  await Hive.openBox('settingsBox');

  // ✅ Start lifecycle tracking
  final stepTracker = StepTracker();
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
      },
    );
  }
}
