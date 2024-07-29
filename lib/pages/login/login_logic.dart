import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:openim/pages/mine/server_config/server_config_binding.dart';
import 'package:openim/pages/mine/server_config/server_config_view.dart';
import 'package:openim_common/openim_common.dart';

import '../../core/controller/im_controller.dart';
import '../../core/controller/push_controller.dart';
import '../../routes/app_navigator.dart';

enum LoginType {
  password,
  sms,
}

class LoginLogic extends GetxController {
  final imLogic = Get.find<IMController>();
  final pushLogic = Get.find<PushController>();
  final phoneCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final pwdCtrl = TextEditingController();
  final codeCtrl = TextEditingController();
  final obscureText = true.obs;
  final enabled = false.obs;
  final areaCode = "+86".obs;
  var loginIndex = 0.obs;
  var loginType = LoginType.password.obs;
  var phoneFocusNode = FocusNode();
  var emailFocusNode = FocusNode();

  bool get isPasswordLogin => loginType.value == LoginType.password;

  var showAccountClearBtn = false.obs;
  var showPwdClearBtn = false.obs;

  _initData() {
    var map = DataSp.getLoginAccount();
    if (map is Map) {
      String? phoneNumber = map["phoneNumber"];
      String? email = map["email"];
      String? areaCode = map["areaCode"];
      if (phoneNumber != null && phoneNumber.isNotEmpty) {
        phoneCtrl.text = phoneNumber;
      }
      if (email != null && email.isNotEmpty) {
        emailCtrl.text = email;
      }
      if (areaCode != null && areaCode.isNotEmpty) {
        this.areaCode.value = areaCode;
      }
    }
  }

  void switchLoginType() {
    loginType.value = isPasswordLogin ? LoginType.sms : LoginType.password;
  }

  @override
  void onClose() {
    phoneCtrl.dispose();
    emailCtrl.dispose();
    pwdCtrl.dispose();
    super.onClose();
  }

  @override
  void onInit() {
    _initData();
    phoneCtrl.addListener(() {
      // showAccountClearBtn.value = phoneCtrl.text.isNotEmpty;
      _onChanged();
    });
    emailCtrl.addListener(() {
      // showAccountClearBtn.value = emailCtrl.text.isNotEmpty;
      _onChanged();
    });
    pwdCtrl.addListener(() {
      // showPwdClearBtn.value = pwdCtrl.text.isNotEmpty;
      _onChanged();
    });
    codeCtrl.addListener(_onChanged);
    super.onInit();
  }

  _onChanged() {
    // enabled.value =
    //     phoneCtrl.text.trim().isNotEmpty && pwdCtrl.text.trim().isNotEmpty;
    enabled.value = (isPasswordLogin && pwdCtrl.text.trim().isNotEmpty ||
            !isPasswordLogin && codeCtrl.text.trim().isNotEmpty) &&
        (phoneCtrl.text.trim().isNotEmpty || emailCtrl.text.trim().isNotEmpty);
  }

  login() {
    if (loginIndex.value == 0 &&
        !IMUtils.isMobile(areaCode.value, phoneCtrl.text)) {
      IMViews.showToast('请输入正确的手机号');
      return;
    }
    if (loginIndex.value == 1 && !GetUtils.isEmail(emailCtrl.text)) {
      IMViews.showToast('请输入正确的邮箱');
      return;
    }

    LoadingView.singleton.wrap(asyncFunction: () async {
      var suc = await _login();
      if (suc) {
        AppNavigator.startMain();
      }
    });
  }

  Future<bool> _login() async {
    try {
      final data = await Apis.login(
        areaCode: areaCode.value,
        // phoneNumber: phoneCtrl.text,
        phoneNumber: loginIndex.value == 0 ? phoneCtrl.text : null,
        email: loginIndex.value == 1 ? emailCtrl.text : null,
        password: IMUtils.emptyStrToNull(pwdCtrl.text),
        verificationCode: isPasswordLogin ? null : codeCtrl.text,
      );
      final account = {
        "areaCode": areaCode.value,
        "phoneNumber": phoneCtrl.text,
        "email": emailCtrl.text,
      };
      await DataSp.putLoginCertificate(data);
      await DataSp.putLoginAccount(account);
      Logger.print('login : ${data.userID}, token: ${data.imToken}');
      await imLogic.login(data.userID, data.imToken);
      Logger.print('im login success');
      pushLogic.login(data.userID);
      Logger.print('push login success');
      return true;
    } catch (e, s) {
      Logger.print('login e: $e $s');
    }
    return false;
  }

  void openCountryCodePicker() async {
    String? code = await IMViews.showCountryCodePicker();
    if (null != code) areaCode.value = code;
  }

  void configService() => Get.to(
        () => ServerConfigPage(),
        binding: ServerConfigBinding(),
      );

  void registerNow(int index) =>
      AppNavigator.startRegister(index == 0 ? 'email' : 'phone');

  void forgetPassword(int index) {
    AppNavigator.startForgetPassword(
        accountType: index == 0 ? 'email' : 'phone');
  }

  @override
  void onReady() {
    // phoneCtrl.addListener(() {
    //   showAccountClearBtn.value = phoneCtrl.text.isNotEmpty;
    //   _changeLoginButtonStatus();
    // });
    // emailCtrl.addListener(() {
    //   showAccountClearBtn.value = emailCtrl.text.isNotEmpty;
    //   _changeLoginButtonStatus();
    // });
    // pwdCtrl.addListener(() {
    //   showPwdClearBtn.value = pwdCtrl.text.isNotEmpty;
    //   _changeLoginButtonStatus();
    // });
    // codeCtrl.addListener(() {
    //   _changeLoginButtonStatus();
    // });
    super.onReady();
  }

  // void _changeLoginButtonStatus() {
  //   enabledLoginButton.value = (isPasswordLogin && pwdCtrl.text.isNotEmpty ||
  //           !isPasswordLogin && codeCtrl.text.isNotEmpty) &&
  //       (phoneCtrl.text.isNotEmpty || emailCtrl.text.isNotEmpty);
  // }

  void switchLoginTab(index) {
    // FocusScope.of(Get.context!).requestFocus(FocusNode());
    this.loginIndex.value = index;
    phoneCtrl.clear();
    emailCtrl.clear();
    pwdCtrl.clear();
    // if (index == 0) {
    //   emailFocusNode.unfocus();
    //   phoneFocusNode.requestFocus();
    // } else {
    //   phoneFocusNode.unfocus();
    //   emailFocusNode.requestFocus();
    // }
  }

  Future<bool> getVerificationCode() async {
    try {
      await LoadingView.singleton.wrap(
          asyncFunction: () => Apis.requestVerificationCode(
                areaCode: areaCode.value,
                phoneNumber: loginIndex.value == 0 ? phoneCtrl.text : null,
                email: loginIndex.value == 1 ? emailCtrl.text : null,
                usedFor: 3,
              ));
      IMViews.showToast(StrRes.sendSuccessfully);
      return true;
    } catch (e) {
      IMViews.showToast(StrRes.sendFailed);
      return false;
    }
  }
}
