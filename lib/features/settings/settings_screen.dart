// lib/features/settings/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'data_management_screen.dart'; // <--- Import New Screen

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Controllers
  final _apiKeyController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _extraContextController = TextEditingController();

  // Settings State
  String _activeProvider = 'gemini';
  String? _selectedGender;
  bool _isLoading = true;

  // Cache keys
  Map<String, String> _keyCache = {
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

    // Load Keys
    String geminiKey = prefs.getString('api_key_gemini') ??
        prefs.getString('custom_api_key') ??
        '';
    String openaiKey = prefs.getString('api_key_openai') ?? '';
    String deepseekKey = prefs.getString('api_key_deepseek') ?? '';

    setState(() {
      _activeProvider = prefs.getString('active_ai_provider') ?? 'gemini';

      _keyCache['gemini'] = geminiKey;
      _keyCache['openai'] = openaiKey;
      _keyCache['deepseek'] = deepseekKey;

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

  void _onProviderChanged(String? newValue) {
    if (newValue == null) return;
    _keyCache[_activeProvider] = _apiKeyController.text;
    setState(() {
      _activeProvider = newValue;
      _apiKeyController.text = _keyCache[_activeProvider]!;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();

    _keyCache[_activeProvider] = _apiKeyController.text.trim();

    await prefs.setString('api_key_gemini', _keyCache['gemini']!);
    await prefs.setString('api_key_openai', _keyCache['openai']!);
    await prefs.setString('api_key_deepseek', _keyCache['deepseek']!);
    await prefs.setString('active_ai_provider', _activeProvider);

    if (_selectedGender != null) {
      await prefs.setString('user_gender', _selectedGender!);
    }
    await prefs.setString('user_height', _heightController.text.trim());
    await prefs.setString('user_weight', _weightController.text.trim());
    await prefs.setString(
        'user_extra_context', _extraContextController.text.trim());

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Profile & Settings Saved!'),
        duration: Duration(seconds: 1),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings & Profile')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: _saveSettings,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text("Save Changes",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
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

                // --- 3. DATA MANAGEMENT BUTTON ---
                ListTile(
                  leading: const Icon(Icons.storage, size: 28),
                  title: const Text("Data Management",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text("Export or Clear Logs"),
                  tileColor: Colors.grey[200],
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  onTap: () {
                    // Navigate to Sub-Page
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const DataManagementScreen()));
                  },
                ),

                const SizedBox(height: 80),
              ],
            ),
    );
  }
}
