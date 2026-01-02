// lib/features/settings/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'data_management_screen.dart';

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
  final Map<String, String> _keyCache = {
    'gemini': '',
    'openai': '',
    'deepseek': '',
    'chatanywhere': '',
  };

  // Define the Theme Color locally for easy usage
  final Color _themeColor = Colors.deepPurple;

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
    String chatAnywhereKey = prefs.getString('api_key_chatanywhere') ?? '';

    setState(() {
      _activeProvider = prefs.getString('active_ai_provider') ?? 'gemini';

      _keyCache['gemini'] = geminiKey;
      _keyCache['openai'] = openaiKey;
      _keyCache['deepseek'] = deepseekKey;
      _keyCache['chatanywhere'] = chatAnywhereKey;

      _apiKeyController.text = _keyCache[_activeProvider] ?? '';

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

    // Save the text currently in the box to the cache before switching
    _keyCache[_activeProvider] = _apiKeyController.text;

    setState(() {
      _activeProvider = newValue;
      // Load the key for the newly selected provider
      _apiKeyController.text = _keyCache[_activeProvider] ?? '';
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // Ensure current field is saved to cache
    _keyCache[_activeProvider] = _apiKeyController.text.trim();

    await prefs.setString('api_key_gemini', _keyCache['gemini']!);
    await prefs.setString('api_key_openai', _keyCache['openai']!);
    await prefs.setString('api_key_deepseek', _keyCache['deepseek']!);
    await prefs.setString('api_key_chatanywhere', _keyCache['chatanywhere']!);

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
              backgroundColor: _themeColor,
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
                  style: const TextStyle(color: Colors.black, fontSize: 16),
                  dropdownColor: Colors.white,
                  iconEnabledColor: _themeColor,
                  decoration: InputDecoration(
                    labelText: 'Select AI Model',
                    border: const OutlineInputBorder(),
                    prefixIcon: Icon(Icons.psychology, color: _themeColor),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'gemini', child: Text('Gemini')),
                    DropdownMenuItem(value: 'openai', child: Text('ChatGPT')),
                    DropdownMenuItem(
                        value: 'chatanywhere', child: Text('ChatAnywhere')),
                    DropdownMenuItem(
                        value: 'deepseek', child: Text('DeepSeek')),
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
                    prefixIcon: Icon(Icons.key, color: _themeColor),
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
                  style: const TextStyle(color: Colors.black, fontSize: 16),
                  dropdownColor: Colors.white,
                  iconEnabledColor: _themeColor,
                  decoration: InputDecoration(
                    labelText: 'Gender',
                    border: const OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person, color: _themeColor),
                  ),
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
                        decoration: InputDecoration(
                            labelText: "Height",
                            border: const OutlineInputBorder(),
                            suffixText: "cm",
                            prefixIcon: Icon(Icons.height, color: _themeColor)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _weightController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                            labelText: "Weight",
                            border: const OutlineInputBorder(),
                            suffixText: "kg",
                            prefixIcon:
                                Icon(Icons.monitor_weight, color: _themeColor)),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 15),
                TextField(
                  controller: _extraContextController,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: "Custom AI Instructions",
                    hintText:
                        "Tell your AI coach about injuries, specific goals, preferred language, or anything you want (e.g., 'I have a bad knee', 'I am vegetarian', 'Answer in Spanish').",
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
