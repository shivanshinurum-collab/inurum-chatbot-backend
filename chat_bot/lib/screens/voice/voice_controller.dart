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
  String _currentPending = "";

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
    } else if (voiceState.value == VoiceState.thinking ||
        voiceState.value == VoiceState.speaking) {
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
      _currentPending = "";

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
    _currentPending = "";
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
    _currentPending = "";
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

          // Queue remaining buffer + pending abbreviations/list markers
          final remaining = (_currentPending + _ttsBuffer).trim();
          if (remaining.isNotEmpty) {
            final cleanRemaining = _cleanTextForTts(remaining);
            if (cleanRemaining.isNotEmpty) {
              _speechQueue.add(cleanRemaining);
            }
            _ttsBuffer = "";
            _currentPending = "";
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
    // Pattern matches ending in punctuation followed by space OR newlines
    // If stream is not finished, we only split on punctuation followed by space or newline, NOT the end of buffer.
    final RegExp sentenceRegex = _streamFinished
        ? RegExp(r'[^.!?\n]+([.!?](\s+|$)\n?)')
        : RegExp(r'[^.!?\n]+([.!?]\s+|\n)');

    final Iterable<RegExpMatch> matches = sentenceRegex.allMatches(_ttsBuffer);

    if (matches.isNotEmpty) {
      int lastMatchEnd = 0;
      for (final match in matches) {
        final sentence = match.group(0) ?? "";
        final trimmed = sentence.trim();

        // Check if this trimmed sentence is an abbreviation or numbered list item
        // e.g. "1.", "Dr.", "Mr."
        if (_isAbbreviationOrListMarker(trimmed)) {
          _currentPending += sentence;
          lastMatchEnd = match.end;
          continue;
        }

        // If we have pending text, prepend it to the current sentence
        final fullSentence = (_currentPending + sentence).trim();
        _currentPending = "";

        if (fullSentence.isNotEmpty) {
          final cleanSentence = _cleanTextForTts(fullSentence);
          if (cleanSentence.isNotEmpty) {
            _speechQueue.add(cleanSentence);
          }
        }
        lastMatchEnd = match.end;
      }

      if (lastMatchEnd > 0) {
        _ttsBuffer = _ttsBuffer.substring(lastMatchEnd);
      }

      _processSpeechQueue();
    }

    // Fallback: If the buffer is getting very long and we haven't found any punctuation,
    // split on the last space to avoid high initial latency.
    if (_ttsBuffer.length > 120) {
      final int lastSpace = _ttsBuffer.lastIndexOf(' ');
      if (lastSpace > 0) {
        final sentence = _ttsBuffer.substring(0, lastSpace).trim();
        _ttsBuffer = _ttsBuffer.substring(lastSpace + 1);

        final fullSentence = (_currentPending + sentence).trim();
        _currentPending = "";

        if (fullSentence.isNotEmpty) {
          final cleanSentence = _cleanTextForTts(fullSentence);
          if (cleanSentence.isNotEmpty) {
            _speechQueue.add(cleanSentence);
            _processSpeechQueue();
          }
        }
      }
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

    // Optimize: Combine all currently queued sentences to avoid stop-and-start latency between sentences.
    // The native TTS engine will handle pauses between sentences smoothly inside a single speak call.
    final List<String> sentencesToSpeak = [];
    while (_speechQueue.isNotEmpty) {
      sentencesToSpeak.add(_speechQueue.removeAt(0));
    }

    final combinedSentence = sentencesToSpeak.join(" ");
    print("TTS Speaking combined: $combinedSentence");
    await _flutterTts.speak(combinedSentence);
  }

  // Cleans Markdown formatting, emojis, and standardizes abbreviations for smooth TTS speech
  String _cleanTextForTts(String text) {
    // 1. Remove markdown links: [text](url) -> text
    text = text.replaceAllMapped(
      RegExp(r'\[([^\]]+)\]\([^)]+\)'),
      (match) => match.group(1) ?? '',
    );

    // 2. Remove markdown bold/italic/strikethrough/code markers
    text = text.replaceAll(RegExp(r'\*\*|__'), '');
    text = text.replaceAll(RegExp(r'\*|_|`'), '');

    // 3. Remove markdown headers: #, ##, ### at the beginning of lines/text
    text = text.replaceAll(RegExp(r'^#+\s+'), '');

    // 4. Remove list markers like: "- ", "+ ", "* " at the start of the text/line
    text = text.replaceAll(RegExp(r'^[-\+]\s+'), '');

    // 5. Clean up numbered lists: "1. ", "2. " -> change to just the number so it doesn't pause or sound awkward
    text = text.replaceAllMapped(
      RegExp(r'^(\d+)\.\s+'),
      (match) => '${match.group(1)} ',
    );

    // 6. Replace common abbreviations with spoken equivalent or dot-less versions to prevent splits
    final abbreviations = {
      r'\bDr\b\.': 'Doctor',
      r'\bMr\b\.': 'Mr',
      r'\bMrs\b\.': 'Mrs',
      r'\bMs\b\.': 'Ms',
      r'\bPvt\b\.': 'Private',
      r'\bLtd\b\.': 'Limited',
      r'\bInc\b\.': 'Incorporated',
      r'\bCo\b\.': 'Company',
      r'\bCorp\b\.': 'Corporation',
      r'\bapprox\b\.': 'approximately',
      r'\bvs\b\.': 'versus',
      r'\be\.g\b\.': 'for example',
      r'\bi\.e\b\.': 'that is',
      r'\ba\.m\b\.': 'AM',
      r'\bp\.m\b\.': 'PM',
    };

    abbreviations.forEach((pattern, replacement) {
      text = text.replaceAllMapped(
        RegExp(pattern, caseSensitive: false),
        (match) => replacement,
      );
    });

    // 7. Strip out emojis to prevent TTS from speaking emoji descriptions or stuttering
    text = text.replaceAll(
      RegExp(
        r'[\u{1F300}-\u{1F9FF}]|[\u{2700}-\u{27BF}]|[\u{1F600}-\u{1F64F}]|[\u{1F680}-\u{1F6FF}]|[\u{2600}-\u{26FF}]|[\u{1F1E6}-\u{1F1FF}]',
        unicode: true,
      ),
      '',
    );

    // 8. Clean up extra spaces/newlines
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();

    return text;
  }

  // Identifies abbreviations or list markers that should be merged with subsequent text
  bool _isAbbreviationOrListMarker(String trimmed) {
    if (trimmed.isEmpty) return false;

    // Check if it's a numbered list marker like "1.", "23.", etc.
    final RegExp numberDotRegex = RegExp(r'^\d+\.$');
    if (numberDotRegex.hasMatch(trimmed)) {
      return true;
    }

    // Check if it's a single letter followed by a dot (e.g. middle initial "A.")
    final RegExp letterDotRegex = RegExp(r'^[a-zA-Z]\.$');
    if (letterDotRegex.hasMatch(trimmed)) {
      return true;
    }

    // Check against list of common abbreviations
    final Set<String> abbreviations = {
      'dr.',
      'mr.',
      'mrs.',
      'ms.',
      'pvt.',
      'ltd.',
      'inc.',
      'co.',
      'corp.',
      'vs.',
      'eg.',
      'ie.',
      'am.',
      'pm.',
      'approx.',
      'etc.',
      'dept.',
      'univ.',
      'assoc.',
    };

    return abbreviations.contains(trimmed.toLowerCase());
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
