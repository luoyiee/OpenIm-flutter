import 'package:flutter/material.dart';
import 'package:flutter_openim_sdk/flutter_openim_sdk.dart';
import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';

import 'chat_logic.dart';

class ChatPage extends StatelessWidget {
  final logic = Get.find<ChatLogic>(tag: GetTags.chat);

  ChatPage({super.key});

  Widget _buildItemView(Message message, int index) => ChatItemView(
        key: logic.itemKey(message),
        index: index,
        message: message,
        timeStr: logic.getShowTime(message),
        messageTimeStr: IMUtils.getChatTimeline(message.sendTime!, 'HH:mm:ss'),
        isSingleChat: logic.isSingleChat,
        clickSubject: logic.clickSubject,

        sendStatusSubject: logic.sendStatusSub,
        sendProgressSubject: logic.sendProgressSub,
        popPageCloseMenuSubject: logic.forceCloseMenuSub,
        multiSelMode: logic.showCheckbox(message),
        multiList: logic.multiSelList.value,
        allAtMap: logic.getAtMapping(message),
        delaySendingStatus: true,

        ///字体设置【拓展】
        textScaleFactor: logic.scaleFactor.value,
        isPrivateChat: logic.isPrivateChat(message),
        readingDuration: logic.readTime(message),
        isPlayingSound: logic.isPlaySound(message),
        onFailedToResend: () => logic.failedResend(message),
        onDestroyMessage: () {
          logic.deleteMsg(message);
        },
        onViewMessageReadStatus: () {
          logic.viewGroupMessageReadStatus(message);
        },
        onMultiSelChanged: (checked) {
          logic.multiSelMsg(message, checked);
        },

        onTapCopyMenu: () {
          logic.copy(message);
        },
        onTapDelMenu: () {
          logic.deleteMsg(message);
        },
        onTapForwardMenu: () {
          // logic.onTapForwordMessage(message);
          logic.forward(message);
        },
        onTapReplyMenu: () {
          logic.setQuoteMsg(message);
        },
        onTapRevokeMenu: () {
          logic.revokeMessage(message);
        },
        onTapMultiMenu: () {
          logic.openMultiSelMode(message);
        },
        onTapAddEmojiMenu: () {
          logic.addEmoji(message);
        },

        onTapSpeakerMenu: () {
          logic.playSpeaker(message);
        },

        onTapSpeaker2SpeedMenu: () {
          logic.speaker2Speed(message);
        },

        // visibilityChange: (context, index, message, visible) {
        //   logic.markMessageAsRead(message, visible);
        // },

        timelineStr: logic.getShowTime(message),

        leftNickname: logic.getNewestNickname(message),
        leftFaceUrl: logic.getNewestFaceURL(message),
        rightNickname: OpenIM.iMManager.userInfo.nickname,
        rightFaceUrl: OpenIM.iMManager.userInfo.faceURL,
        showLeftNickname: !logic.isSingleChat,
        showRightNickname: false,

        playingStateStream: logic.playingStateStream,

        onClickItemView: () => logic.parseClickEvent(message),

        onLongPressLeftAvatar: () {
          logic.onLongPressLeftAvatar(message);
        },
        onLongPressRightAvatar: () {},
        onTapLeftAvatar: () {
          logic.onTapLeftAvatar(message);
        },
        onTapRightAvatar: logic.onTapRightAvatar,

        onClickAtText: (uid) {
          logic.clickAtText(uid);
        },
        onTapQuoteMsg: () {
          logic.onTapQuoteMsg(message);
        },

        onVisibleTrulyText: (text) {},
        customTypeBuilder: _buildCustomTypeItemView,
        enabledTranslationMenu: false,
        enabledCopyMenu: logic.showCopyMenu(message),
        enabledRevokeMenu: logic.showRevokeMenu(message),
        enabledReplyMenu: logic.showReplyMenu(message),
        enabledMultiMenu: logic.showMultiMenu(message),
        enabledForwardMenu: logic.showForwardMenu(message),
        enabledDelMenu: logic.showDelMenu(message),
        enabledAddEmojiMenu: logic.showAddEmojiMenu(message),
        enabledSpeakerMenu: logic.showSpeakerMenu(message),
        enabledSpeaker2SpeedMenu: logic.showSpeaker2SpeedMenu(message),
        showNoticeMessage: true,
        showLongPressMenu: !logic.isMuted,

        enabledReadStatus: logic.enabledReadStatus(message),

        // leftBubbleColor: null,
        // rightBubbleColor: null,

        isBubbleMsg: !logic.isNotificationType(message) &&
            !logic.isFailedHintMessage(message),
      );

