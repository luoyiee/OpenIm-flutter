import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter_openim_sdk/flutter_openim_sdk.dart';
import 'package:get/get.dart';
import 'package:openim/pages/contacts/select_contacts/select_contacts_logic.dart';
import 'package:openim/pages/conversation/conversation_logic.dart';
import 'package:openim/routes/app_navigator.dart';
import 'package:openim/src/models/contacts_info.dart';
import 'package:openim_common/openim_common.dart';
import 'package:sprintf/sprintf.dart';

class CreateGroupInChatSetupLogic extends GetxController {
  var nameCtrl = TextEditingController(text: '群组');
  var memberList = <ContactsInfo>[].obs;
  var avatarUrl = ''.obs;
  var conversationLogic = Get.find<ConversationLogic>();
  late int groupType;

  @override
  void onInit() {
    var list = Get.arguments['members'];
    groupType = Get.arguments['groupType'];
    final info = memberList.value.firstWhereOrNull(
        (element) => element.userID == OpenIM.iMManager.userInfo.userID);
    memberList.value.addIf(info != null,
        ContactsInfo.fromJson(OpenIM.iMManager.userInfo.toJson()));
    memberList.addAll(list);
    super.onInit();
  }

  completeCreation() async {
    if (nameCtrl.text.trim().isEmpty) {
      IMViews.showToast('取个群名称方便后续搜索');
      return;
    }

    // 普通群限制
    if (groupType == GroupType.general &&
        memberList.length > Config.normalGroupMaxItems) {
      var confirm = await Get.dialog(CustomDialog(
        title: '群聊支持人数最多${Config.normalGroupMaxItems}人，若多人群聊，请创建大群',
        rightText: '马上去',
      ));
      if (confirm == true) {
        groupType = GroupType.work;
      } else {
        return;
      }
    }

    if (groupType == GroupType.work &&
        memberList.length > Config.workGroupMaxItems) {
      // 工作群限制
      Get.dialog(CustomDialog(
        title: '群聊支持人数最多${Config.workGroupMaxItems}人',
        // sprintf(
        //     StrRes.maxPersonWhenCreateGroup, []),
        rightText: '确定',
      ));
      return;
    }

    var info = await OpenIM.iMManager.groupManager.createGroup(
      groupInfo: GroupInfo(
          groupID: '',
          groupName: nameCtrl.text,
          faceURL: avatarUrl.value,
          groupType: groupType),
      memberUserIDs:
          // memberList.map((e) => GroupMemberRole(userID: e.userID)).toList(),
          memberList.map((e) => e.userID!).toList(),
    );
    print('create group :  ${jsonEncode(info)}  groupType : $groupType');
    conversationLogic.toChat(
      // type: 1,
      groupID: info.groupID,
      nickname: nameCtrl.text,
      faceURL: avatarUrl.value,
      sessionType: info.sessionType,
    );
  }

  void setAvatar() {
    IMViews.openPhotoSheet(onData: (path, url) {
      if (url != null) avatarUrl.value = url;
    });
  }

  int length() {
    return (memberList.length + 2) > 6 ? 6 : (memberList.length + 2);
  }

  Widget itemBuilder({
    required int index,
    required Widget Function(ContactsInfo info) builder,
    required Widget Function() addButton,
    required Widget Function() delButton,
  }) {
    if (memberList.length > 4) {
      if (index < 4) {
        var info = memberList.elementAt(index);
        return builder(info);
      } else if (index == 4) {
        return addButton();
      } else {
        return delButton();
      }
    } else {
      if (index < memberList.length) {
        var info = memberList.elementAt(index);
        return builder(info);
      } else if (index == memberList.length) {
        return addButton();
      } else {
        return delButton();
      }
    }
  }

  @override
  void onReady() {
    // TODO: implement onReady
    super.onReady();
  }

  @override
  void onClose() {
    nameCtrl.dispose();
    super.onClose();
  }

  void opMember() async {
    var myself =
        memberList.firstWhereOrNull((e) => e.userID == OpenIM.iMManager.userID);
    var list = await AppNavigator.startSelectContacts(
      action: SelAction.addMember,
      // defaultCheckedUidList: [OpenIM.iMManager.uid],
      // excludeUidList: [OpenIM.iMManager.uid],
      checkedList: memberList..remove(myself),
    );
    if (null != list) {
      memberList
        ..assignAll(list)
        ..insert(0, myself!);
    } else {
      memberList.insert(0, myself!);
    }
  }
}
