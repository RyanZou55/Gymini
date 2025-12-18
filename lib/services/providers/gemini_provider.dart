// lib/services/providers/gemini_provider.dart
import 'package:google_generative_ai/google_generative_ai.dart';
import 'ai_provider_interface.dart';
import '../../models/gymini_response.dart';

class GeminiProvider implements AIProviderInterface {
  static const String _modelName = 'gemini-flash-latest';

  @override
  Future<GyminiResponse> sendMessage({
    required String apiKey,
    required String history,
    required String userProfile,
    required String userMessage,
  }) async {
    // 1. Build the specific Gemini Prompt
    final prompt = '''
    You are Gymini, an elite strength coach.
    
    $userProfile
    
    WORKOUT HISTORY:
    $history
    
    USER QUESTION: "$userMessage"
    ''';

    // 2. Define Schema (Gemini specific structure)
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

    // 3. Call the API
    try {
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
      // Pass the error up to the manager to handle
      throw e;
    }
  }
}
