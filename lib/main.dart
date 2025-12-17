// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/chat_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'features/log_workout/log_workout_screen.dart';
import 'features/chat/chat_screen.dart';

void main() async {
  //
  // Ensure Flutter engine is ready before loading .env
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Attempt to load the file
    await dotenv.load(fileName: ".env");
  } catch (e) {
    // If it fails, print the error but DO NOT CRASH the app
    print("---------------------------------------------------");
    print("ERROR LOADING .ENV FILE: $e");
    print("---------------------------------------------------");
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: const MaterialApp(home: HomeScreen()),
    ),
  );
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gymini')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const LogWorkoutScreen())),
              child: const Text("Log Workout"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ChatScreen())),
              child: const Text("Chat with Coach"),
            ),
          ],
        ),
      ),
    );
  }
}
