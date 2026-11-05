import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

class SpeechService extends ChangeNotifier {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();

  bool isListening = false;
  bool isSpeaking = false;
  bool isAvailable = false;
  String lastWords = '';

  Future<void> init() async {
    isAvailable = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          isListening = false;
          notifyListeners();
        }
      },
      onError: (error) {
        isListening = false;
        notifyListeners();
      },
    );

    // TTS settings
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.48); // Calm pace
    await _tts.setVolume(1.0);
    await _tts.setPitch(0.95);

    _tts.setStartHandler(() {
      isSpeaking = true;
      notifyListeners();
    });

    _tts.setCompletionHandler(() {
      isSpeaking = false;
      notifyListeners();
    });

    _tts.setErrorHandler((msg) {
      isSpeaking = false;
      notifyListeners();
    });

    notifyListeners();
  }

  Future<void> startListening({required Function(String) onResult}) async {
    if (!isAvailable || isListening) return;

    isListening = true;
    lastWords = '';
    notifyListeners();

    await _speech.listen(
      onResult: (result) {
        lastWords = result.recognizedWords;
        notifyListeners();
        if (result.finalResult) {
          onResult(lastWords);
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 4),
      partialResults: true,
      localeId: 'en_US',
      cancelOnError: true,
      listenMode: stt.ListenMode.confirmation,
    );
  }

  Future<void> stopListening() async {
    await _speech.stop();
    isListening = false;
    notifyListeners();
  }

  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;

    // Stop listening while speaking
    if (isListening) await stopListening();

    await _tts.speak(text);
  }

  Future<void> stopSpeaking() async {
    await _tts.stop();
    isSpeaking = false;
    notifyListeners();
  }

  void disposeServices() {
    _speech.cancel();
    _tts.stop();
  }
}
