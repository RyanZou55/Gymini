// lib/services/providers/openai_provider.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'ai_provider_interface.dart';
import '../../models/gymini_response.dart';

class OpenAIProvider implements AIProviderInterface {
  static const String _baseUrl = 'https://api.openai.com/v1/chat/completions';

  static const String _model = 'gpt-4o-mini';
  @override
  Future<GyminiResponse> sendMessage({
    required String apiKey,
    required String history,
    required String userProfile,
    required String userMessage,
  }) async {
    // 1. Strict Schema Instruction (OpenAI requires the word "JSON" in the prompt)
    const schemaInstruction = '''
    You are a helpful assistant designed to output JSON.
    Strictly follow this schema:
    {
      "response_text": "String",
      "action_type": "String (One of: general_chat, routine_suggestion, analysis, education, adjustment)",
      "analysis_insight": "String (Optional)",
      "actionable_advice": "String (Optional)",
      "suggested_routine": [
        { "exercise_name": "String", "sets": Int, "reps": Int, "weight_kg": Double }
      ],
      "technique_guide": {
        "cues": ["String"], "mistakes": ["String"]
      },
      "substitution": {
        "original_exercise": "String", "replacement": "String", "reasoning": "String"
      }
    }
    ''';

    final messages = [
      {
        "role": "system",
        "content":
            "You are Gymini, an elite strength coach.\n$userProfile\n\nWORKOUT HISTORY:\n$history\n\nSYSTEM INSTRUCTION:\n$schemaInstruction"
      },
      {"role": "user", "content": userMessage}
    ];

    try {
      // 2. HTTP Request
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          "model": _model,
          "messages": messages,
          "temperature": 0.7,
          "response_format": {"type": "json_object"} // OpenAI Native JSON Mode
        }),
      );

      // --- DEBUG PRINT ---
      if (response.statusCode != 200) {
        print("🔴 OPENAI ERROR: ${response.statusCode}");
        print("🔴 BODY: ${response.body}");
      }

      // --- ERROR HANDLING ---
      if (response.statusCode == 401) {
        return GyminiResponse(
            responseText:
                "⚠️ OpenAI Error: Invalid API Key.\n\nPlease check your key in Settings.",
            actionType: "general_chat");
      }

      if (response.statusCode == 429) {
        return GyminiResponse(
            responseText:
                "⚠️ OpenAI Error: Rate Limit or Quota Exceeded.\n\nPlease check your usage limits on platform.openai.com.",
            actionType: "general_chat");
      }

      if (response.statusCode != 200) {
        throw "OpenAI API Error: ${response.statusCode} - ${response.body}";
      }

      // 3. Parse Response
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      final content = data['choices'][0]['message']['content'];

      return GyminiResponse.fromJson(content);
    } catch (e) {
      print("🔴 CONNECTION EXCEPTION: $e");
      throw "OpenAI Connection Failed: $e";
    }
  }
}
