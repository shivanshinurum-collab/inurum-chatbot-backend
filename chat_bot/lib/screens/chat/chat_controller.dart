import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/message.dart';
import '../../services/api_service.dart';

class ChatController extends GetxController {
  final ApiService _apiService = ApiService();

  // Observable states
  final messages = <Message>[].obs;
  final isChatStarted = false.obs;
  final isLoading = false.obs;
  final isListening = false.obs;

 final apiMessage = "".obs;

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  Future<void> loadData() async {
    apiMessage.value = await _apiService.test();

    print("API Response: ${apiMessage.value}");
  }

  
  // Controllers
  final TextEditingController textController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  FocusNode inputFocusNode = FocusNode();

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
  void onClose() {
    textController.dispose();
    scrollController.dispose();
    inputFocusNode.dispose();
    super.onClose();
  }

  // Send message
  Future<void> sendMessage(String text) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty) return;

    // Trigger transitions
    if (!isChatStarted.value) {
      isChatStarted.value = true;
    }

    // Add user message
    messages.add(Message.user(cleanText));
    textController.clear();
    _scrollToBottom();

    // Start thinking state
    isLoading.value = true;

    // Call API
    final String responseText = await _apiService.askAi(cleanText);

    // Stop thinking state and add AI reply
    isLoading.value = false;
    messages.add(Message.agent(responseText));
    _scrollToBottom();
  }

  // Handle suggestion tap
  void selectSuggestion(String suggestionText) {
    // Clean formatting newlines for querying
    final cleanQuery = suggestionText.replaceAll('\n', ' ');
    sendMessage(cleanQuery);
  }

  // Simulate audio input listening
  void toggleListening() {
    if (isListening.value) {
      // User tapped mic to stop
      isListening.value = false;
    } else {
      isListening.value = true;
      // Simulate listening to speech and sending query after 3 seconds
      Timer(const Duration(seconds: 3), () {
        if (isListening.value) {
          isListening.value = false;
          // Pre-fill input or send default test question from user's request
          sendMessage("Tell me about Inurum Technologies");
        }
      });
    }
  }

  // Reset the chat and go back to orb screen
  void resetChat() {
    isChatStarted.value = false;
    messages.clear();
    textController.clear();
  }

  // Helper to scroll list to bottom
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutQuad,
        );
      }
    });
  }
}
