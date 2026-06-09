import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../services/api_service.dart';
import '../../routes/routes.dart';

enum VoiceState { idle, listening, thinking, speaking }

class VoiceController extends GetxController {
  final ApiService _apiService = ApiService();
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();

  // Observable states
  final voiceState = VoiceState.idle.obs;
  final userTranscript = "".obs;
  final aiTranscript = "".obs;
  final apiMessage = "".obs;

  // For compatibility/convenience in UI
  final isLoading = false.obs;
  final isListening = false.obs;

  bool _speechEnabled = false;
  StreamSubscription? _apiStreamSubscription;
  final List<String> _speechQueue = <String>[];
  bool _isTtsSpeaking = false;
  String _ttsBuffer = "";
  bool _streamFinished = false;

  // Suggestions for starting screen
  final List<String> suggestions = [
    "Tell me about Inurum Technologies",
    "What services does Inurum offer?",
    "How can AI help my business?",
    "Mobile app development solutions",
    "Custom software development services",
    "Cloud and backend development expertise",
    "AI and machine learning solutions",
    "Technology consulting and support",
  ];

  @override
  void onInit() {
    super.onInit();
    _initVoice();
    loadData();
  }

  Future<void> loadData() async {
    try {
      apiMessage.value = await _apiService.test();
      print("API Response: ${apiMessage.value}");
    } catch (e) {
      print("Error loading api test: $e");
    }
  }

  Future<void> _initVoice() async {
    try {
      _speechEnabled = await _speechToText.initialize(
        onStatus: (status) {
          print("STT Status: $status");
          if (status == 'done' || status == 'notListening') {
            // Check if we finished listening and didn't trigger query yet
            if (voiceState.value == VoiceState.listening) {
              stopListeningAndQuery();
            }
          }
        },
        onError: (errorNotification) {
          print("STT Error: $errorNotification");
          // Reset to idle on error
          if (voiceState.value == VoiceState.listening) {
            voiceState.value = VoiceState.idle;
            isListening.value = false;
          }
        },
      );

      // Initialize TTS
      await _flutterTts.setLanguage("en-US");
      await _flutterTts.setSpeechRate(0.5); // natural speaking speed
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      _flutterTts.setCompletionHandler(() {
        print("TTS speech block completed");
        _isTtsSpeaking = false;
        _processSpeechQueue();
      });

      _flutterTts.setErrorHandler((msg) {
        print("TTS Error: $msg");
        _isTtsSpeaking = false;
        _processSpeechQueue();
      });
    } catch (e) {
      print("Error initializing voice services: $e");
    }
  }

  // Toggle voice assistant action
  void toggleListening() {
    if (voiceState.value == VoiceState.listening) {
      stopListeningAndQuery();
    } else if (voiceState.value == VoiceState.thinking || voiceState.value == VoiceState.speaking) {
      stopSpeechAndStream();
    } else {
      startListening();
    }
  }

  // Start recording voice input
  void startListening() async {
    // Make sure initialized
    if (!_speechEnabled) {
      await _initVoice();
    }

    if (_speechEnabled) {
      userTranscript.value = "";
      aiTranscript.value = "";
      voiceState.value = VoiceState.listening;
      isListening.value = true;
      isLoading.value = false;

      // Stop any ongoing speech first
      await _flutterTts.stop();
      _isTtsSpeaking = false;
      _speechQueue.clear();
      _ttsBuffer = "";

      await _speechToText.listen(
        onResult: (result) {
          userTranscript.value = result.recognizedWords;
          if (result.finalResult) {
            stopListeningAndQuery();
          }
        },
        listenFor: const Duration(seconds: 20),
        pauseFor: const Duration(seconds: 4),
      );
    } else {
      Get.snackbar(
        "Microphone Required",
        "Could not initialize speech recognition services. Please ensure permissions are granted.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent.withOpacity(0.8),
        colorText: Colors.white,
      );
    }
  }

