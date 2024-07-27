import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_openim_sdk/flutter_openim_sdk.dart';
import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';

import '../../../core/controller/app_controller.dart';
import '../../../core/controller/im_controller.dart';
import '../../../routes/app_navigator.dart';
import '../chat_logic.dart';

class ChatSetupLogic extends GetxController {
  final chatLogic = Get.find<ChatLogic>(tag: GetTags.chat);
  final appLogic = Get.find<AppController>();
  final imLogic = Get.find<IMController>();
  late Rx<ConversationInfo> conversationInfo;

  String get conversationID => conversationInfo.value.conversationID;

  ///拓展
  var topContacts = false.obs;
  var noDisturb = false.obs;
  var blockFriends = false.obs;
  var burnAfterReading = false.obs;
  var noDisturbIndex = 0.obs;
  late StreamSubscription conversationChangedSub;
  late StreamSubscription friendInfoChangedSub;
  var burnDuration = 30.obs;
  var name = ''.obs;

  @override
  void onClose() {
    super.onClose();
  }

  @override
  void onInit() {
    conversationInfo = Rx(Get.arguments['conversationInfo']);
    name.value = conversationInfo.value.showName ?? '';
    topContacts.value = conversationInfo.value.isPinned!;
    burnAfterReading.value = conversationInfo.value.isPrivateChat!;
    var status = conversationInfo.value.recvMsgOpt;
    noDisturb.value = status != 0;
    burnDuration.value = conversationInfo.value.burnDuration ?? 30;
    if (noDisturb.value) {
      noDisturbIndex.value = status == 1 ? 1 : 0;
    }

    conversationChangedSub =
        imLogic.conversationChangedSubject.listen((newList) {
      for (var newValue in newList) {
        if (newValue.conversationID == conversationInfo.value.conversationID) {
          burnAfterReading.value = newValue.isPrivateChat!;
          burnDuration.value = newValue.burnDuration ?? 30;
          break;
        }
      }
    });

    // 好友信息变化
    friendInfoChangedSub = imLogic.friendInfoChangedSubject.listen((value) {
      if (conversationInfo.value.userID == value.userID) {
        name.value = value.getShowName();
      }
    });
    super.onInit();
  }

  void createGroup() => AppNavigator.startCreateGroup(defaultCheckedList: [
        UserInfo(
          userID: conversationInfo.value.userID,
          faceURL: conversationInfo.value.faceURL,
          nickname: conversationInfo.value.showName,
        ),
        OpenIM.iMManager.userInfo,
      ]);

  void viewUserInfo() => AppNavigator.startUserProfilePane(
        userID: conversationInfo.value.userID!,
        // nickname: conversationInfo.value.showName,
        nickname: name.value,
        faceURL: conversationInfo.value.faceURL,
      );

  ///拓展
  void searchMessage() {
    AppNavigator.startMessageSearch(info: conversationInfo.value);
  }

  void searchPicture() {
    AppNavigator.startSearchPicture(info: conversationInfo.value, type: 0);
  }

  void searchVideo() {
    AppNavigator.startSearchPicture(info: conversationInfo.value, type: 1);
  }

  void searchFile() {
    AppNavigator.startSearchFile(info: conversationInfo.value);
  }

  void toggleTopContacts() async {
    topContacts.value = !topContacts.value;
    await OpenIM.iMManager.conversationManager.pinConversation(
      conversationID: conversationInfo.value.conversationID,
      isPinned: topContacts.value,
    );
  }

  void toggleNoDisturb() {
    noDisturb.value = !noDisturb.value;
    if (!noDisturb.value) noDisturbIndex.value = 0;
    setConversationRecvMessageOpt(status: noDisturb.value ? 2 : 0);
  }

  void toggleBlockFriends() {
    blockFriends.value = !blockFriends.value;
    chatLogic.isInBlacklist.value = blockFriends.value;
  }

