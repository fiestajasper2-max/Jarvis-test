import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jarvis/widgets/holographic_orb.dart';
import 'package:jarvis/services/groq_service.dart';
import 'package:jarvis/services/speech_service.dart';
import 'package:jarvis/services/memory_service.dart';
import 'package:jarvis/services/phone_service.dart';
import 'package:permission_handler/permission_handler.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _showChat = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final speech = context.read<SpeechService>();
      await speech.init();
      await _requestPermissions();

      // Welcome message
      _addMessage(
        "Hello. I'm Jarvis. How can I help you today?",
        isUser: false,
        speak: true,
      );
    });
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.microphone,
      Permission.speech,
      Permission.notification,
    ].request();
  }

  void _addMessage(String text, {required bool isUser, bool speak = false}) {
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: isUser, time: DateTime.now()));
    });

    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    if (speak && !isUser) {
      context.read<SpeechService>().speak(text);
    }
  }

  Future<void> _handleUserInput(String text) async {
    if (text.trim().isEmpty) return;

    _textController.clear();
    _addMessage(text, isUser: true);

    // Check for phone commands first
    final handled = await _tryHandlePhoneCommand(text);
    if (handled) return;

    // Send to Groq
    final groq = context.read<GroqService>();
    final memory = context.read<MemoryService>();

    final reply = await groq.sendMessage(text, memory: memory);
    _addMessage(reply, isUser: false, speak: true);
  }

  Future<bool> _tryHandlePhoneCommand(String text) async {
    final lower = text.toLowerCase();

    // Open app
    if (lower.contains('open ') || lower.contains('launch ')) {
      final app = lower
          .replaceAll('open ', '')
          .replaceAll('launch ', '')
          .replaceAll('please', '')
          .replaceAll('jarvis', '')
          .trim();

      if (app.isNotEmpty) {
        final success = await PhoneService.openApp(app);
        final reply = success
            ? "Opening $app for you."
            : "I couldn't find or open $app. Trying the Play Store instead.";
        _addMessage(reply, isUser: false, speak: true);
        return true;
      }
    }

    // Set alarm
    if (lower.contains('set alarm') ||
        lower.contains('set an alarm') ||
        lower.contains('wake me')) {
      // Very basic parsing
      int? hour;
      int? minute;

      final timeMatch = RegExp(r'(\d{1,2})(?::(\d{2}))?\s*(am|pm)?').firstMatch(lower);
      if (timeMatch != null) {
        hour = int.tryParse(timeMatch.group(1)!);
        minute = int.tryParse(timeMatch.group(2) ?? '0');
        final period = timeMatch.group(3);

        if (period == 'pm' && hour != null && hour < 12) hour += 12;
        if (period == 'am' && hour == 12) hour = 0;
      }

      final success = await PhoneService.setAlarm(
        hour: hour,
        minute: minute,
        message: 'Jarvis Alarm',
      );

      final reply = success
          ? "Setting an alarm${hour != null ? ' for $hour:${minute.toString().padLeft(2, '0')}' : ''}."
          : "I tried to set the alarm. Please confirm in the clock app.";
      _addMessage(reply, isUser: false, speak: true);
      return true;
    }

    // Take note
    if (lower.contains('take a note') ||
        lower.contains('note that') ||
        lower.contains('write down') ||
        lower.contains('remember this note')) {
      final noteContent = text
          .replaceAll(RegExp(r'(take a note|note that|write down|remember this note)', caseSensitive: false), '')
          .trim();

      if (noteContent.isNotEmpty) {
        final success = await PhoneService.takeNote(noteContent);
        final reply = success
            ? "I've noted that down for you."
            : "I saved it in my memory instead.";
        _addMessage(reply, isUser: false, speak: true);

        // Also save to Jarvis memory
        await context.read<MemoryService>().saveMemory(noteContent, category: 'note');
        return true;
      }
    }

    return false;
  }

  void _toggleListening() async {
    final speech = context.read<SpeechService>();

    if (speech.isListening) {
      await speech.stopListening();
    } else {
      await speech.startListening(
        onResult: (text) {
          if (text.trim().isNotEmpty) {
            _handleUserInput(text);
          }
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final speech = context.watch<SpeechService>();
    final groq = context.watch<GroqService>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [
              Color(0xFF0A1628),
              Colors.black,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'JARVIS',
                      style: TextStyle(
                        color: Color(0xFF00D4FF),
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 4,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _showChat ? Icons.bubble_chart_rounded : Icons.chat_bubble_outline_rounded,
                        color: Colors.white70,
                      ),
                      onPressed: () => setState(() => _showChat = !_showChat),
                    ),
                  ],
                ),
              ),

              // Orb Section
              Expanded(
                flex: _showChat ? 2 : 5,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      HolographicOrb(
                        isListening: speech.isListening,
                        isSpeaking: speech.isSpeaking,
                        isThinking: groq.isLoading,
                        size: _showChat ? 180 : 280,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        speech.isListening
                            ? 'Listening...'
                            : speech.isSpeaking
                                ? 'Speaking...'
                                : groq.isLoading
                                    ? 'Thinking...'
                                    : 'Tap the mic or type below',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 14,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Chat section
              if (_showChat)
                Expanded(
                  flex: 4,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final msg = _messages[index];
                        return _ChatBubble(message: msg);
                      },
                    ),
                  ),
                ),

              // Input area
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                child: Row(
                  children: [
                    // Mic button
                    GestureDetector(
                      onTap: _toggleListening,
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: speech.isListening
                                ? [const Color(0xFF00D4FF), const Color(0xFF0077B6)]
                                : [const Color(0xFF1A1A2E), const Color(0xFF16213E)],
                          ),
                          boxShadow: speech.isListening
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF00D4FF).withOpacity(0.4),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                  )
                                ]
                              : null,
                        ),
                        child: Icon(
                          speech.isListening ? Icons.mic : Icons.mic_none_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Text input
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: TextField(
                          controller: _textController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: 'Talk to Jarvis...',
                            hintStyle: TextStyle(color: Colors.white38),
                            border: InputBorder.none,
                          ),
                          onSubmitted: _handleUserInput,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Send button
                    GestureDetector(
                      onTap: () => _handleUserInput(_textController.text),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF00D4FF),
                        ),
                        child: const Icon(Icons.send_rounded, color: Colors.black, size: 22),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime time;

  ChatMessage({required this.text, required this.isUser, required this.time});
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: message.isUser
              ? const Color(0xFF00D4FF).withOpacity(0.2)
              : Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(message.isUser ? 18 : 4),
            bottomRight: Radius.circular(message.isUser ? 4 : 18),
          ),
          border: Border.all(
            color: message.isUser
                ? const Color(0xFF00D4FF).withOpacity(0.3)
                : Colors.white.withOpacity(0.05),
          ),
        ),
        child: Text(
          message.text,
          style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4),
        ),
      ),
    );
  }
}
