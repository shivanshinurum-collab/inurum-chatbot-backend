import 'package:chat_bot/screens/chat/chat_binding.dart';
import 'package:chat_bot/screens/chat/chat_view.dart';
import 'package:chat_bot/screens/voice/voice_binding.dart';
import 'package:chat_bot/screens/voice/voice_view.dart';
import 'package:get/get_navigation/src/routes/get_route.dart';

import '../routes/routes.dart';

class AppPages{
  static const initialRoute = Routes.voiceScreen;
  static final  routes = [
    GetPage(name: Routes.voiceScreen, page: () => VoiceView(),binding: VoiceBinding()),
    GetPage(name: Routes.chatScreen,page: () => ChatView() , binding: ChatBinding())
  ];
}