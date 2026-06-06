import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../widgets/glowing_orb.dart';
import 'chat_controller.dart';

class ChatView extends GetView<ChatController> {
  const ChatView({super.key});

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
            return Column(
              children: [
                // Top Header (Adapts based on chat state)
                _buildHeader(context),
                
                // Main Body Area
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.05),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: controller.isChatStarted.value
                        ? _buildChatHistory()
                        : _buildOrbStartup(context),
                  ),
                ),

                // Bottom Input/Controls Area
                _buildBottomPanel(context),
              ],
            );
          }),
        ),
      ),
    );
  }

  // --- HEADER SECTION ---
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button
          Visibility(
            visible: controller.isChatStarted.value,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
              onPressed: () {
                if (controller.isChatStarted.value) {
                  controller.resetChat();
                }
              },
            ),
          ),
          
          // Agent details in header (only visible when chat is active)
          Expanded(
            child: controller.isChatStarted.value
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Spark AI circular gradient avatar
                      Container(
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF4081), Color(0xFFFF9100)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF4081).withOpacity(0.3),
                              blurRadius: 8,
                              spreadRadius: 1,
                            )
                          ]
                        ),
                        child: const Icon(
                          Icons.auto_awesome,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            "Inurum Technologies AI",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "AI-Powered Tech Solutions",
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      )
                    ],
                  )
                : const Center(
                    child: Text(
                      "Inurum Technologies AI",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
          ),

          // // Menu button
          // IconButton(
          //   icon: const Icon(Icons.more_vert_rounded, color: Colors.white, size: 22),
          //   onPressed: () {
          //     // Action menu
          //   },
          // ),
        ],
      ),
    );
  }

  // --- STARTUP / ORB VIEW ---
  Widget _buildOrbStartup(BuildContext context) {
    return Column(
      key: const ValueKey('orb_startup'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(),
        
        // Large Glowing Animated Orb representing the AI "live photo"
        Center(
          child: GlowingOrb(
            size: 280,
            isThinking: controller.isLoading.value,
            isListening: controller.isListening.value,
          ),
        ),
        
        const Spacer(),
        
        // Suggestion suggestions cards
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "Suggested Questions",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              
              // Map suggestion list
              ...controller.suggestions.take(2).map((suggestion) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: InkWell(
                    onTap: () => controller.selectSuggestion(suggestion),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.06),
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              suggestion.replaceAll('\n', ' '),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 13,
                                height: 1.3,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white.withOpacity(0.3),
                            size: 16,
                          )
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // --- CHAT HISTORY VIEW ---
  Widget _buildChatHistory() {
    return Column(
      key: const ValueKey('chat_history'),
      children: [
        Expanded(
          child: Obx(() {
            return ListView.builder(
              controller: controller.scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              itemCount: controller.messages.length + (controller.isLoading.value ? 1 : 0),
              itemBuilder: (context, index) {
                // Show loading shimmer for agent response
                if (index == controller.messages.length) {
                  return _buildAgentLoadingItem();
                }
                
                final message = controller.messages[index];
                return _buildMessageItem(context, message);
              },
            );
          }),
        ),
      ],
    );
  }

  // Individual message row (User vs Agent)
  Widget _buildMessageItem(BuildContext context, message) {
    if (message.isUser) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User message bubble with Pink-Purple gradient
            Flexible(
              child: Container(
                margin: const EdgeInsets.only(left: 60.0),
                padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 14.0),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFFFF3F82),
                      Color(0xFFB53FFF),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(4),
                  ),
                ),
                child: Text(
                  message.text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // User avatar
            const CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blueGrey,
              backgroundImage: NetworkImage('https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=100&auto=format&fit=crop'), // placeholder image path
            ),
          ],
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Agent Icon
                Container(
                  padding: const EdgeInsets.all(6.0),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFFFF4081), Color(0xFFFF9100)],
                    ),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
                const SizedBox(width: 8),
                // Agent message bubble - Dark Charcoal
                Flexible(
                  child: Container(
                    margin: const EdgeInsets.only(right: 40.0),
                    padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 14.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16151B),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(20),
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.04),
                      ),
                    ),
                    child: Text(
                      message.text,
                      style: const TextStyle(
                        color: Color(0xFFE2E2E6),
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            // Interaction Action Buttons underneath Agent Bubble
            Padding(
              padding: const EdgeInsets.only(left: 38.0, top: 4.0, bottom: 4.0),
              child: Row(
                children: [
                  _buildActionIcon(Icons.copy_rounded, () {
                    Clipboard.setData(ClipboardData(text: message.text));
                    Get.snackbar(
                      "Copied",
                      "Message copied to clipboard",
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.white.withOpacity(0.1),
                      colorText: Colors.white,
                      duration: const Duration(seconds: 1),
                    );
                  }),
                  const SizedBox(width: 12),
                  _buildActionIcon(Icons.thumb_up_alt_outlined, () {
                    // Like action
                  }),
                  const SizedBox(width: 12),
                  _buildActionIcon(Icons.thumb_down_alt_outlined, () {
                    // Dislike action
                  }),
                  const SizedBox(width: 12),
                  _buildActionIcon(Icons.refresh_rounded, () {
                    // Re-run the question
                    controller.sendMessage(controller.messages[controller.messages.length - 2].text);
                  }),
                ],
              ),
            )
          ],
        ),
      );
    }
  }

  // Small helper for action buttons under agent message
  Widget _buildActionIcon(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Icon(
          icon,
          color: Colors.white54,
          size: 16,
        ),
      ),
    );
  }

  // Loading typing bubble for the Agent
  Widget _buildAgentLoadingItem() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6.0),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFFFF4081), Color(0xFFFF9100)],
              ),
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 14,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 14.0),
            decoration: BoxDecoration(
              color: const Color(0xFF16151B),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.04),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(0),
                const SizedBox(width: 4),
                _buildDot(1),
                const SizedBox(width: 4),
                _buildDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Individual bouncing dot helper for loading indicators
  Widget _buildDot(int delay) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (delay * 150)),
      builder: (context, value, child) {
        return Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.3 + (value * 0.5)),
            shape: BoxShape.circle,
          ),
        );
      },
      onEnd: () {},
    );
  }

  // --- BOTTOM CONTROLS PANEL ---
  Widget _buildBottomPanel(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 20.0, top: 8.0),
      child: AnimatedCrossFade(
        firstChild: _buildOrbControls(context),
        secondChild: _buildTextInputField(),
        crossFadeState: controller.isChatStarted.value
            ? CrossFadeState.showSecond
            : CrossFadeState.showFirst,
        duration: const Duration(milliseconds: 350),
      ),
    );
  }

  // Small bottom controls on Startup Screen (Mic button + secondary actions)
  Widget _buildOrbControls(BuildContext context) {
    return Column(
      children: [
        if (controller.isListening.value)
          const Padding(
            padding: EdgeInsets.only(bottom: 16.0),
            child: Text(
              "Listening...",
              style: TextStyle(
                color: Color(0xFFFF52A2),
                fontSize: 14,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Left Refresh Button
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Colors.white54, size: 24),
              onPressed: () {
                // Clear state / change suggestions
              },
            ),
            
            // Center Large Pulsing Mic Button
            GestureDetector(
              onTap: () => controller.toggleListening(),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Breathing outer ring
                  if (controller.isListening.value)
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 1.0, end: 1.5),
                      duration: const Duration(milliseconds: 1000),
                      builder: (context, value, child) {
                        return Container(
                          width: 64 * value,
                          height: 64 * value,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFFF52A2).withOpacity(0.25 * (2.0 - value)),
                          ),
                        );
                      },
                      onEnd: () {},
                    ),
                  
                  // Main purple mic circular button
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFB53FFF), Color(0xFFFF3F82)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF3F82).withOpacity(0.4),
                          blurRadius: 16,
                          spreadRadius: 2,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Icon(
                      controller.isListening.value ? Icons.stop_rounded : Icons.mic_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),
            
            // Right Keyboard Toggle Button
            IconButton(
              icon: const Icon(Icons.keyboard_rounded, color: Colors.white54, size: 24),
              onPressed: () {
                // Show text field immediately
                controller.isChatStarted.value = true;
                FocusScope.of(context).requestFocus(controller.inputFocusNode);
              },
            ),
          ],
        ),
      ],
    );
  }

  // Chat TextInput Field Panel (Visible when chat started)
  Widget _buildTextInputField() {
    return Row(
      children: [
        // Plus circle button on the left of input box
        Container(
          margin: const EdgeInsets.only(right: 10.0),
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.06),
            border: Border.all(
              color: Colors.white.withOpacity(0.08),
            ),
          ),
          child: const Icon(
            Icons.add_rounded,
            color: Color(0xFFFF52A2),
            size: 22,
          ),
        ),
        
        // Main input container box
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF16151B),
              borderRadius: BorderRadius.circular(24.0),
              border: Border.all(
                color: Colors.white.withOpacity(0.06),
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                // Text input
                Expanded(
                  child: TextField(
                    controller: controller.textController,
                    focusNode: controller.inputFocusNode,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    cursorColor: const Color(0xFFFF52A2),
                    decoration: InputDecoration(
                      hintText: "Send message...",
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.3),
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12.0),
                    ),
                    onSubmitted: (val) {
                      controller.sendMessage(val);
                    },
                  ),
                ),
                
                // Mic Icon accessory
                IconButton(
                  icon: const Icon(Icons.mic_none_rounded, color: Colors.white54, size: 20),
                  onPressed: () {
                    // Switch to voice mode/listening
                    controller.isChatStarted.value = false;
                    controller.toggleListening();
                  },
                ),
                
                // Attachment Icon accessory
                IconButton(
                  icon: const Icon(Icons.attach_file_rounded, color: Colors.white54, size: 20),
                  onPressed: () {
                    // Attach media
                  },
                ),
                
                // Send icon (only show if input is not empty)
                IconButton(
                  icon: const Icon(Icons.send_rounded, color: Color(0xFFFF52A2), size: 20),
                  onPressed: () {
                    controller.sendMessage(controller.textController.text);
                  },
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
