import 'package:get/get.dart';
import 'package:openim/pages/chat/chat_logic.dart';
import 'package:openim_common/openim_common.dart';

class FontSizeLogic extends GetxController {
  final logic = Get.find<ChatLogic>(tag: GetTags.chat);
  var factor = 1.0.obs;

  @override
  void onInit() {
    factor.value = DataSp.getChatFontSizeFactor();
    super.onInit();
  }

  void changed(dynamic fac) {
    factor.value = fac;
  }

  void saveFactor() async {
    await logic.changeFontSize(factor.value);
    // Get.back();
  }

  void reset() async {
    await logic.changeFontSize(factor.value = Config.textScaleFactor);
  }
}
