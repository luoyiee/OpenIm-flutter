import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';

import '../../routes/app_navigator.dart';

class ForgetPasswordLogic extends GetxController {
  var controller = TextEditingController();
  var showClearBtn = false.obs;
  var isPhoneRegister = true;
  var areaCode = "+86".obs;
  var enabled = false.obs;

  void nextStep() async {
    if (isPhoneRegister &&
        !IMUtils.isMobile(areaCode.value, controller.text)) {
      IMViews.showToast('请输入正确的手机号');
      return;
    }
    if (!isPhoneRegister && !GetUtils.isEmail(controller.text)) {
      IMViews.showToast('请输入正确的邮箱');
      return;
    }
    final success = await Apis.requestVerificationCode(
      areaCode: areaCode.value,
      phoneNumber: isPhoneRegister ? controller.text : null,
      email: !isPhoneRegister ? controller.text : null,
      usedFor: 2,
    );
    if (success) {
      AppNavigator.startRegisterVerifyPhoneOrEmail(
        areaCode: areaCode.value,
        phoneNumber: isPhoneRegister ? controller.text : null,
        email: !isPhoneRegister ? controller.text : null,
        usedFor: 2,
      );
    }
  }

  @override
  void onReady() {
    controller.addListener(() {
      showClearBtn.value = controller.text.isNotEmpty;
      enabled.value = controller.text.isNotEmpty;
    });
    super.onReady();
  }

  @override
  void onClose() {
    controller.dispose();
    super.onClose();
  }

  @override
  void onInit() {
    isPhoneRegister = Get.arguments['accountType'] == "phone";
    super.onInit();
  }

  void openCountryCodePicker() async {
    String? code = await IMViews.showCountryCodePicker();
    if (null != code) {
      areaCode.value = code;
    }
  }
}