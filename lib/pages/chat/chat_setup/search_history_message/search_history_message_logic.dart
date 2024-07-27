import 'package:flutter/cupertino.dart';
import 'package:flutter_openim_sdk/flutter_openim_sdk.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:sprintf/sprintf.dart';

import '../../../../routes/app_navigator.dart';

class SearchHistoryMessageLogic extends GetxController {
  final refreshController = RefreshController(initialRefresh: false);
  var searchCtrl = TextEditingController();
  var focusNode = FocusNode();
  late ConversationInfo info;
  var messageList = <Message>[].obs;
  var key = "".obs;
  var pageIndex = 1;
  var pageSize = 50;

  @override
  void dispose() {
    searchCtrl.dispose();
    focusNode.dispose();
    super.dispose();
  }

  @override
  void onInit() {
    info = Get.arguments;
    super.onInit();
  }

  bool isNotKey() => key.value.trim().isEmpty;

  void onChanged(String value) {
    key.value = value;
    if (value.trim().isNotEmpty) {
      search(value.trim());
    }
  }

  void clear() {
    key.value = '';
    messageList.clear();
  }

  void search(key) async {
    try {
      var result = await OpenIM.iMManager.messageManager.searchLocalMessages(
        conversationID: info.conversationID,
        keywordList: [key],
        pageIndex: pageIndex = 1,
        count: pageSize,
        messageTypeList: [MessageType.text, MessageType.atText],
      );
      print("result:${result.totalCount}");
      if (result.totalCount == 0) {
        messageList.clear();
      } else {
        var item = result.searchResultItems!.first;
        messageList.assignAll(item.messageList!);
      }
    } finally {
      if (messageList.length < pageIndex * pageSize) {
        refreshController.loadNoData();
      }
    }
  }

  load() async {
    try {
      var result = await OpenIM.iMManager.messageManager.searchLocalMessages(
        conversationID: info.conversationID,
        keywordList: [searchCtrl.text.trim()],
        pageIndex: ++pageIndex,
        count: pageSize,
        messageTypeList: [MessageType.text, MessageType.atText],
      );
      if (result.totalCount! > 0) {
        var item = result.searchResultItems!.first;
        messageList.addAll(item.messageList!);
      }
    } finally {
      if (messageList.length < (pageSize * pageIndex)) {
        refreshController.loadNoData();
      } else {
        refreshController.loadComplete();
      }
    }
  }

  /// 中英文案
  Widget noFoundText() {
    var key = searchCtrl.text.trim();
    // var noFound = sprintf(StrRes.noFoundMessage, ["#"]);
    var noFound = '没有找到“#”相关结果';
    var index = noFound.indexOf("#");
    print('noFound:$noFound   index:$index');
    var start = noFound.substring(0, index);
    var end = '';
    if (index + 1 < noFound.length) {
      end = noFound.substring(index + 1);
    }
    return RichText(
      text: TextSpan(
        children: [
          if (start.isNotEmpty)
            TextSpan(text: start, style: Styles.ts_666666_16sp),
          TextSpan(text: key, style: Styles.ts_1B61D6_16sp),
          if (end.isNotEmpty) TextSpan(text: end, style: Styles.ts_666666_16sp),
        ],
      ),
    );
  }

  String calContent(Message message) {
    String content = IMUtils.parseMsg(message, replaceIdToNickname: true);
    // 左右间距+头像跟名称的间距+头像dax
    var usedWidth = 22.w * 2 + 12.w + 42.h;
    return IMUtils.calContent(
      content: content,
      key: key.value,
      style: Styles.ts_666666_14sp,
      usedWidth: usedWidth,
    );
  }

  void searchFile() {
    AppNavigator.startSearchFile(info: info);
  }

  void searchPicture() {
    AppNavigator.startSearchPicture(info: info, type: 0);
  }

  void searchVideo() {
    AppNavigator.startSearchPicture(info: info, type: 1);
  }

  void previewMessageHistory(Message message) async {
    // var list =
    //     await OpenIM.iMManager.conversationManager.getMultipleConversation(
    //   conversationIDList: [searchResultItems.conversationID!],
    // );
    // conversationLogic.startChat(
    //   userID: list.first.userID,
    //   groupID: list.first.groupID,
    //   nickname: searchResultItems.showName!,
    //   faceURL: searchResultItems.faceURL,
    //   conversationInfo: list.first,
    //   searchMessage: message
    // );
    AppNavigator.startPreviewChatHistory(
      conversationInfo: ConversationInfo(
        conversationID: info.conversationID,
        showName: info.showName,
        faceURL: info.faceURL,
      ),
      message: message,
    );
  }
}
