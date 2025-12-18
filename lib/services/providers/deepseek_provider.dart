import 'ai_provider_interface.dart';
import '../../models/gymini_response.dart';

class DeepSeekProvider implements AIProviderInterface {
  @override
  Future<GyminiResponse> sendMessage({
    required String apiKey,
    required String history,
    required String userProfile,
    required String userMessage,
  }) async {
    // Placeholder implementation
    return GyminiResponse(
      responseText:
          "🚧 DeepSeek support is coming soon! Please switch back to Gemini in Settings.",
      actionType: "general_chat",
    );
  }
}
