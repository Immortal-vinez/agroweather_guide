// ignore_for_file: avoid_print

import 'package:dart_openai/dart_openai.dart';

/// Service for AI-powered farming assistant using OpenAI ChatGPT
/// Restricted to answer ONLY agricultural questions
class OpenAIChatbotService {
  final String apiKey;
  final List<OpenAIChatCompletionChoiceMessageModel> _conversationHistory = [];

  OpenAIChatbotService(this.apiKey) {
    if (apiKey.isEmpty) {
      throw Exception('OpenAI API key is required');
    }

    print('🤖 Initializing OpenAI ChatGPT...');
    OpenAI.apiKey = apiKey;

    // Add system message for agricultural focus
    _conversationHistory.add(
      OpenAIChatCompletionChoiceMessageModel(
        role: OpenAIChatMessageRole.system,
        content: [
          OpenAIChatCompletionChoiceMessageContentItemModel.text(
            _buildSystemPrompt(),
          ),
        ],
      ),
    );

    print('✅ OpenAI chatbot service initialized successfully');
  }

  /// Build system prompt that restricts responses to farming topics only
  String _buildSystemPrompt() {
    return '''You are AgriBot, an expert agricultural assistant for farmers in Zambia and Africa.

STRICT RULES - YOU MUST FOLLOW THESE:
1. ONLY answer questions related to:
   ✓ Crop cultivation, planting, harvesting, crop rotation
   ✓ Weather and climate impacts on farming
   ✓ Soil management, fertilization, composting
   ✓ Pest control and disease management
   ✓ Irrigation and water management
   ✓ Farm equipment, tools, and machinery
   ✓ Agricultural best practices and techniques
   ✓ Livestock and animal husbandry
   ✓ Organic and sustainable farming
   ✓ Seeds, varieties, and breeding
   ✓ Post-harvest handling and storage
   ✓ Agricultural economics and markets

2. If asked about ANY non-farming topic (sports, entertainment, politics, technology not related to farming, etc.), respond EXACTLY:
   "I'm specialized in agricultural assistance only. Please ask me about farming, crops, weather, soil, livestock, or agricultural practices!"

3. Keep responses concise (2-4 paragraphs maximum)
4. Use simple, clear language suitable for farmers
5. Prioritize practical, actionable advice
6. When possible, reference African farming conditions and Zambian context
7. Include specific numbers, measurements, and timeframes when relevant

Your goal is to help farmers improve their yields, manage resources efficiently, and solve agricultural problems.''';
  }

  /// Send a message and get farming-focused response
  Future<String> sendMessage({
    required String userMessage,
    String? currentTemp,
    String? currentSeason,
    String? humidity,
    String? locationName,
  }) async {
    try {
      print(
          '💬 Sending message to OpenAI: "${userMessage.substring(0, userMessage.length > 50 ? 50 : userMessage.length)}..."');

      // Add context information if available
      String contextualMessage = userMessage;

      if (currentTemp != null || currentSeason != null || humidity != null) {
        final contextParts = <String>[];
        if (locationName != null) contextParts.add('Location: $locationName');
        if (currentTemp != null) {
          contextParts.add('Temperature: $currentTemp°C');
        }
        if (currentSeason != null) contextParts.add('Season: $currentSeason');
        if (humidity != null) contextParts.add('Humidity: $humidity%');

        if (contextParts.isNotEmpty) {
          contextualMessage =
              '[Current conditions: ${contextParts.join(', ')}]\n\n$userMessage';
          print('📍 Added context: ${contextParts.join(', ')}');
        }
      }

      // Add user message to history
      _conversationHistory.add(
        OpenAIChatCompletionChoiceMessageModel(
          role: OpenAIChatMessageRole.user,
          content: [
            OpenAIChatCompletionChoiceMessageContentItemModel.text(
              contextualMessage,
            ),
          ],
        ),
      );

      // Send request to OpenAI
      final chatCompletion = await OpenAI.instance.chat.create(
        model: 'gpt-3.5-turbo',
        messages: _conversationHistory,
        temperature: 0.7,
        maxTokens: 500,
      );

      final responseText =
          chatCompletion.choices.first.message.content?.first.text;

      if (responseText == null || responseText.isEmpty) {
        print('⚠️ OpenAI returned empty response');
        return 'Sorry, I couldn\'t generate a response. Please try again.';
      }

      // Add assistant response to history
      _conversationHistory.add(chatCompletion.choices.first.message);

      print('✅ Received response from OpenAI (${responseText.length} chars)');
      return responseText.trim();
    } catch (e) {
      print('❌ Error in sendMessage: $e');

      // Handle specific errors
      if (e.toString().contains('API key')) {
        return 'Chat feature requires valid API configuration. Please check your API key.';
      } else if (e.toString().contains('rate limit') ||
          e.toString().contains('quota')) {
        return 'Too many requests. Please wait a moment and try again.';
      } else if (e.toString().contains('network') ||
          e.toString().contains('connection')) {
        return 'Network error. Please check your internet connection and try again.';
      } else if (e.toString().contains('401') ||
          e.toString().contains('unauthorized')) {
        return 'Invalid API key. Please verify your OpenAI API key at platform.openai.com';
      }

      return 'Sorry, I encountered an error: ${e.toString().substring(0, e.toString().length > 100 ? 100 : e.toString().length)}';
    }
  }

  /// Create a new chat session (clears history)
  void resetChat() {
    _conversationHistory.clear();

    // Re-add system message
    _conversationHistory.add(
      OpenAIChatCompletionChoiceMessageModel(
        role: OpenAIChatMessageRole.system,
        content: [
          OpenAIChatCompletionChoiceMessageContentItemModel.text(
            _buildSystemPrompt(),
          ),
        ],
      ),
    );
  }

  /// Get chat history length
  int get historyLength => _conversationHistory.length;
}
