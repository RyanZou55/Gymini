import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/database_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _apiKeyController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _extraContextController = TextEditingController();

  String? _selectedGender;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _apiKeyController.text = prefs.getString('custom_api_key') ?? '';
      _selectedGender = prefs.getString('user_gender');
      _heightController.text = prefs.getString('user_height') ?? '';
      _weightController.text = prefs.getString('user_weight') ?? '';
      _extraContextController.text =
          prefs.getString('user_extra_context') ?? '';
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();

    if (_apiKeyController.text.trim().isEmpty) {
      await prefs.remove('custom_api_key');
    } else {
      await prefs.setString('custom_api_key', _apiKeyController.text.trim());
    }

    if (_selectedGender != null) {
      await prefs.setString('user_gender', _selectedGender!);
    }

    await prefs.setString('user_height', _heightController.text.trim());
    await prefs.setString('user_weight', _weightController.text.trim());
    await prefs.setString(
        'user_extra_context', _extraContextController.text.trim());

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile & Settings Saved!')));
      // REMOVED Navigator.pop(context) to stay on this screen
    }
  }

  // --- DATA ACTIONS ---

  Future<void> _exportData() async {
    try {
      // 1. Generate clean JSON
      final jsonString = await DatabaseService().exportDataAsJson();

      // 2. Save to file
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/gymini_logs.json';
      final file = File(path);
      await file.writeAsString(jsonString);

      print("✅ File saved locally at: $path");

      // 3. SHARE THE FILE
      if (mounted) {
        // We calculate the screen size to give the iPad/Mac popover a place to anchor
        final box = context.findRenderObject() as RenderBox?;

        await Share.shareXFiles(
          [XFile(path)],
          text: 'My Gymini Workout Logs',
          // FIX: This 'sharePositionOrigin' is required for iPad/Mac to prevent crashing
          sharePositionOrigin: box != null
              ? box.localToGlobal(Offset.zero) & box.size
              : const Rect.fromLTWH(0, 0, 100, 100),
        );
      }
    } catch (e) {
      // PRINT ERROR TO TERMINAL
      print("🔴 Export Error: $e");

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Export Failed: $e")));
      }
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
      try {
        await DatabaseService().clearAllData();
        print("✅ Data Cleared Successfully");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("All records deleted.")));
        }
      } catch (e) {
        print("🔴 Clear Data Error: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings & Profile')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // API KEY
                const Text("🔑 AI Configuration",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                TextField(
                  controller: _apiKeyController,
                  decoration: const InputDecoration(
                      labelText: "Gemini API Key",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.key)),
                ),

                const SizedBox(height: 30),

                // PROFILE
                const Text("👤 Personal Profile",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),

                DropdownButtonFormField<String>(
                  value: _selectedGender,
                  decoration: const InputDecoration(
                      labelText: 'Gender', border: OutlineInputBorder()),
                  items: ['Male', 'Female'].map((String value) {
                    return DropdownMenuItem<String>(
                        value: value, child: Text(value));
                  }).toList(),
                  onChanged: (newValue) =>
                      setState(() => _selectedGender = newValue),
                ),

                const SizedBox(height: 15),

                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _heightController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                            labelText: "Height",
                            border: OutlineInputBorder(),
                            suffixText: "cm"),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _weightController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                            labelText: "Weight",
                            border: OutlineInputBorder(),
                            suffixText: "kg"),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 15),
                TextField(
                  controller: _extraContextController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: "Coach Context",
                    hintText:
                        "e.g., I'm pregnant, recovering from injury, on a diet... anything your AI coach should know.",
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),

                const SizedBox(height: 30),

                // DATA
                const Text("💾 Data Management",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),

                ListTile(
                  leading: const Icon(Icons.share),
                  title: const Text("Export Logs"),
                  subtitle: const Text("Save & Share JSON file"),
                  onTap: _exportData,
                  tileColor: Colors.grey[100],
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                const SizedBox(height: 10),
                ListTile(
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  title: const Text("Clear All Records",
                      style: TextStyle(color: Colors.red)),
                  onTap: _clearAllData,
                  tileColor: Colors.red[50],
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),

                const SizedBox(height: 40),

                ElevatedButton(
                  onPressed: _saveSettings,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("Save Changes",
                      style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(height: 30),
              ],
            ),
    );
  }
}
