import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';

import '../../../core/controller/im_controller.dart';
import '../../../core/controller/push_controller.dart';
import '../../../routes/app_navigator.dart';

class SetPasswordLogic extends GetxController {
  final imLogic = Get.find<IMController>();
  final pushLogic = Get.find<PushController>();
  final nicknameCtrl = TextEditingController();
  final pwdCtrl = TextEditingController();
  final pwdAgainCtrl = TextEditingController();
  final enabled = false.obs;
  String? phoneNumber;
  String? email;
  String? areaCode;
  late int usedFor;
  late String verificationCode;
  String? invitationCode;

  // var isPhoneWay = true.obs;
  bool get isPhoneWay => null != phoneNumber;

  bool get isUsedForRegister => usedFor == 1;

  @override
  void onClose() {
    nicknameCtrl.dispose();
    pwdCtrl.dispose();
    pwdAgainCtrl.dispose();
    super.onClose();
  }

  @override
  void onInit() {
    phoneNumber = Get.arguments['phoneNumber'];
    email = Get.arguments['email'];
    areaCode = Get.arguments['areaCode'];
    usedFor = Get.arguments['usedFor'];
    verificationCode = Get.arguments['verificationCode'];
    invitationCode = Get.arguments['invitationCode'];
    nicknameCtrl.addListener(_onChanged);
    pwdCtrl.addListener(_onChanged);
    pwdAgainCtrl.addListener(_onChanged);
    super.onInit();
  }

  _onChanged() {
    ///注册
    if (usedFor == 1) {
      enabled.value = nicknameCtrl.text.trim().isNotEmpty &&
          pwdCtrl.text.trim().isNotEmpty &&
          pwdAgainCtrl.text.trim().isNotEmpty;

      ///修改密码
    } else {
      enabled.value =
          pwdCtrl.text.trim().isNotEmpty && pwdAgainCtrl.text.trim().isNotEmpty;
    }
  }

  bool _checkingInput() {
    if (usedFor == 1 && nicknameCtrl.text.trim().isEmpty) {
      IMViews.showToast(StrRes.plsEnterYourNickname);
      return false;
    }
    if (!IMUtils.isValidPassword(pwdCtrl.text)) {
      IMViews.showToast(StrRes.wrongPasswordFormat);
      return false;
    } else if (pwdCtrl.text != pwdAgainCtrl.text) {
      IMViews.showToast(StrRes.twicePwdNoSame);
      return false;
    }
    return true;
  }

  void nextStep() {
    if (_checkingInput()) {
      if (usedFor == 1) {
        // 设置密码/注册
        register();
      } else if (usedFor == 2) {
        //重置密码,使用ip报错
        LoadingView.singleton.wrap(asyncFunction: () async {
          await Apis.resetPassword(
            areaCode: areaCode,
            phoneNumber: phoneNumber,
            email: email,
            password: pwdCtrl.text,
            verificationCode: verificationCode,
          ).then((value) {
            AppNavigator.startBackLogin();
          });
        });
      }
    }
  }

  void register() async {
    await LoadingView.singleton.wrap(asyncFunction: () async {
      final data = await Apis.register(
        nickname: nicknameCtrl.text.trim(),
        areaCode: areaCode,
        phoneNumber: phoneNumber,
        email: email,
        password: pwdCtrl.text,
        verificationCode: verificationCode,
        invitationCode: invitationCode,
      );
      if (null == IMUtils.emptyStrToNull(data.imToken) ||
          null == IMUtils.emptyStrToNull(data.chatToken)) {
        AppNavigator.startLogin();
        return;
      }
      final account = {"areaCode": areaCode, "phoneNumber": phoneNumber};
      await DataSp.putLoginCertificate(data);
      await DataSp.putLoginAccount(account);
      await imLogic.login(data.userID, data.imToken);
      Logger.print('---------im login success-------');
      pushLogic.login(data.userID);
      Logger.print('---------jpush login success----');
    });
    AppNavigator.startMain();
  }
}
