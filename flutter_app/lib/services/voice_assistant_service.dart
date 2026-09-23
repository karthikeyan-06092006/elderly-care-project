import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'api_service.dart';
import 'offline_assistant_engine.dart';

enum AssistantState { idle, listening, thinking, speaking }

class VoiceAssistantService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  final OfflineAssistantEngine engine = OfflineAssistantEngine();

  bool _initialized = false;
  bool _speechListening = false;
  bool _speaking = false;
  bool _processing = false;
  bool _waitingForSpeechResult = false;

  AssistantState _state = AssistantState.idle;
  AssistantState get state => _state;

  String _lastTranscript = '';
  String get lastTranscript => _lastTranscript;

  String _lastReply = '';
  String get lastReply => _lastReply;

  String _language = 'en';
  String get language => _language;
  final List<String> _messages = [];
  String? lastSpeechError;

  dynamic Function(AssistantState state)? onStateChanged;
  dynamic Function(String transcript, bool isFinal)? onTranscript;
  dynamic Function(String reply, String intent)? onReply;

  Future<bool> ensureInitialized({String language = 'en'}) async {
    _language = language;
    engine.setLanguage(language);
    try {
      if (!_initialized) {
        _initialized = await _speech.initialize(
          onStatus: (status) {
            debugPrint('[Voice] status: $status');
            if (status == 'done' || status == 'notListening') {
              if (_waitingForSpeechResult) {
                _waitingForSpeechResult = false;
                _stopListening();
              }
            }
          },
          onError: (error) {
            debugPrint('[Voice] error: ${error.errorMsg}');
            _setState(AssistantState.idle);
          },
        );
      }
      if (!_initialized) return false;
      await _initTts();
      return true;
    } catch (e) {
      debugPrint('[Voice] init failed: $e');
      return false;
    }
  }

  Future<void> _initTts() async {
    try {
      await _tts.setLanguage(_language == 'bn' ? 'bn-BD' : 'en-US');
      await _tts.setSpeechRate(0.42);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
    } catch (e) {
      debugPrint('[Voice] tts init: $e');
    }
  }

  void _setState(AssistantState s) {
    _state = s;
    onStateChanged?.call(s);
  }

  void setUserName(String name) {
    engine.setUserName(name);
  }

  Future<void> startListening() async {
    if (_speaking) return;
    if (_processing) return;
    final ok = await ensureInitialized(language: _language);
    if (!ok) {
      _emitConversation('', engine.language == 'en'
          ? 'I could not start voice recognition on this device.'
          : 'ভয়েস রিকগনিশন শুরু করা যায়নি।');
      return;
    }
    _lastTranscript = '';
    _waitingForSpeechResult = true;
    _setState(AssistantState.listening);
    try {
      await _speech.listen(
        onResult: (result) {
          _lastTranscript = result.recognizedWords;
          onTranscript?.call(result.recognizedWords, result.finalResult);
          if (result.finalResult) {
            _waitingForSpeechResult = false;
            _stopListening();
            if (_lastTranscript.trim().isNotEmpty) {
              _handleUserText(_lastTranscript);
            }
          }
        },
        listenOptions: stt.SpeechListenOptions(
          partialResults: true,
          cancelOnError: true,
          listenMode: stt.ListenMode.dictation,
          listenFor: const Duration(seconds: 12),
          pauseFor: const Duration(seconds: 3),
          localeId: _language == 'bn' ? 'bn-BD' : 'en-US',
        ),
      );
      _speechListening = true;
    } catch (e) {
      debugPrint('[Voice] listen failed: $e');
      _waitingForSpeechResult = false;
      _setState(AssistantState.idle);
    }
  }

  void _stopListening() {
    if (!_speechListening) return;
    _speechListening = false;
    try {
      _speech.stop();
    } catch (_) {}
  }

  Future<void> stopListening() async {
    _waitingForSpeechResult = false;
    _stopListening();
    if (_state == AssistantState.listening) _setState(AssistantState.idle);
    if (_lastTranscript.trim().isNotEmpty) {
      await _handleUserText(_lastTranscript);
    } else if (_state != AssistantState.thinking && _state != AssistantState.speaking) {
      _setState(AssistantState.idle);
    }
  }

  Future<void> _handleUserText(String text) async {
    _processing = true;
    _setState(AssistantState.thinking);
    _messages.add(text);

    final engineReply = engine.reply(text);
    var reply = engineReply.reply;
    final intent = engineReply.intent;
    final action = engineReply.action;

    final apiReply = await ApiService.aiChat(
      userText: text,
      language: _language,
      patientName: engine.userName,
    );
    if (apiReply != null && apiReply.trim().isNotEmpty) {
      reply = apiReply;
    }

    _lastReply = reply;
    onReply?.call(reply, intent);
    _messages.add(reply);
    _processing = false;

    if (action == 'sos') {
      _emitConversation(reply, reply);
    }

    _setState(AssistantState.speaking);
    await _speak(reply);
    _setState(AssistantState.idle);
  }

  Future<void> _speak(String text) async {
    if (_speaking) return;
    _speaking = true;
    try {
      await _tts.stop();
      await _tts.awaitSpeakCompletion(true);
      await _tts.speak(text);
    } catch (e) {
      debugPrint('[Voice] speak error: $e');
    } finally {
      _speaking = false;
    }
  }

  void _emitConversation(String transcript, String reply) {
    onTranscript?.call(transcript, true);
    onReply?.call(reply, '_empty');
  }

  Future<void> greet() async {
    final ok = await ensureInitialized(language: _language);
    if (!ok) return;
    final greeting = engine.welcome;
    _lastReply = greeting;
    onReply?.call(greeting, 'greeting');
    _setState(AssistantState.speaking);
    await _speak(greeting);
    _setState(AssistantState.idle);
  }

  Future<void> speakText(String text) async {
    final ok = await ensureInitialized(language: _language);
    if (!ok) return;
    _setState(AssistantState.speaking);
    await _speak(text);
    _setState(AssistantState.idle);
  }

  Future<void> dispose() async {
    try {
      _stopListening();
      await _tts.stop();
      await _speech.cancel();
    } catch (_) {}
  }
}