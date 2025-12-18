// lib/features/settings/settings_screen.dart
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
  // We reuse one controller, but switch its content based on selection
  final _apiKeyController = TextEditingController();

  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _extraContextController = TextEditingController();

  // Settings State
  String _activeProvider = 'gemini'; // Default
  String? _selectedGender;
  bool _isLoading = true;

  // Cache keys temporarily so they don't get lost when switching dropdowns
  final Map<String, String> _keyCache = {
    'gemini': '',
    'openai': '',
    'deepseek': '',
  };

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Load Keys
    String geminiKey = prefs.getString('api_key_gemini') ??
        prefs.getString('custom_api_key') ??
        '';
    String openaiKey = prefs.getString('api_key_openai') ?? '';
    String deepseekKey = prefs.getString('api_key_deepseek') ?? '';

    setState(() {
      _activeProvider = prefs.getString('active_ai_provider') ?? 'gemini';

      // Store in cache
      _keyCache['gemini'] = geminiKey;
      _keyCache['openai'] = openaiKey;
      _keyCache['deepseek'] = deepseekKey;

      // Set controller to currently active provider's key
      _apiKeyController.text = _keyCache[_activeProvider]!;

      // Load Profile
      _selectedGender = prefs.getString('user_gender');
      _heightController.text = prefs.getString('user_height') ?? '';
      _weightController.text = prefs.getString('user_weight') ?? '';
      _extraContextController.text =
          prefs.getString('user_extra_context') ?? '';

      _isLoading = false;
    });
  }

  // Handle Dropdown Change
  void _onProviderChanged(String? newValue) {
    if (newValue == null) return;

    // Save current text to cache before switching
    _keyCache[_activeProvider] = _apiKeyController.text;

    setState(() {
      _activeProvider = newValue;
      // Load new provider's key from cache
      _apiKeyController.text = _keyCache[_activeProvider]!;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Save whatever is currently in the text box to the cache first
    _keyCache[_activeProvider] = _apiKeyController.text.trim();

    // 2. Write ALL keys to storage
    await prefs.setString('api_key_gemini', _keyCache['gemini']!);
    await prefs.setString('api_key_openai', _keyCache['openai']!);
    await prefs.setString('api_key_deepseek', _keyCache['deepseek']!);

    // 3. Save Active Provider
    await prefs.setString('active_ai_provider', _activeProvider);

    // 4. Save Profile
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
    }
  }

  // --- DATA ACTIONS (Keep exactly as before) ---
  Future<void> _exportData() async {
    try {
      final jsonString = await DatabaseService().exportDataAsJson();
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/gymini_logs.json';
      final file = File(path);
      await file.writeAsString(jsonString);

      if (mounted) {
        final box = context.findRenderObject() as RenderBox?;
        await Share.shareXFiles(
          [XFile(path)],
          text: 'My Gymini Workout Logs',
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
      appBar: AppBar(title: const Text('Settings & Profile')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // --- 1. AI MODEL SELECTION ---
                const Text("🤖 AI Configuration",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),

                // PROVIDER DROPDOWN
                DropdownButtonFormField<String>(
                  value: _activeProvider,
                  decoration: const InputDecoration(
                    labelText: 'Select AI Model',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.psychology),
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: 'gemini', child: Text('Google Gemini (Flash)')),
                    DropdownMenuItem(
                        value: 'openai', child: Text('OpenAI (GPT-4o)')),
                    DropdownMenuItem(
                        value: 'deepseek', child: Text('DeepSeek (V3)')),
                  ],
                  onChanged: _onProviderChanged,
                ),

                const SizedBox(height: 15),

                // DYNAMIC API KEY FIELD
                TextField(
                  controller: _apiKeyController,
                  decoration: InputDecoration(
                    labelText:
                        "${_activeProvider[0].toUpperCase()}${_activeProvider.substring(1)} API Key",
                    hintText:
                        _activeProvider == 'gemini' ? "AIzaSy..." : "sk-...",
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.key),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  "Key is saved specifically for $_activeProvider.",
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),

                const SizedBox(height: 30),

                // --- 2. PERSONAL PROFILE ---
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
                    hintText: "e.g., I'm pregnant, recovering from injury...",
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),

                const SizedBox(height: 30),

                // --- 3. DATA ---
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
