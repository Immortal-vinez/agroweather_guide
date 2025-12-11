// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import '../services/openai_chatbot_service.dart';
import '../services/weather_service.dart';
import '../services/season_service.dart';
import '../config/env.dart';
import '../widgets/gradient_app_bar.dart';

/// AI-powered farming assistant chat screen
/// Uses OpenAI ChatGPT to answer ONLY agricultural questions
class ChatScreen extends StatefulWidget {
  final double? latitude;
  final double? longitude;
  final String? locationName;

  const ChatScreen({
    super.key,
    this.latitude,
    this.longitude,
    this.locationName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatUser _user = ChatUser(id: '1', firstName: 'You');
  final ChatUser _bot = ChatUser(
    id: '2',
    firstName: 'AgriBot',
    customProperties: {'avatar': '🌾'},
  );

  final List<ChatMessage> _messages = [];
  late OpenAIChatbotService _chatService;
  bool _isTyping = false;

  String? _currentTemp;
  String? _currentSeason;
  String? _humidity;

  @override
  void initState() {
    super.initState();
    _initializeChatService();
    _loadWeatherContext();
    _addWelcomeMessage();
  }

  void _initializeChatService() {
    try {
      final apiKey = Env.openAiApiKey;
      print('🔑 Initializing OpenAI ChatGPT chatbot...');
      print(
          '📊 API Key configured: ${apiKey.isNotEmpty ? "Yes (${apiKey.length} chars)" : "No"}');

      if (apiKey.isEmpty) {
        throw Exception('API key is empty');
      }

      _chatService = OpenAIChatbotService(apiKey);
      print('✅ Chatbot service initialized successfully');
    } catch (e) {
      print('❌ Failed to initialize chatbot: $e');
      // Show error if API key is missing
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Chat initialization failed: $e\nGet API key at platform.openai.com'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      });
    }
  }

  void _addWelcomeMessage() {
    setState(() {
      _messages.add(ChatMessage(
        text:
            '👋 Hello! I\'m AgriBot, your farming assistant powered by AI.\n\n'
            'Ask me anything about:\n'
            '• Crops and planting 🌱\n'
            '• Soil and fertilizers 🌍\n'
            '• Pests and diseases 🐛\n'
            '• Weather impacts ☁️\n'
            '• Irrigation 💧\n'
            '• Livestock 🐄\n\n'
            'How can I help you today?',
        user: _bot,
        createdAt: DateTime.now(),
      ));
    });
  }

  Future<void> _loadWeatherContext() async {
    if (widget.latitude != null && widget.longitude != null) {
      try {
        final weather = await WeatherService(
          Env.agroMonitoringApiKey,
          demoMode: !Env.hasApiKey,
        ).fetchCurrentWeather(widget.latitude!, widget.longitude!);

        final season = SeasonService().getSeasonInfo(DateTime.now());

        setState(() {
          _currentTemp = weather.temperature.toStringAsFixed(1);
          _humidity = weather.humidity.toStringAsFixed(0);
          _currentSeason = season.name;
        });
      } catch (e) {
        // Continue without weather context
        debugPrint('Could not load weather context: $e');
      }
    }
  }

  Future<void> _onSend(ChatMessage message) async {
    setState(() {
      _messages.insert(0, message);
      _isTyping = true;
    });

    try {
      final response = await _chatService.sendMessage(
        userMessage: message.text,
        currentTemp: _currentTemp,
        currentSeason: _currentSeason,
        humidity: _humidity,
        locationName: widget.locationName,
      );

      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.insert(
            0,
            ChatMessage(
              text: response,
              user: _bot,
              createdAt: DateTime.now(),
            ),
          );
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.insert(
            0,
            ChatMessage(
              text: 'Sorry, I encountered an error. Please try again.',
              user: _bot,
              createdAt: DateTime.now(),
            ),
          );
        });
      }
    }
  }

  void _clearChat() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Chat'),
        content: const Text('Are you sure you want to clear the conversation?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _messages.clear();
                _chatService.resetChat();
              });
              _addWelcomeMessage();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD),
      appBar: GradientAppBar(
        title: const Row(
          children: [
            Text('🌾 AgriBot', style: TextStyle(fontSize: 20)),
            SizedBox(width: 8),
            Icon(LucideIcons.sparkles, size: 18),
          ],
        ),
        actions: [
          // Quick suggestions button
          IconButton(
            icon: const Icon(LucideIcons.lightbulb),
            onPressed: _showQuickSuggestions,
            tooltip: 'Quick Questions',
          ),
          // Clear chat button
          IconButton(
            icon: const Icon(LucideIcons.trash2),
            onPressed: _clearChat,
            tooltip: 'Clear Chat',
          ),
        ],
      ),
      body: Column(
        children: [
          // Context info banner (if available)
          if (_currentTemp != null || _currentSeason != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.green.shade50,
              child: Row(
                children: [
                  const Icon(LucideIcons.info,
                      size: 16, color: Color(0xFF4CAF50)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Context: ${widget.locationName ?? "Unknown"} • '
                      '${_currentTemp ?? "N/A"}°C • '
                      '${_currentSeason ?? "Unknown"} season',
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF2E7D32)),
                    ),
                  ),
                ],
              ),
            ),
          // Chat interface
          Expanded(
            child: DashChat(
              currentUser: _user,
              messages: _messages,
              onSend: _onSend,
              typingUsers: _isTyping ? [_bot] : [],
              messageOptions: MessageOptions(
                currentUserContainerColor: const Color(0xFF4CAF50),
                containerColor: Colors.white,
                textColor: Colors.black87,
                showTime: true,
                showOtherUsersAvatar: true,
                showCurrentUserAvatar: false,
                avatarBuilder: (user, onPress, onLongPress) {
                  if (user.id == _bot.id) {
                    return Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text('🌾', style: TextStyle(fontSize: 24)),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              inputOptions: InputOptions(
                inputDecoration: InputDecoration(
                  hintText: 'Ask about farming...',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                ),
                sendButtonBuilder: (onSend) => Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: CircleAvatar(
                    backgroundColor: const Color(0xFF4CAF50),
                    child: IconButton(
                      icon: const Icon(
                        LucideIcons.send,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: onSend,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showQuickSuggestions() {
    final suggestions = [
      '🌽 What crops are best for this season?',
      '🐛 How do I control pests naturally?',
      '💧 Best irrigation practices?',
      '🌱 When should I plant maize?',
      '🌾 How to improve soil fertility?',
      '☁️ How does weather affect my crops?',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Quick Questions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ...suggestions.map((suggestion) => ListTile(
                    leading: const Icon(
                      LucideIcons.messageSquare,
                      color: Color(0xFF4CAF50),
                    ),
                    title: Text(
                      suggestion,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _onSend(ChatMessage(
                        text: suggestion.substring(2), // Remove emoji
                        user: _user,
                        createdAt: DateTime.now(),
                      ));
                    },
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
