import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

class MemoryService extends ChangeNotifier {
  static const String _boxName = 'jarvis_memories';
  static Box? _box;
  final _uuid = const Uuid();

  static Future<void> init() async {
    _box = await Hive.openBox(_boxName);
  }

  // Save a memory
  Future<void> saveMemory(String content, {String? category}) async {
    if (_box == null) return;

    final memory = {
      'id': _uuid.v4(),
      'content': content,
      'category': category ?? 'general',
      'createdAt': DateTime.now().toIso8601String(),
      'lastAccessed': DateTime.now().toIso8601String(),
    };

    await _box!.put(memory['id'], memory);
    notifyListeners();
  }

  // Get all memories
  List<Map> getAllMemories() {
    if (_box == null) return [];
    return _box!.values.cast<Map>().toList()
      ..sort((a, b) => (b['createdAt'] as String).compareTo(a['createdAt'] as String));
  }

  // Simple relevance: keyword matching (good enough for free local version)
  Future<List<String>> getRelevantMemories(String query) async {
    if (_box == null) return [];

    final queryLower = query.toLowerCase();
    final keywords = queryLower.split(RegExp(r'\s+')).where((w) => w.length > 3).toList();

    final all = getAllMemories();
    final relevant = <String>[];

    for (final mem in all) {
      final content = (mem['content'] as String).toLowerCase();
      int score = 0;
      for (final kw in keywords) {
        if (content.contains(kw)) score++;
      }
      if (score > 0 || content.contains(queryLower)) {
        relevant.add(mem['content'] as String);
      }
    }

    // Return top 5
    return relevant.take(5).toList();
  }

  // Very simple extraction: if user says "remember that..." or similar
  Future<void> extractAndSaveMemories(String userMessage, String aiReply) async {
    final lower = userMessage.toLowerCase();

    // Explicit remember commands
    if (lower.contains('remember that') ||
        lower.contains('remember this') ||
        lower.contains('don\'t forget') ||
        lower.contains('my name is') ||
        lower.contains('i am') ||
        lower.contains('i like') ||
        lower.contains('i hate') ||
        lower.contains('i live')) {
      // Save the user message as memory
      await saveMemory(userMessage);
    }

    // Also save short clear facts
    if (userMessage.length < 120 && 
        (lower.contains('my') || lower.contains('i '))) {
      // Heuristic: personal statements
      await saveMemory(userMessage, category: 'personal');
    }
  }

  Future<void> deleteMemory(String id) async {
    if (_box == null) return;
    await _box!.delete(id);
    notifyListeners();
  }

  Future<void> clearAllMemories() async {
    if (_box == null) return;
    await _box!.clear();
    notifyListeners();
  }
}
