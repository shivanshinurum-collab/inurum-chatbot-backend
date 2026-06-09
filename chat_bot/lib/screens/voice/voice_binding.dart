import 'package:chat_bot/screens/voice/voice_controller.dart';
import 'package:get/get.dart';

class VoiceBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<VoiceController>(() => VoiceController());
  }
}
