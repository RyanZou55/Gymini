import 'package:google_generative_ai/google_generative_ai.dart';
import 'database_service.dart';
import '../models/gymini_response.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AIService {
  // Read from .env file
  static String? get _apiKey => dotenv.env['GEMINI_API_KEY'];

  // 'flash' is faster, cheaper, and smarter at JSON than 'pro'
  static const String _modelName = 'gemini-flash-latest';

  final DatabaseService _dbService = DatabaseService();

  Future<GyminiResponse> sendMessage(String userMessage) async {
    // Safety Check
    if (_apiKey == null || _apiKey!.isEmpty) {
      return GyminiResponse(
          responseText: "System Error: API Key missing in .env file.",
          actionType: "general_chat");
    }

    try {
      String history = await _dbService.getContextForAI();

      // --- MASTER SCHEMA ---
      final responseSchema = Schema.object(properties: {
        'response_text': Schema.string(description: "Conversational answer."),
        'action_type': Schema.enumString(enumValues: [
          'general_chat',
          'routine_suggestion',
          'analysis',
          'education',
          'adjustment'
        ], description: "Type of response."),
        'analysis_insight': Schema.string(
            description: "The underlying problem/pattern identified."),
        'actionable_advice':
            Schema.string(description: "The specific solution."),
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
        apiKey: _apiKey!,
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
          responseSchema: responseSchema,
        ),
      );

      final prompt = '''
      You are Gymini, an elite strength coach.
      
      CONTEXT:
      $history
      
      USER QUESTION: "$userMessage"
      ''';

      final response = await model.generateContent([Content.text(prompt)]);

      if (response.text == null) throw "Empty response";

      return GyminiResponse.fromJson(response.text!);
    } catch (e) {
      print("AI Error: $e");

      // Fallback if context is somehow TOO massive (rare with Flash model)
      if (e.toString().contains('400')) {
        return GyminiResponse(
            responseText:
                "My memory is a bit full. I'll read just the recent logs next time.",
            actionType: "general_chat");
      }

      return GyminiResponse(
          responseText: "System Error: $e", actionType: "general_chat");
    }
  }
}
