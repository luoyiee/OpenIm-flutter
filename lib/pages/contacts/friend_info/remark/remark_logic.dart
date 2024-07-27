import 'package:flutter/cupertino.dart';
import 'package:flutter_openim_sdk/flutter_openim_sdk.dart';
import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';

class FriendRemarkLogic extends GetxController {
  late UserFullInfo info;
  var inputCtrl = TextEditingController();
  // var focusNode = FocusNode();

  void save() {
    // if (inputCtrl.text.isEmpty) {
    //   IMWidget.showToast(StrRes.remarkNotEmpty);
    //   return;
    // }
    OpenIM.iMManager.friendshipManager
        .setFriendRemark(userID: info.userID!, remark: inputCtrl.text.trim())
        .then(
      (value) {
        IMViews.showToast(StrRes.saveSuccessfully);
        Get.back(result: inputCtrl.text.trim());
        return value;
      },
    ).catchError((e) => IMViews.showToast(StrRes.saveFailed));
  }

  @override
  void onInit() {
    info = Get.arguments;
    inputCtrl.text = info.remark ?? '';
    super.onInit();
  }

  @override
  void onReady() {
    // TODO: implement onReady
    super.onReady();
  }

  @override
  void onClose() {
    inputCtrl.dispose();
    // focusNode.dispose();
    super.onClose();
  }
}
