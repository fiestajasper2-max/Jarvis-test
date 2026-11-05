import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:jarvis/services/memory_service.dart';

class GroqService extends ChangeNotifier {
  // ============================================
  // PASTE YOUR GROQ API KEY HERE
  // Get it free at: https://console.groq.com
  // ============================================
  static const String _apiKey = 'YOUR_GROQ_API_KEY_HERE';

  static const String _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';
  static const String _model = 'llama-3.3-70b-versatile'; // Fast & good free model

  bool isLoading = false;
  String? lastError;

  final List<Map<String, String>> _conversationHistory = [];

  List<Map<String, String>> get conversationHistory => List.unmodifiable(_conversationHistory);

  // System personality prompt
  static const String _systemPrompt = '''
You are Jarvis, an advanced AI assistant inspired by the one from Iron Man.

Personality:
- Calm, collected, and friendly
- Light wit and occasional dry sarcasm
- Extremely helpful and efficient
- Speak naturally, like a real intelligent companion
- Keep responses relatively concise unless the user asks for detail
- Address the user respectfully but not stiffly

You can help with:
- Answering questions and web-related knowledge
- Remembering information the user tells you
- Controlling phone features (when the app handles it)
- Taking notes and setting reminders
- General conversation

When the user asks you to do something on the phone (open app, set alarm, take note, etc.), clearly confirm what you understood so the app can execute it.

Current date awareness: You know today's approximate date from context.
''';

  Future<String> sendMessage(String userMessage, {MemoryService? memory}) async {
    if (_apiKey == 'YOUR_GROQ_API_KEY_HERE' || _apiKey.isEmpty) {
      return "Please add your Groq API key in lib/services/groq_service.dart first.";
    }

    isLoading = true;
    lastError = null;
    notifyListeners();

    try {
      // Add long-term memory context
      String memoryContext = '';
      if (memory != null) {
        final memories = await memory.getRelevantMemories(userMessage);
        if (memories.isNotEmpty) {
          memoryContext = '\n\nRelevant things you remember about the user:\n${memories.join('\n')}';
        }
      }

      // Build messages
      final messages = [
        {
          'role': 'system',
          'content': _systemPrompt + memoryContext,
        },
        ..._conversationHistory,
        {
          'role': 'user',
          'content': userMessage,
        },
      ];

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': _model,
          'messages': messages,
          'temperature': 0.7,
          'max_tokens': 1024,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final reply = data['choices'][0]['message']['content'] as String;

        // Save to history (keep last 12 messages to stay within limits)
        _conversationHistory.add({'role': 'user', 'content': userMessage});
        _conversationHistory.add({'role': 'assistant', 'content': reply});

        if (_conversationHistory.length > 12) {
          _conversationHistory.removeRange(0, _conversationHistory.length - 12);
        }

        // Auto-save important facts to memory
        if (memory != null) {
          await memory.extractAndSaveMemories(userMessage, reply);
        }

        isLoading = false;
        notifyListeners();
        return reply;
      } else {
        lastError = 'Error ${response.statusCode}: ${response.body}';
        isLoading = false;
        notifyListeners();
        return "I'm having trouble connecting right now. Please check your internet or API key.";
      }
    } catch (e) {
      lastError = e.toString();
      isLoading = false;
      notifyListeners();
      return "Something went wrong: $e";
    }
  }

  void clearHistory() {
    _conversationHistory.clear();
    notifyListeners();
  }
}
