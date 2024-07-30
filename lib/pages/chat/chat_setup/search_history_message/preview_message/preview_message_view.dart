// import 'package:flutter/material.dart';
// import 'package:flutter_openim_sdk/flutter_openim_sdk.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:get/get.dart';
// import 'package:openim_common/openim_common.dart';
// import 'package:pull_to_refresh/pull_to_refresh.dart';
// import 'package:rxdart/rxdart.dart';
//
// import 'preview_message_logic.dart';
//
// class PreviewMessagePage extends StatelessWidget {
//   final logic = Get.find<PreviewMessageLogic>();
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Styles.c_FFFFFF,
//       appBar: TitleBar.chat(
//         title: logic.conversationInfo.showName,
//         showOnlineStatus: false,
//         showCallBtn: false,
//         showMoreButton: false,
//         onCloseMultiModel: () => Get.back(),
//       ),
//       body: Obx(() => SafeArea(
//             child: Column(
//               children: [
//                 Expanded(
//                   child: SmartRefresher(
//                     controller: logic.refreshController,
//                     footer: IMViews.buildFooter(),
//                     header: IMViews.buildHeader(),
//                     enablePullUp: true,
//                     enablePullDown: true,
//                     onLoading: logic.onLoad,
//                     onRefresh: logic.onRefresh,
//                     child: ListView.builder(
//                       controller: logic.scrollController,
//                       itemCount: logic.messageList.length,
//                       itemBuilder: (_, index) => Obx(
//                         () => _itemView(
//                           index,
//                           logic.indexOfMessage(index),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           )),
//     );
//   }
//
//   Widget _itemView(int index, Message message) => ChatItemView(
//         index: index,
//         message: message,
//         timeStr: logic.getShowTime(message),
//         messageTimeStr: IMUtils.getChatTimeline(message.sendTime!, 'HH:mm:ss'),
//         isSingleChat: logic.isSingleChat,
//         clickSubject: logic.clickSubject,
//         sendStatusSubject: logic.msgSendStatusSubject,
//         sendProgressSubject: logic.msgSendProgressSubject,
//         allAtMap: logic.getAtMapping(message),
//         delaySendingStatus: false,
//         enabledAddEmojiMenu: false,
//         enabledCopyMenu: false,
//         enabledDelMenu: false,
//         enabledForwardMenu: false,
//         enabledMultiMenu: false,
//         enabledReplyMenu: false,
//         enabledReadStatus: false,
//         enabledTranslationMenu: false,
//         enabledRevokeMenu: false,
//         isPrivateChat: false,
//         readingDuration: 0,
//         highlightColor: logic.getHighlightColor(message),
//         onTapLeftAvatar: () {
//           logic.onTapLeftAvatar(message);
//         },
//         onClickAtText: (uid) {
//           logic.clickAtText(uid);
//         },
//         onTapQuoteMsg: () {
//           logic.onTapQuoteMsg(message);
//         },
//         onTapCopyMenu: () {
//           logic.copy(message);
//         },
//         patterns: <MatchPattern>[
//           MatchPattern(
//             type: PatternType.at,
//             style: Styles.ts_1B72EC_14sp,
//             onTap: logic.clickLinkText,
//           ),
//           MatchPattern(
//             type: PatternType.email,
//             style: Styles.ts_1B72EC_14sp,
//             onTap: logic.clickLinkText,
//           ),
//           MatchPattern(
//             type: PatternType.url,
//             style: Styles.ts_1B72EC_14sp_underline,
//             onTap: logic.clickLinkText,
//           ),
//           MatchPattern(
//             type: PatternType.mobile,
//             style: Styles.ts_1B72EC_14sp,
//             onTap: logic.clickLinkText,
//           ),
//           MatchPattern(
//             type: PatternType.tel,
//             style: Styles.ts_1B72EC_14sp,
//             onTap: logic.clickLinkText,
//           ),
//         ],
//         customItemBuilder: _buildCustomItemView,
//         customMessageBuilder: _buildCustomMessageView,
//         isBubbleMsg: !logic.isNotificationType(message),
//         customLeftAvatarBuilder: () => _buildCustomLeftAvatar(message),
//         customRightAvatarBuilder: () => _buildCustomRightAvatar(message),
//         showNoticeMessage: false,
//         showLongPressMenu: false,
//         multiList: [],
//         multiSelMode: false,
//       );
//
//   /// 自定义消息
//   Widget? _buildCustomMessageView(
//     BuildContext context,
//     bool isReceivedMsg,
//     int index,
//     Message message,
//     Map<String, String> allAtMap,
//     double textScaleFactor,
//     List<MatchPattern> patterns,
//     Subject<MsgStreamEv<int>> msgSendProgressSubject,
//     Subject<int> clickSubject,
//   ) {
//     var data = IMUtils.parseCustomMessage(message);
//     if (null != data) {
//       var viewType = data['viewType'];
//       if (viewType == CustomMessageType.call) {
//         return _buildCallItemView(type: data['type'], content: data['content']);
//       } else if (viewType == CustomMessageType.tag) {
//         final url = data['url'];
//         final duration = data['duration'];
//         final text = data['text'];
//         if (text != null) {
//           return ChatAtText(
//             text: text,
//             textScaleFactor: textScaleFactor,
//             allAtMap: allAtMap,
//             patterns: patterns,
//           );
//         } else if (url != null) {
//           return ChatVoiceViewBase(
//             msgId: message.clientMsgID ?? "",
//             index: index,
//             clickStream: clickSubject.stream,
//             isReceived: isReceivedMsg,
//             soundPath: null,
//             soundUrl: url,
//             duration: duration,
//           );
//         }
//       }
//     }
//     return null;
//   }
//
//   /// custom item view
//   Widget? _buildCustomItemView(
//     BuildContext context,
//     int index,
//     Message message,
//   ) {
//     final text = IMUtils.parseNtf(message);
//     if (null != text) {
//       return _buildNotificationTipsView(text);
//     }
//     return null;
//   }
//
//   Widget _buildNotificationTipsView(String text) => Container(
//         alignment: Alignment.center,
//         child: ChatAtText(
//           text: text,
//           textStyle: Styles.ts_999999_12sp,
//           textAlign: TextAlign.center,
//         ),
//       );
//
//   /// 通话item
//   Widget _buildCallItemView({
//     required String type,
//     required String content,
//   }) =>
//       Row(
//         children: [
//           Image.asset(
//             type == 'audio'
//                 ? ImageRes.ic_voiceCallMsg
//                 : ImageRes.ic_videoCallMsg,
//             width: 20.h,
//             height: 20.h,
//           ),
//           SizedBox(width: 6.w),
//           Text(
//             content,
//             style: Styles.ts_333333_14sp,
//           ),
//         ],
//       );
//
//   /// 自定义头像
//   Widget? _buildCustomLeftAvatar(Message message) {
//     return AvatarView(
//       width: 42.h,
//       height: 42.h,
//       url: message.senderFaceUrl,
//       text: message.senderNickname,
//       textStyle: Styles.ts_FFFFFF_14sp,
//     );
//   }
//
//   Widget? _buildCustomRightAvatar(Message message) {
//     return AvatarView(
//       width: 42.h,
//       height: 42.h,
//       url: OpenIM.iMManager.userInfo.faceURL,
//       text: OpenIM.iMManager.userInfo.nickname,
//       textStyle: Styles.ts_FFFFFF_14sp,
//     );
//   }
// }
