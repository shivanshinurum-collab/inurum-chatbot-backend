import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../widgets/glowing_orb.dart';
import 'voice_controller.dart';

class VoiceView extends GetView<VoiceController> {
  const VoiceView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C0B10),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0A090F),
              Color(0xFF120E1E),
              Color(0xFF0C0B10),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Obx(() {
            final state = controller.voiceState.value;
            final isThinking = state == VoiceState.thinking;
            final isListening = state == VoiceState.listening;
            final isSpeaking = state == VoiceState.speaking;

            return Column(
              children: [
                // Top Header Section
                _buildHeader(context, state),

                // Main Body Area
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Large Glowing Animated Orb representing the AI
                      Expanded(
                        flex: 3,
                        child: Center(
                          child: GlowingOrb(
                            size: 260,
                            isThinking: isThinking,
                            isListening: isListening,
                          ),
                        ),
                      ),

                      // Status & Subtitles/Transcript Area
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: _buildTranscriptBox(state),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Bottom Panel Controls (Refresh, Mic, Keyboard)
                _buildBottomControls(context, state, isListening, isThinking, isSpeaking),
              ],
            );
          }),
        ),
      ),
    );
  }

  // --- HEADER SECTION ---
  Widget _buildHeader(BuildContext context, VoiceState state) {
    String statusText = "Online";
    Color statusColor = const Color(0xFF00FF87);

    if (state == VoiceState.listening) {
      statusText = "Listening...";
      statusColor = const Color(0xFFFF52A2);
    } else if (state == VoiceState.thinking) {
      statusText = "Thinking...";
      statusColor = const Color(0xFF9F52FF);
    } else if (state == VoiceState.speaking) {
      statusText = "Speaking...";
      statusColor = const Color(0xFFFF9100);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left Status Indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: statusColor.withValues(alpha: 0.25),
                width: 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: statusColor.withValues(alpha: 0.5),
                        blurRadius: 4,
                        spreadRadius: 1,
                      )
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  statusText.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),

          // Center Title
          const Text(
            "Inurum AI Voice",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),

          // Right Spacer to keep center aligned
          const SizedBox(width: 80),
        ],
      ),
    );
  }

  // --- TRANSCRIPT BOX SECTION ---
  Widget _buildTranscriptBox(VoiceState state) {
    final userText = controller.userTranscript.value;
    final aiText = controller.aiTranscript.value;

    if (state == VoiceState.idle && userText.isEmpty && aiText.isEmpty) {
      // Show suggestions when screen is idle and empty
      return Column(
        key: const ValueKey('suggestions_view'),
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "Tap mic to start or try asking:",
            style: TextStyle(
              color: Colors.white60,
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 90,
            child: ListView(
              scrollDirection: Axis.horizontal,
              shrinkWrap: true,
              children: controller.suggestions.take(3).map((suggestion) {
                return GestureDetector(
                  onTap: () => controller.selectSuggestion(suggestion),
                  child: Container(
                    width: 170,
                    margin: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 8.0),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        suggestion,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          height: 1.3,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      );
    }

    // Otherwise, show the subtitle transcript conversation bubble
    return SingleChildScrollView(
      key: const ValueKey('transcript_content'),
      physics: const BouncingScrollPhysics(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.05),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // User Speech Recognition Subtitles
            if (userText.isNotEmpty) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "You: ",
                    style: TextStyle(
                      color: Color(0xFFFF52A2),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      userText,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
              if (aiText.isNotEmpty) const SizedBox(height: 12),
            ],

            // AI Speech Output Subtitles
            if (aiText.isNotEmpty) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "AI: ",
                    style: TextStyle(
                      color: Color(0xFF9F52FF),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      aiText,
                      style: const TextStyle(
                        color: Color(0xFFE2E2E6),
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ] else if (state == VoiceState.thinking) ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF52A2)),
                    ),
                  ),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  // --- BOTTOM CONTROLS SECTION ---
  Widget _buildBottomControls(
    BuildContext context,
    VoiceState state,
    bool isListening,
    bool isThinking,
    bool isSpeaking,
  ) {
    final isActive = isListening || isThinking || isSpeaking;

    return Padding(
      padding: const EdgeInsets.only(left: 24.0, right: 24.0, bottom: 32.0, top: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Left Reset/Mute Button
          IconButton(
            icon: Icon(
              isActive ? Icons.close_rounded : Icons.refresh_rounded,
              color: Colors.white54,
              size: 24,
            ),
            onPressed: () {
              controller.stopSpeechAndStream();
              controller.userTranscript.value = "";
              controller.aiTranscript.value = "";
            },
          ),

          // Center Large Microphone Button
          GestureDetector(
            onTap: () => controller.toggleListening(),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Animated outer pulsing ring for recording status
                if (isListening)
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 1.0, end: 1.45),
                    duration: const Duration(milliseconds: 1200),
                    builder: (context, value, child) {
                      return Container(
                        width: 70 * value,
                        height: 70 * value,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFFF52A2).withValues(alpha: 0.25 * (2.0 - value)),
                        ),
                      );
                    },
                    onEnd: () {},
                  ),

                // Main central action button
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFB53FFF), Color(0xFFFF3F82)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF3F82).withValues(alpha: 0.4),
                        blurRadius: 16,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Icon(
                    isListening
                        ? Icons.stop_rounded
                        : (isSpeaking || isThinking ? Icons.pause_rounded : Icons.mic_rounded),
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ],
            ),
          ),

          // Right Keyboard Toggle Button (Redirects to chat)
          IconButton(
            icon: const Icon(Icons.keyboard_rounded, color: Colors.white54, size: 24),
            onPressed: () => controller.navigateToChat(),
          ),
        ],
      ),
    );
  }
}