  void clearChatHistory() async {
    var confirm = await Get.dialog(CustomDialog(
      title: StrRes.confirmClearChatHistory,
      rightText: StrRes.clearAll,
    ));
    if (confirm == true) {
      await OpenIM.iMManager.conversationManager
          .clearConversationAndDeleteAllMsg(
              conversationID: conversationInfo.value.conversationID ?? "");
      chatLogic.clearAllMessage();
      IMViews.showToast('清除成功');
    }
  }

  void toSelectGroupMember() {
    Get.bottomSheet(
      BottomSheetView(
        // itemBgColor: Styles.c_FFFFFF,
        items: [
          SheetItem(
            label: '普通群',
            onTap: () => AppNavigator.createGroup(
              defaultCheckedUidList: [conversationInfo.value.userID ?? ""],
            ),
          ),
          SheetItem(
            label: '大群',
            onTap: () => AppNavigator.createGroup(
              defaultCheckedUidList: [conversationInfo.value.userID ?? ""],
              groupType: GroupType.work,
            ),
          ),
        ],
      ),
    );
    // AppNavigator.startSelectContacts(
    //   action: SelAction.CRATE_GROUP,
    //   defaultCheckedUidList: [uid],
    // );
  }

  /// 消息免打扰
  /// 1: Do not receive messages, 2: Do not notify when messages are received; 0: Normal
  void setConversationRecvMessageOpt({int status = 2}) {
    LoadingView.singleton.wrap(
      asyncFunction: () =>
          OpenIM.iMManager.conversationManager.setConversationRecvMessageOpt(
        conversationID: 'single_${conversationInfo.value.userID ?? ""}',
        status: status,
      ),
    );
  }

  void noDisturbSetting() {
    IMViews.openNoDisturbSettingSheet(
      isGroup: false,
      onTap: (index) {
        setConversationRecvMessageOpt(status: index == 0 ? 2 : 1);
        noDisturbIndex.value = index;
      },
    );
  }

  /// 阅后即焚
  void togglePrivateChat() {
    LoadingView.singleton.wrap(asyncFunction: () async {
      await OpenIM.iMManager.conversationManager.setConversationPrivateChat(
        conversationID: conversationInfo.value.conversationID,
        isPrivate: !burnAfterReading.value,
      );
      // burnAfterReading.value = !burnAfterReading.value;
    });
  }

  String getBurnAfterReadingDuration() {
    int day = 1 * 24 * 60 * 60;
    int hour = 1 * 60 * 60;
    int fiveMinutes = 5 * 60;
    if (burnDuration.value == day) {
      return StrRes.oneDay;
    } else if (burnDuration.value == hour) {
      return StrRes.oneHour;
    } else if (burnDuration.value == fiveMinutes) {
      return StrRes.fiveMinutes;
    } else {
      return StrRes.thirtySeconds;
    }
  }

  void setBurnAfterReadingDuration() async {
    final result = await Get.bottomSheet(
      BottomSheetView(
        items: [
          SheetItem(
            label: StrRes.thirtySeconds,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
            result: 30,
          ),
          SheetItem(
            label: StrRes.fiveMinutes,
            result: 5 * 60,
          ),
          SheetItem(
            label: StrRes.oneHour,
            result: 60 * 60,
          ),
          SheetItem(
            label: StrRes.oneDay,
            result: 24 * 60 * 60,
          ),
        ],
      ),
    );
    if (result is int) {
      LoadingView.singleton.wrap(
          asyncFunction: () =>
              OpenIM.iMManager.conversationManager.setConversationBurnDuration(
                conversationID: conversationInfo.value.conversationID,
                burnDuration: result,
              ));
    }
  }

  void background() {
    AppNavigator.startSetChatBackground();
    /*IMWidget.openPhotoSheet(
      toUrl: false,
      crop: false,
      onData: (String path, String? url) async {
        String? value = await CommonUtil.createThumbnail(
          path: path,
          minWidth: 1.sw,
          minHeight: 1.sh,
        );
        if (null != value) chatLogic.changeBackground(value);
      },
    );*/
  }

  void fontSize() {
    AppNavigator.startFontSizeSetup();
  }
}
