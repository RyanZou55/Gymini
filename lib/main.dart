// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/chat_provider.dart';
import 'features/log_workout/log_workout_screen.dart';
import 'features/chat/chat_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/log_meal/log_meal_screen.dart';

void main() {
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
      appBar: AppBar(
        title: const Text('Gymini'),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.settings,
              size: 30.0,
            ),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SettingsScreen())),
          )
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- 1. LOG WORKOUT BUTTON ---
              ElevatedButton.icon(
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const LogWorkoutScreen())),
                icon: const Icon(Icons.fitness_center),
                label: const Text("Log Workout"),
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(20),
                    textStyle: const TextStyle(fontSize: 18)),
              ),

              const SizedBox(height: 20),

              // --- 2. LOG MEAL BUTTON (NEW) ---
              ElevatedButton.icon(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const LogMealScreen())),
                icon: const Icon(Icons.restaurant), // Food Icon
                label: const Text("Log Meal"),
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(20),
                    //backgroundColor: Colors.orange, // Distinct color for food
                    //foregroundColor: Colors.white, // White text
                    textStyle: const TextStyle(fontSize: 18)),
              ),

              const SizedBox(height: 20),

              // --- 3. CHAT BUTTON ---
              ElevatedButton.icon(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ChatScreen())),
                icon: const Icon(Icons.chat_bubble),
                label: const Text("Chat with your AI Coach"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(20),
                  textStyle: const TextStyle(fontSize: 18),
                  //backgroundColor: Colors.blue[50]
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
