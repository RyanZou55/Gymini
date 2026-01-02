// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/chat_provider.dart';
import 'features/log_workout/log_workout_screen.dart';
import 'features/chat/chat_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/log_meal/log_meal_screen.dart';
import 'features/splash/splash_screen.dart';

void main() {
  runApp(
    // We MUST wrap the app in MultiProvider so ChatProvider is available
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gymini',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          primary: Colors.deepPurple,
        ),
        useMaterial3: true,

        // 1. Keep the background Pure White
        scaffoldBackgroundColor: Colors.white,

        // 2. AppBar Theme (Deep Purple with White Text)
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white, // Header background is White
          foregroundColor: Colors.deepPurple, // Header Title/Icons are Purple
          elevation: 0, // No shadow (flat)
          scrolledUnderElevation: 0, // Stays white when scrolling
          iconTheme: IconThemeData(
              color: Colors.deepPurple), // Ensures back buttons are purple
        ),

        // 3. BUTTONS: White Background, Purple Text, with Shadow
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white, // The button body is White
            foregroundColor: Colors.deepPurple, // The text/icon is Purple
            elevation: 4, // This creates the "Shade" / Drop Shadow
            shadowColor: Colors
                .black45, // Optional: Makes the shadow slightly more visible
            padding: const EdgeInsets.all(20), // consistent padding
            shape: RoundedRectangleBorder(
              // Optional: Rounded corners
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      // Start with the Splash Screen
      home: const SplashScreen(),
    );
  }
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
            icon: const Icon(Icons.settings, size: 30.0),
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

              // --- 2. LOG MEAL BUTTON ---
              ElevatedButton.icon(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const LogMealScreen())),
                icon: const Icon(Icons.restaurant),
                label: const Text("Log Meal"),
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(20),
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
