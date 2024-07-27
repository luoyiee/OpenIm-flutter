import 'package:flutter/material.dart';
import 'package:flutter_openim_sdk/flutter_openim_sdk.dart';
import 'package:flutter_screen_lock/flutter_screen_lock.dart';
import 'package:get/get.dart';
import 'package:local_auth/local_auth.dart';
import 'package:openim_common/openim_common.dart';
import 'package:rxdart/rxdart.dart';

import '../../core/controller/app_controller.dart';
import '../../core/controller/im_controller.dart';
import '../../core/controller/push_controller.dart';
import '../../routes/app_navigator.dart';
import '../../widgets/screen_lock_title.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_darwin/local_auth_darwin.dart';

class HomeLogic extends GetxController {
  final pushLogic = Get.find<PushController>();
  final imLogic = Get.find<IMController>();
  final initLogic = Get.find<AppController>();
  final index = 0.obs;
  final unreadMsgCount = 0.obs;
  final unhandledFriendApplicationCount = 0.obs;
  final unhandledGroupApplicationCount = 0.obs;
  final unhandledCount = 0.obs;
  final auth = LocalAuthentication();
  final _errorController = PublishSubject<String>();

  Function()? onScrollToUnreadMessage;
  String? lockScreenPwd;
  bool isShowScreenLock = false;
  late bool isAutoLogin;
  final cacheLogic = Get.find<CacheController>();

  switchTab(index) {
    this.index.value = index;
  }

  scrollToUnreadMessage(index) {
    onScrollToUnreadMessage?.call();
  }

  _getUnreadMsgCount() {
    OpenIM.iMManager.conversationManager.getTotalUnreadMsgCount().then((count) {
      unreadMsgCount.value = int.tryParse(count) ?? 0;
      initLogic.showBadge(unreadMsgCount.value);
    });
  }

  void getUnhandledFriendApplicationCount() async {
    var i = 0;
    var list = await OpenIM.iMManager.friendshipManager
        .getFriendApplicationListAsRecipient();
    var haveReadList = DataSp.getHaveReadUnHandleFriendApplication();
    haveReadList ??= <String>[];
    for (var info in list) {
      var id = IMUtils.buildFriendApplicationID(info);
      if (!haveReadList.contains(id)) {
        if (info.handleResult == 0) i++;
      }
    }
    unhandledFriendApplicationCount.value = i;
    unhandledCount.value = unhandledGroupApplicationCount.value + i;
  }

  void getUnhandledGroupApplicationCount() async {
    var i = 0;
    var list = await OpenIM.iMManager.groupManager
        .getGroupApplicationListAsRecipient();
    var haveReadList = DataSp.getHaveReadUnHandleGroupApplication();
    haveReadList ??= <String>[];
    for (var info in list) {
      var id = IMUtils.buildGroupApplicationID(info);
      if (!haveReadList.contains(id)) {
        if (info.handleResult == 0) i++;
      }
    }
    unhandledGroupApplicationCount.value = i;
    unhandledCount.value = unhandledFriendApplicationCount.value + i;
  }

  @override
  void onInit() {
    isAutoLogin = Get.arguments['isAutoLogin'];

    if (isAutoLogin) {
      WidgetsBinding.instance.addPostFrameCallback((_) => showLockScreenPwd());
    }


    imLogic.unreadMsgCountEventSubject.listen((value) {
      unreadMsgCount.value = value;
    });
    imLogic.friendApplicationChangedSubject.listen((value) {
      getUnhandledFriendApplicationCount();
    });
    imLogic.groupApplicationChangedSubject.listen((value) {
      getUnhandledGroupApplicationCount();
    });

    super.onInit();
  }

  @override
  void onReady() {
    _getUnreadMsgCount();
    getUnhandledFriendApplicationCount();
    getUnhandledGroupApplicationCount();
    cacheLogic.initCallRecords();
    cacheLogic.initFavoriteEmoji();
    super.onReady();
  }

  @override
  void onClose() {
    _errorController.close();
    super.onClose();
  }


  @override
  void onResumed() {
    WidgetsBinding.instance.addPostFrameCallback((_) => showLockScreenPwd());
  }


  void showLockScreenPwd() async {
    if (isShowScreenLock) return;
    lockScreenPwd = DataSp.getLockScreenPassword();
    if (null != lockScreenPwd) {
      final isEnabledBiometric = DataSp.isEnabledBiometric() == true;
      bool enabled = false;
      if (isEnabledBiometric) {
        final isSupportedBiometrics = await auth.isDeviceSupported();
        final canCheckBiometrics = await auth.canCheckBiometrics;
        enabled = isSupportedBiometrics && canCheckBiometrics;
      }
      isShowScreenLock = true;
      screenLock(
        context: Get.context!,
        correctString: lockScreenPwd!,
        maxRetries: 3,
        // title: Text(StrRes.plsEnterPwd, style: PageStyle.ts_FFFFFF_24sp),
        title: ScreenLockTitle(stream: _errorController.stream),
        canCancel: false,
        customizedButtonChild: enabled ? const Icon(Icons.fingerprint) : null,
        customizedButtonTap: enabled ? () async => await localAuth() : null,
        onOpened: enabled ? () async => await localAuth() : null,
        onUnlocked: () {
          isShowScreenLock = false;
          Get.back();
        },
        onMaxRetries: (_) async {
          Get.back();
          await LoadingView.singleton.wrap(asyncFunction: () async {
            await imLogic.logout();
            await DataSp.removeLoginCertificate();
            await DataSp.clearLockScreenPassword();
            await DataSp.closeBiometric();
            pushLogic.logout();
          });
          AppNavigator.startLogin();
        },
        onError: (retries) {
          _errorController.sink.add(
            retries.toString(),
          );
        },
      );
    }
  }


  Future<void> localAuth() async {
    final didAuthenticate = await auth.authenticate(
      localizedReason: '扫描您的指纹（或面部或其他）以进行身份验证',
      options: AuthenticationOptions(
        // stickyAuth: true,
        biometricOnly: true,
      ),
      authMessages: <AuthMessages>[
        AndroidAuthMessages(
          signInTitle: ' ',
          cancelButton: '不，谢谢',
        ),
        IOSAuthMessages(
          cancelButton: '不，谢谢',
        ),
      ],
    );
    if (didAuthenticate) {
      Get.back();
    }
  }
}