  // Stop recording and send query
  void stopListeningAndQuery() async {
    if (voiceState.value == VoiceState.listening) {
      await _speechToText.stop();
      isListening.value = false;
      
      final query = userTranscript.value.trim();
      if (query.isNotEmpty) {
        sendVoiceQuery(query);
      } else {
        voiceState.value = VoiceState.idle;
      }
    }
  }

  // Stop ongoing API stream & TTS playback and reset to idle
  void stopSpeechAndStream() async {
    if (_apiStreamSubscription != null) {
      await _apiStreamSubscription!.cancel();
      _apiStreamSubscription = null;
    }

    await _flutterTts.stop();
    _isTtsSpeaking = false;

    _speechQueue.clear();
    _ttsBuffer = "";
    _streamFinished = false;

    voiceState.value = VoiceState.idle;
    isListening.value = false;
    isLoading.value = false;
  }

  // Send voice query to streaming API
  Future<void> sendVoiceQuery(String query) async {
    voiceState.value = VoiceState.thinking;
    isLoading.value = true;
    aiTranscript.value = "";
    _speechQueue.clear();
    _ttsBuffer = "";
    _isTtsSpeaking = false;
    _streamFinished = false;

    try {
      _apiStreamSubscription = await _apiService.askAiStream(
        query,
        onChunk: (chunk) {
          isLoading.value = false;
          voiceState.value = VoiceState.speaking;
          aiTranscript.value += chunk;

          // Process speech sentence buffering
          _ttsBuffer += chunk;
          _extractSentencesAndQueue();
        },
        onDone: () {
          _streamFinished = true;
          isLoading.value = false;

          // Queue remaining buffer
          final remaining = _ttsBuffer.trim();
          if (remaining.isNotEmpty) {
            _speechQueue.add(remaining);
            _ttsBuffer = "";
          }
          _processSpeechQueue();
        },
        onError: (error) {
          isLoading.value = false;
          voiceState.value = VoiceState.idle;
          aiTranscript.value = "Error: $error";
        },
      );
    } catch (e) {
      isLoading.value = false;
      voiceState.value = VoiceState.idle;
      aiTranscript.value = "Exception: $e";
    }
  }

  // Extract completed sentences from stream buffer
  void _extractSentencesAndQueue() {
    // Pattern matches ending in punctuation followed by space/end
    final RegExp sentenceRegex = RegExp(r'[^.!?\n]+[.!?\n](\s|$)');
    final Iterable<RegExpMatch> matches = sentenceRegex.allMatches(_ttsBuffer);

    if (matches.isNotEmpty) {
      int lastMatchEnd = 0;
      for (final match in matches) {
        final sentence = match.group(0)?.trim();
        if (sentence != null && sentence.isNotEmpty) {
          _speechQueue.add(sentence);
        }
        lastMatchEnd = match.end;
      }

      if (lastMatchEnd > 0) {
        _ttsBuffer = _ttsBuffer.substring(lastMatchEnd);
      }

      _processSpeechQueue();
    }
  }

  // Process and speak sentences in queue sequentially
  void _processSpeechQueue() async {
    if (_isTtsSpeaking) return;

    if (_speechQueue.isEmpty) {
      if (_streamFinished) {
        voiceState.value = VoiceState.idle;
      }
      return;
    }

    _isTtsSpeaking = true;
    voiceState.value = VoiceState.speaking;
    final sentence = _speechQueue.removeAt(0);
    print("TTS Speaking: $sentence");
    await _flutterTts.speak(sentence);
  }

  // Tap suggestions in UI
  void selectSuggestion(String suggestionText) {
    userTranscript.value = suggestionText;
    sendVoiceQuery(suggestionText);
  }

  // Navigate to text chat screen
  void navigateToChat() {
    // Stop any ongoing speech before switching screen
    stopSpeechAndStream();
    Get.toNamed(Routes.chatScreen);
  }

  @override
  void onClose() {
    _flutterTts.stop();
    _speechToText.stop();
    _apiStreamSubscription?.cancel();
    super.onClose();
  }
}
