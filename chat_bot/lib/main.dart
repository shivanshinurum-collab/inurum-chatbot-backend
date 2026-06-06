import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'screens/chat/chat_binding.dart';
import 'screens/chat/chat_view.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Inurum AI Chatbot',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFFFF52A2),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFF52A2),
          secondary: Color(0xFFB53FFF),
          surface: Color(0xFF16151B),
          background: Color(0xFF0C0B10),
        ),
        scaffoldBackgroundColor: const Color(0xFF0C0B10),
        useMaterial3: true,
      ),
      initialBinding: ChatBinding(),
      home: const ChatView(),
    );
  }
}
