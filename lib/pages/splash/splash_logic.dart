import 'dart:async';

import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';

import '../../core/controller/im_controller.dart';
import '../../core/controller/push_controller.dart';
import '../../routes/app_navigator.dart';

class SplashLogic extends GetxController {
  final imLogic = Get.find<IMController>();
  final pushLogic = Get.find<PushController>();

  String? get userID => DataSp.userID;

  String? get token => DataSp.imToken;

  late StreamSubscription initializedSub;

  @override
  void onInit() {
    initializedSub = imLogic.initializedSubject.listen((value) {
      LoggerUtil.print('---------------------initialized---------------------');
      if (null != userID && null != token) {
        _login();
      } else {
        AppNavigator.startLogin();
      }
    });
    super.onInit();
  }

  _login() async {
    try {
      LoggerUtil.print('---------login---------- userID: $userID, token: $token');
      await imLogic.login(userID!, token!);
      LoggerUtil.print('---------im login success-------');
      pushLogic.login(userID!);
      LoggerUtil.print('---------push login success----');
      AppNavigator.startSplashToMain(isAutoLogin: true);
    } catch (e, s) {
      IMViews.showToast('$e $s');
      await DataSp.removeLoginCertificate();
      AppNavigator.startLogin();
    }
  }

  @override
  void onClose() {
    initializedSub.cancel();
    super.onClose();
  }
}
