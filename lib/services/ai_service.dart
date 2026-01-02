// lib/services/ai_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'database_service.dart';
import '../models/gymini_response.dart';

// Providers
import 'providers/ai_provider_interface.dart';
import 'providers/gemini_provider.dart';
import 'providers/openai_provider.dart';
import 'providers/deepseek_provider.dart';
import 'providers/chatanywhere_provider.dart';

class AIService {
  final DatabaseService _dbService = DatabaseService();

  Future<GyminiResponse> sendMessage(String userMessage) async {
    final prefs = await SharedPreferences.getInstance();

    // 1. DETERMINE ACTIVE PROVIDER (Default to 'gemini')
    String providerKey = prefs.getString('active_ai_provider') ?? 'gemini';

    // 2. FETCH THE CORRECT KEY BASED ON PROVIDER
    String? apiKey;
    AIProviderInterface provider;

    switch (providerKey) {
      case 'openai':
        provider = OpenAIProvider();
        apiKey = prefs.getString('api_key_openai');
        break;

      case 'chatanywhere':
        provider = ChatAnywhereProvider();
        apiKey = prefs.getString('api_key_chatanywhere');
        break;

      case 'deepseek':
        provider = DeepSeekProvider();
        apiKey = prefs.getString('api_key_deepseek');
        break;
      case 'gemini':
      default:
        provider = GeminiProvider();
        apiKey = prefs.getString('api_key_gemini') ??
            prefs.getString('custom_api_key');
        // ^ Legacy fallback: Checks old key location if new one is empty
        break;
    }

    // 3. CHECK KEY EXISTENCE
    if (apiKey == null || apiKey.isEmpty) {
      return GyminiResponse(
          responseText:
              "🚫 No API Key Found for ${providerKey.toUpperCase()}.\n\nPlease go to Settings, select '$providerKey', and enter a valid API Key.",
          actionType: "general_chat");
    }

    try {
      // 4. GATHER CONTEXT
      String history = await _dbService.getContextForAI();

      String gender = prefs.getString('user_gender') ?? 'Not specified';
      String height = prefs.getString('user_height') ?? '';
      if (height.isNotEmpty && !height.toLowerCase().contains('cm'))
        height += " cm";

      String weight = prefs.getString('user_weight') ?? '';
      if (weight.isNotEmpty && !weight.toLowerCase().contains('kg'))
        weight += " kg";

      String extraContext = prefs.getString('user_extra_context') ?? '';

      String userProfile = '''
      USER PROFILE:
      - Gender: $gender
      - Height: $height
      - Weight: $weight
      - Additional Context: $extraContext
      ''';

      // 5. DELEGATE TO WORKER
      return await provider.sendMessage(
        apiKey: apiKey,
        history: history,
        userProfile: userProfile,
        userMessage: userMessage,
      );
    } catch (e) {
      // Universal Error Handling
      if (e.toString().contains("API key not valid") ||
          e.toString().contains("403")) {
        return GyminiResponse(
            responseText:
                "⚠️ Your API Key for ${providerKey.toUpperCase()} is invalid.",
            actionType: "general_chat");
      }

      return GyminiResponse(
          responseText: "Connection Error ($providerKey): $e",
          actionType: "general_chat");
    }
  }
}
