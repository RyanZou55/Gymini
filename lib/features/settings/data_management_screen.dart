// lib/features/settings/data_management_screen.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../../services/database_service.dart';

class DataManagementScreen extends StatefulWidget {
  const DataManagementScreen({super.key});

  @override
  State<DataManagementScreen> createState() => _DataManagementScreenState();
}

class _DataManagementScreenState extends State<DataManagementScreen> {
  final Color _themeColor = Colors.deepPurple;

  Future<void> _exportData() async {
    try {
      // 1. Get the raw (ugly) data string from the DB
      final rawJsonString = await DatabaseService().exportDataAsJson();

      // 2. Decode it so we can clean it up
      final Map<String, dynamic> rawData = jsonDecode(rawJsonString);

      // 3. Process Meals (Remove IDs, Fix Dates)
      List<Map<String, dynamic>> cleanMeals = [];
      if (rawData['meals'] != null) {
        for (var m in rawData['meals']) {
          cleanMeals.add({
            // Format: "Dec 19, 2025 9:19 PM"
            "time": _formatDate(m['timestamp']),
            "type": m['type'],
            "items": m['items'],
            "hunger_before": m['hunger_before'],
            "hunger_after": m['hunger_after'],
          });
        }
      }

      // 4. Process Workouts (Remove IDs, Fix Dates, Fix "Stringified" Exercises)
      List<Map<String, dynamic>> cleanWorkouts = [];
      if (rawData['workouts'] != null) {
        for (var w in rawData['workouts']) {
          // Parse the nested JSON string for exercises
          List<dynamic> exercisesList = [];
          try {
            if (w['exercises'] is String) {
              exercisesList = jsonDecode(w['exercises']);
            }
          } catch (e) {
            exercisesList = [];
          }

          // Clean up the exercises list (Remove IDs inside exercises)
          List<Map<String, dynamic>> cleanExercises = exercisesList.map((ex) {
            // Cast to Map to safely access fields
            Map<String, dynamic> exMap = ex as Map<String, dynamic>;

            // --- UPDATED FOR CARDIO SUPPORT ---
            final type = exMap['type'] ?? 'strength';

            Map<String, dynamic> cleanEx = {
              "name": exMap['name'],
              "type": type,
            };

            if (type == 'cardio') {
              cleanEx["distance_km"] = exMap['distance'];
              cleanEx["duration_mins"] = exMap['duration'];
            } else {
              cleanEx["sets"] = exMap['sets'];
              cleanEx["reps"] = exMap['reps'];
              cleanEx["weight_kg"] = exMap['weight'];
            }

            return cleanEx;
            // ----------------------------------
          }).toList();

          cleanWorkouts.add({
            "date": _formatDate(w['date']),
            "duration_total_minutes": w['duration'],
            "exercises": cleanExercises, // Now a real list, not a string
          });
        }
      }

      // 5. Re-assemble into a clean object
      final Map<String, dynamic> finalData = {
        'export_date': _formatDate(DateTime.now().toIso8601String()),
        'meals': cleanMeals,
        'workouts': cleanWorkouts,
      };

      // 6. Pretty Print the JSON (Add indentation so it's readable)
      final prettyString =
          const JsonEncoder.withIndent('  ').convert(finalData);

      // 7. Save and Share
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/gymini_logs.json';
      final file = File(path);
      await file.writeAsString(prettyString);

      if (mounted) {
        final box = context.findRenderObject() as RenderBox?;
        await Share.shareXFiles(
          [XFile(path)],
          // REMOVED 'text' parameter here to stop the extra text file/caption
          sharePositionOrigin: box != null
              ? box.localToGlobal(Offset.zero) & box.size
              : const Rect.fromLTWH(0, 0, 100, 100),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Export Failed: $e")));
      }
    }
  }

  // Helper to make dates readable (e.g., "2025-12-19 21:19")
  String _formatDate(String? isoString) {
    if (isoString == null) return "";
    try {
      final dt = DateTime.parse(isoString);
      return DateFormat('yyyy-MM-dd HH:mm').format(dt);
    } catch (e) {
      return isoString;
    }
  }

  Future<void> _clearAllData() async {
    bool? confirm = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("⚠️ Delete Everything?"),
        content: const Text(
            "This will permanently delete ALL your workout logs. This cannot be undone."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel")),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("DELETE", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseService().clearAllData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("All records deleted.")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Data Management")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            "Manage your workout history.",
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
          const SizedBox(height: 20),

          // --- EXPORT BUTTON ---
          ListTile(
            leading: Icon(Icons.share, color: _themeColor),
            title: const Text("Export Logs"),
            subtitle: const Text("Save clean JSON file"),
            onTap: _exportData,
            tileColor: Colors.grey[100],
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            trailing: const Icon(Icons.chevron_right),
          ),

          const SizedBox(height: 15),

          // --- DELETE BUTTON ---
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text("Clear All Records",
                style:
                    TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            onTap: _clearAllData,
            tileColor: Colors.red[50],
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ],
      ),
    );
  }
}