  CustomTypeInfo? _buildCustomTypeItemView(_, Message message) {
    final data = IMUtils.parseCustomMessage(message);
    if (null != data) {
      final viewType = data['viewType'];
      if (viewType == CustomMessageType.call) {
        final type = data['type'];
        final content = data['content'];
        final view = ChatCallItemView(type: type, content: content);
        return CustomTypeInfo(view);
      } else if (viewType == CustomMessageType.deletedByFriend ||
          viewType == CustomMessageType.blockedByFriend) {
        final view = ChatFriendRelationshipAbnormalHintView(
          name: logic.nickname.value,
          onTap: logic.sendFriendVerification,
          blockedByFriend: viewType == CustomMessageType.blockedByFriend,
          deletedByFriend: viewType == CustomMessageType.deletedByFriend,
        );
        return CustomTypeInfo(view, false, false);
      } else if (viewType == CustomMessageType.removedFromGroup) {
        return CustomTypeInfo(
          StrRes.removedFromGroupHint.toText..style = Styles.ts_8E9AB0_12sp,
          false,
          false,
        );
      } else if (viewType == CustomMessageType.groupDisbanded) {
        return CustomTypeInfo(
          StrRes.groupDisbanded.toText..style = Styles.ts_8E9AB0_12sp,
          false,
          false,
        );
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() => WillPopScope(
        onWillPop: logic.willPop(),
        child: ChatVoiceRecordLayout(
            locale: Get.locale,
            maxRecordSec: 60,
            builder: (bar) => Obx(
                  () => Scaffold(
                    appBar: TitleBar.chat(
                      title: logic.title,
                      subTitle: logic.subTile,
                      onCloseMultiModel: logic.exit,
                      onClickMoreBtn: logic.chatSetup,
                      onClickCallBtn: logic.call,
                    ),
                    body: WaterMarkBgView(
                      // text: logic.markText,
                      backgroundColor: Styles.c_FFFFFF,
                      path: logic.background.value,
                      bottomView: ChatInputBox(
                        allAtMap: logic.atUserNameMappingMap,
                        controller: logic.inputCtrl,
                        focusNode: logic.focusNode,
                        isMultiModel: logic.multiSelMode.value,
                        inputFormatters: [AtTextInputFormatter(logic.openAtList)],
                        muteEndTime: logic.muteEndTime.value,
                        isInBlacklist: logic.isSingleChat ? logic.isInBlacklist.value : false,

                        isNotInGroup: logic.isInvalidGroup,
                        onSend: (v) => logic.sendTextMsg(),
                        toolbox: ChatToolBox(
                          onTapAlbum: logic.onTapAlbum,
                          onTapCamera: logic.onTapCamera,
                          onTapCall: logic.call,
                          onTapFile: logic.onTapFile,
                          onTapCard: logic.onTapCard,
                          onTapLocation: logic.onTapLocation,
                          onStopVoiceInput: () => logic.onStopVoiceInput(),
                          onStartVoiceInput: () => logic.onStartVoiceInput(),
                        ),
                        multiOpToolbox: ChatMultiSelToolbox(
                          onDelete: () => logic.mergeDelete(),
                          onMergeForward: () => logic.mergeForward(),
                        ),
                        emojiView: ChatEmojiView(
                          onAddEmoji: logic.onAddEmoji,
                          onDeleteEmoji: logic.onDeleteEmoji,
                          onAddFavorite: () => logic.emojiManage(),
                          // favoriteList: logic.cacheLogic.urlList,
                          // onSelectedFavorite: logic.sendCustomEmoji,
                          textEditingController: logic.inputCtrl,
                        ),
                        voiceRecordBar: bar,
                      ),
                      child: ChatListView(
                        itemCount: logic.messageList.length,
                        controller: logic.scrollController,
                        onScrollToBottomLoad: logic.onScrollToBottomLoad,
                        onScrollToTop: logic.onScrollToTop,
                        itemBuilder: (_, index) {
                          final message = logic.indexOfMessage(index);
                          return _buildItemView(message, index);
                        },
                      ),
                    ),
                  ),
                ),
            onCompleted: (sec, path) {
              logic.sendVoice(duration: sec, path: path);
            })));
  }
}
