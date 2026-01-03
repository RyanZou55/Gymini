// lib/providers/chat_provider.dart
import 'package:flutter/material.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import '../services/ai_service.dart';
import '../models/gymini_response.dart';

class ChatProvider extends ChangeNotifier {
  final AIService _aiService = AIService();

  List<ChatMessage> _messages = [];
  bool _isTyping = false;

  List<ChatMessage> get messages => _messages;
  bool get isTyping => _isTyping;

  final ChatUser _gymini = ChatUser(id: '2', firstName: 'Gymini Coach');

  ChatProvider() {
    _messages.add(
      ChatMessage(
        text: "I'm connected to your records. Ask me anything!",
        user: _gymini,
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<void> sendMessage(ChatMessage userMessage) async {
    _messages.insert(0, userMessage);
    _isTyping = true;
    notifyListeners();

    try {
      GyminiResponse response = await _aiService.sendMessage(userMessage.text);

      // --- CRITICAL FIX START ---
      // We must convert the Objects back into Maps so the UI can read them as JSON.

      // 1. Convert Routine List
      List<Map<String, dynamic>>? routineMap;
      if (response.suggestedRoutine != null) {
        routineMap = response.suggestedRoutine!
            .map((e) => {
                  'exercise_name': e.name,
                  'sets': e.sets,
                  'reps': e.reps,
                  'weight_kg': e.weight
                })
            .toList();
      }

      // 2. Convert Technique Guide
      Map<String, dynamic>? techniqueMap;
      if (response.techniqueGuide != null) {
        techniqueMap = {
          'cues': response.techniqueGuide!.cues,
          'mistakes': response.techniqueGuide!.mistakes,
        };
      }

      // 3. Convert Substitution
      Map<String, dynamic>? subMap;
      if (response.substitution != null) {
        subMap = {
          'original_exercise': response.substitution!.original,
          'replacement': response.substitution!.replacement,
          'reasoning': response.substitution!.reason,
        };
      }

      // 4. Pack it all into properties
      Map<String, dynamic> properties = {
        'action_type': response.actionType,
        'analysis_insight': response.analysisInsight,
        'actionable_advice': response.actionableAdvice,
        'suggested_routine': routineMap, // Pass the MAP, not the Object
        'technique_guide': techniqueMap, // Pass the MAP, not the Object
        'substitution': subMap, // Pass the MAP, not the Object
      };
      // --- CRITICAL FIX END ---

      final aiMessage = ChatMessage(
        text: response.responseText,
        user: _gymini,
        createdAt: DateTime.now(),
        customProperties: properties,
      );

      _messages.insert(0, aiMessage);
    } catch (e) {
      _messages.insert(
          0,
          ChatMessage(
            text: "Error: $e",
            user: _gymini,
            createdAt: DateTime.now(),
          ));
    } finally {
      _isTyping = false;
      notifyListeners();
    }
  }
}
