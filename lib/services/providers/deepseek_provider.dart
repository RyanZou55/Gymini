// lib/services/providers/deepseek_provider.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'ai_provider_interface.dart';
import '../../models/gymini_response.dart';

class DeepSeekProvider implements AIProviderInterface {
  static const String _baseUrl = 'https://api.deepseek.com/chat/completions';
  static const String _model = 'deepseek-chat';

  @override
  Future<GyminiResponse> sendMessage({
    required String apiKey,
    required String history,
    required String userProfile,
    required String userMessage,
  }) async {
    const schemaInstruction = '''
    You must respond PURELY in JSON format. Do not add markdown like ```json.
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
          "response_format": {"type": "json_object"}
        }),
      );

      // --- DEBUG PRINT ---
      if (response.statusCode != 200) {
        print("🔴 DEEPSEEK ERROR: ${response.statusCode}");
        print("🔴 BODY: ${response.body}");
      }

      // --- ERROR HANDLING ---
      if (response.statusCode == 402) {
        return GyminiResponse(
            responseText:
                "⚠️ DeepSeek Error: Insufficient Balance.\n\nPlease log in to platform.deepseek.com and top up your account credits.",
            actionType: "general_chat");
      }

      if (response.statusCode != 200) {
        throw "DeepSeek API Error: ${response.statusCode} - ${response.body}";
      }

      final data = jsonDecode(utf8.decode(response.bodyBytes));
      String content = data['choices'][0]['message']['content'];

      content = content.replaceAll('```json', '').replaceAll('```', '').trim();

      return GyminiResponse.fromJson(content);
    } catch (e) {
      print("🔴 CONNECTION EXCEPTION: $e"); // Print to terminal
      throw "DeepSeek Connection Failed: $e";
    }
  }
}
