import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:openim/routes/app_navigator.dart';
import 'package:openim_common/openim_common.dart';

import '../../core/controller/app_controller.dart';

class RegisterLogic extends GetxController {
  final appLogic = Get.find<AppController>();
  final phoneCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final invitationCodeCtrl = TextEditingController();
  final areaCode = "+86".obs;
  final enabled = false.obs;
  var isPhoneRegister = true.obs;

  @override
  void onClose() {
    phoneCtrl.dispose();
    emailCtrl.dispose();
    invitationCodeCtrl.dispose();
    super.onClose();
  }

  @override
  void onInit() {
    isPhoneRegister.value = Get.arguments['registerWay'] == "phone";
    phoneCtrl.addListener(_onChanged);
    emailCtrl.addListener(_onChanged);
    invitationCodeCtrl.addListener(_onChanged);
    super.onInit();
  }

  _onChanged() {
    if (isPhoneRegister.value) {
      enabled.value = needInvitationCodeRegister
          ? phoneCtrl.text.trim().isNotEmpty &&
              invitationCodeCtrl.text.trim().isNotEmpty
          : phoneCtrl.text.trim().isNotEmpty;
    } else {
      enabled.value = needInvitationCodeRegister
          ? emailCtrl.text.trim().isNotEmpty &&
              invitationCodeCtrl.text.trim().isNotEmpty
          : emailCtrl.text.trim().isNotEmpty;
    }
  }

  bool get needInvitationCodeRegister =>
      null != appLogic.clientConfigMap['needInvitationCodeRegister'] &&
      appLogic.clientConfigMap['needInvitationCodeRegister'] != 0;

  String? get invitationCode => IMUtils.emptyStrToNull(invitationCodeCtrl.text);

  void openCountryCodePicker() async {
    String? code = await IMViews.showCountryCodePicker();
    if (null != code) areaCode.value = code;
  }

  Future<bool> requestVerificationCode() => Apis.requestVerificationCode(
        areaCode: areaCode.value,
        phoneNumber: isPhoneRegister.value ? phoneCtrl.text.trim() : null,
        email: !isPhoneRegister.value ? emailCtrl.text.trim() : null,
        usedFor: 1,
        invitationCode: invitationCode,
      );

  void next() async {
    // if (!IMUtils.isMobile(areaCode.value, phoneCtrl.text)) {
    //   IMViews.showToast(StrRes.plsEnterRightPhone);
    //   return;
    // }

    if (isPhoneRegister.value &&
        !IMUtils.isMobile(areaCode.value, phoneCtrl.text)) {
      IMViews.showToast(StrRes.plsEnterRightPhone);
      return;
    }
    if (!isPhoneRegister.value && !GetUtils.isEmail(emailCtrl.text)) {
      IMViews.showToast('请输入正确的邮箱');
      return;
    }

    // if (needInvitationCodeRegister && invitationCodeCtrl.text.isEmpty) {
    //   IMViews.showToast(StrRes.invitationCodeNotEmpty);
    //   return;
    // }

    final success = await LoadingView.singleton.wrap(
      asyncFunction: () => requestVerificationCode(),
    );
    if (success) {
      AppNavigator.startRegisterVerifyPhoneOrEmail(
        areaCode: areaCode.value,
        phoneNumber: isPhoneRegister.value ? phoneCtrl.text.trim() : null,
        email: !isPhoneRegister.value ? emailCtrl.text.trim() : null,
        usedFor: 1,
        invitationCode: invitationCode,
      );
    }
  }
}
