import 'package:flutter_openim_sdk/flutter_openim_sdk.dart';
import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';

class FriendIdCodeLogic extends GetxController {
  late UserInfo info;

  @override
  void onInit() {
    info = Get.arguments;
    super.onInit();
  }

  void copy() {
    IMUtils.copy(text: info.userID!);
  }

  @override
  void onReady() {
    // TODO: implement onReady
    super.onReady();
  }

  @override
  void onClose() {
    // TODO: implement onClose
    super.onClose();
  }
}
