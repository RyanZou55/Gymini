// lib/services/ai_service.dart
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_service.dart';
import '../models/gymini_response.dart';

class AIService {
  static const String _modelName = 'gemini-flash-latest';
  final DatabaseService _dbService = DatabaseService();

  Future<GyminiResponse> sendMessage(String userMessage) async {
    // 1. Fetch Key directly from storage
    final prefs = await SharedPreferences.getInstance();
    String? apiKey = prefs.getString('custom_api_key');

    // 2. If NO key is saved, stop immediately and guide user
    if (apiKey == null || apiKey.isEmpty) {
      return GyminiResponse(
          responseText:
              "🚫 No API Key Found.\n\nPlease go to Settings (Top Right Gear Icon) and paste your Google Gemini API Key to activate the coach.",
          actionType: "general_chat");
    }

    try {
      // Workout History Context
      String history = await _dbService.getContextForAI();
      // User Profile Context

      String gender = prefs.getString('user_gender') ?? 'Not specified';
      String height = prefs.getString('user_height') ?? '';
      if (height.isNotEmpty && !height.toLowerCase().contains('cm')) {
        height += " cm";
      }
      String weight = prefs.getString('user_weight') ?? '';
      if (weight.isNotEmpty && !weight.toLowerCase().contains('kg')) {
        weight += " kg";
      }
      String extraContext = prefs.getString('user_extra_context') ?? '';

      // Construct the "User Profile" block
      String userProfile = '''
      USER PROFILE:
      - Gender: $gender
      - Height: $height
      - Weight: $weight
      - Additional Context: $extraContext
      ''';

      // Update the Prompt
      final prompt = '''
      You are Gymini, an elite strength coach.
      
      $userProfile
      
      WORKOUT HISTORY:
      $history
      
      USER QUESTION: "$userMessage"
      ''';

      final responseSchema = Schema.object(properties: {
        'response_text': Schema.string(),
        'action_type': Schema.enumString(enumValues: [
          'general_chat',
          'routine_suggestion',
          'analysis',
          'education',
          'adjustment'
        ]),
        'analysis_insight': Schema.string(),
        'actionable_advice': Schema.string(),
        'suggested_routine': Schema.array(
            items: Schema.object(properties: {
          'exercise_name': Schema.string(),
          'sets': Schema.integer(),
          'reps': Schema.integer(),
          'weight_kg': Schema.number(),
        })),
        'technique_guide': Schema.object(properties: {
          'cues': Schema.array(items: Schema.string()),
          'mistakes': Schema.array(items: Schema.string()),
        }),
        'substitution': Schema.object(properties: {
          'original_exercise': Schema.string(),
          'replacement': Schema.string(),
          'reasoning': Schema.string(),
        })
      }, requiredProperties: [
        'response_text',
        'action_type'
      ]);

      final model = GenerativeModel(
        model: _modelName,
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
          responseSchema: responseSchema,
        ),
      );

      final response = await model.generateContent([Content.text(prompt)]);

      if (response.text == null) throw "Empty response";

      return GyminiResponse.fromJson(response.text!);
    } catch (e) {
      // 3. Catch Invalid Key Errors (e.g., user typed 'abc' instead of a real key)
      if (e.toString().contains("API key not valid") ||
          e.toString().contains("403")) {
        return GyminiResponse(
            responseText:
                "⚠️ Your API Key is invalid.\n\nPlease go to Settings and ensure you copied the key correctly from Google AI Studio.",
            actionType: "general_chat");
      }

      return GyminiResponse(
          responseText: "Connection Error: $e", actionType: "general_chat");
    }
  }
}
