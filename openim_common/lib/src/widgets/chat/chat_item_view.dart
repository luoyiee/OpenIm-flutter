import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_openim_sdk/flutter_openim_sdk.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:openim_common/src/utils/common_util.dart';
import 'package:openim_common/src/widgets/chat/plus/chat_notice_view.dart';
import 'package:openim_common/src/widgets/chat/plus/chat_read_tag.dart';
import 'package:openim_common/src/widgets/chat/self/chat_file_picture_view.dart';
import 'package:openim_common/src/widgets/chat/self/chat_file_video_view.dart';
import 'package:openim_common/src/widgets/chat/self/chat_file_view.dart';
import 'package:rxdart/rxdart.dart';

import '../../utils/betaTestLogic.dart';
import 'plus/ChatVoiceView.dart';
import 'plus/chat_revoke_view.dart';
import 'plus/chat_voice_read_status_view.dart';
import 'self/chat_at_text.dart' as prefix;
import 'self/chat_carte_view.dart';
import 'self/chat_custom_emoji_view.dart';
import 'self/chat_item_container_new.dart';
import 'self/chat_item_single_view.dart';
import 'self/chat_location_view.dart';
import 'self/chat_menu.dart';
import 'self/chat_merge_view.dart';
import 'self/chat_quote_view.dart';
import 'self/chat_voice_view.dart';

// double maxWidth = 247.w;
double maxWidth = 219.w;
double maxWidthContainer = 243.w;
double pictureWidth = 120.w;
double videoWidth = 120.w;
double locationWidth = 220.w;

BorderRadius borderRadius(bool isISend) => BorderRadius.only(
      topLeft: Radius.circular(isISend ? 6.r : 6.r),
      topRight: Radius.circular(isISend ? 6.r : 6.r),
      bottomLeft: Radius.circular(6.r),
      bottomRight: Radius.circular(6.r),
    );

class MsgStreamEv<T> {
  final String id;
  final T value;

  MsgStreamEv({required this.id, required this.value});

  @override
  String toString() {
    return 'MsgStreamEv{msgId: $id, value: $value}';
  }
}

class CustomTypeInfo {
  final Widget customView;
  final bool needBubbleBackground;
  final bool needChatItemContainer;

  CustomTypeInfo(
    this.customView, [
    this.needBubbleBackground = true,
    this.needChatItemContainer = true,
  ]);
}

typedef CustomTypeBuilder = CustomTypeInfo? Function(
  BuildContext context,
  Message message,
);
typedef NotificationTypeBuilder = Widget? Function(
  BuildContext context,
  Message message,
);
typedef ItemViewBuilder = Widget? Function(
  BuildContext context,
  Message message,
);
typedef ItemVisibilityChange = void Function(
  Message message,
  bool visible,
);

typedef CustomItemBuilder = Widget? Function(
  BuildContext context,
  int index,
  Message message,
);

/// MessageType.custom
typedef CustomMessageBuilder = Widget? Function(
  BuildContext context,
  bool isReceivedMsg,
  int index,
  Message message,
  Map<String, String> allAtMap,
  double textScaleFactor,
  List<MatchPattern> patterns,
  Subject<MsgStreamEv<int>> msgSendProgressSubject,
  Subject<int> clickSubject,
);

class ChatItemView extends StatefulWidget {
  const ChatItemView(
      {super.key,
      this.mediaItemBuilder,
      this.itemViewBuilder,
      this.customTypeBuilder,
      this.notificationTypeBuilder,
      this.sendStatusSubject,
      this.sendProgressSubject,
      this.timelineStr,
      this.leftNickname,
      this.leftFaceUrl,
      this.rightNickname,
      this.rightFaceUrl,
      required this.message,
      this.textScaleFactor = 1.0,
      this.ignorePointer = false,
      this.showLeftNickname = true,
      this.showRightNickname = false,
      this.highlightColor,
      this.allAtMap = const {},
      this.patterns = const [],
      this.onTapLeftAvatar,
      this.onTapRightAvatar,
      this.onLongPressLeftAvatar,
      this.onLongPressRightAvatar,
      this.onVisibleTrulyText,
      this.onFailedToResend,
      this.onClickItemView,
      // required this.index,
      this.menus,
      // this.menuStyle,
      this.enabledCopyMenu = true,
      this.enabledDelMenu = true,
      this.enabledForwardMenu = true,
      this.enabledReplyMenu = true,
      this.enabledRevokeMenu = true,
      this.enabledMultiMenu = true,
      this.enabledTranslationMenu = false,
      this.enabledAddEmojiMenu = true,
      this.onTapCopyMenu,
      this.onTapDelMenu,
      this.onTapForwardMenu,
      this.onTapReplyMenu,
      this.onTapRevokeMenu,
      this.onTapMultiMenu,
      this.onTapTranslationMenu,
      this.onTapAddEmojiMenu,
      this.onTapSpeakerMenu,
      this.onTapSpeaker2SpeedMenu,
      // required this.showNoticeMessage,
      this.showLongPressMenu = true,
      this.customLeftAvatarBuilder,
      this.customRightAvatarBuilder,
      this.checkedList = const [],
      this.isMultiSelMode = false,
      this.onMultiSelChanged,
      // required this.delaySendingStatus,
      this.enabledReadStatus = true,
      this.isPrivateChat = false,
      this.onDestroyMessage,
      this.readingDuration = 30,
      this.onViewMessageReadStatus,
      this.onTapQuoteMsg,
      this.timeDecoration,
      this.timePadding,
      this.timeStr,
      this.messageTimeStr,
      this.onClickAtText,
      // this.leftBubbleColor,
      // this.rightBubbleColor,
      // required this.clickSubject,
      // required this.isSingleChat,
      this.avatarSize,
      this.timeStyle,
      this.onPopMenuShowChanged,
      this.popPageCloseMenuSubject,
      this.customItemBuilder,
      // required this.isBubbleMsg,
      this.textStyle,
      this.isPlayingSound = false,
      this.enabledSpeakerMenu = false,
      this.enabledSpeaker2SpeedMenu = false,
      this.canReEdit = false,
      this.playingStateStream,
      this.customMessageBuilder,
      this.closePopMenuSubject,
      this.ChatFileDownloadProgressView,
      this.onReEit,
      this.onTapQuoteMessage,
      this.onTapUnTranslateMenu,
      this.enabledTtsMenu = false,
      this.enabledUnTranslateMenu = false,
      this.enabledUnTtsMenu = false,
      this.onTapUnTtsMenu,
      this.showRead});

  final ItemViewBuilder? mediaItemBuilder;
  final ItemViewBuilder? itemViewBuilder;
  final CustomTypeBuilder? customTypeBuilder;
  final NotificationTypeBuilder? notificationTypeBuilder;
  final Subject<MsgStreamEv<bool>>? sendStatusSubject;
  final Subject<MsgStreamEv<int>>? sendProgressSubject;
  final String? timelineStr;
  final String? leftNickname;
  final String? leftFaceUrl;
  final String? rightNickname;
  final String? rightFaceUrl;
  final Message message;

  /// 消息时间的样式
  final TextStyle? timeStyle;

  /// if current is group chat : false
  /// if current is single chat : true
  /// true 单聊，false 群聊
  // final bool isSingleChat;

  /// 头像大小
  final double? avatarSize;

  /// 被选择的消息
  final List<Message> checkedList;

  /// listview index
  // final int index;

  /// long press menu list
  /// 长按消息起泡弹出的菜单列表
  final List<MenuInfo>? menus;

  // /// menu list style
  // /// 菜单样式
  // final MenuStyle? menuStyle;

  /// Click the copy button event on the menu
  final bool enabledCopyMenu;

  /// Click the delete button event on the menu
  final bool enabledDelMenu;

  /// Click the forward button event on the menu
  final bool enabledForwardMenu;

  /// Click the reply button event on the menu
  final bool enabledReplyMenu;

  /// Click the revoke button event on the menu
  final bool enabledRevokeMenu;

  ///
  final bool enabledMultiMenu;

  ///
  final bool enabledTranslationMenu;
  final bool enabledUnTranslateMenu;
  final bool enabledTtsMenu;
  final bool enabledUnTtsMenu;

  ///
  final bool enabledAddEmojiMenu;

  final bool enabledSpeakerMenu;
  final bool enabledSpeaker2SpeedMenu;

  /// Click the copy button event on the menu
  final Function()? onTapCopyMenu;

  /// Click the delete button event on the menu
  final Function()? onTapDelMenu;

  /// Click the forward button event on the menu
  final Function()? onTapForwardMenu;

  /// Click the reply button event on the menu
  final Function()? onTapReplyMenu;

  /// Click the revoke button event on the menu
  final Function()? onTapRevokeMenu;

  ///
  final Function()? onTapMultiMenu;

  ///
  final Function()? onTapTranslationMenu;

  ///
  final Function()? onTapAddEmojiMenu;

  final Function()? onTapSpeakerMenu;

  final Function()? onTapSpeaker2SpeedMenu;

  /// 将公告消息做普通消息显示
  // final bool showNoticeMessage;

  /// 自定义头像
  final CustomAvatarBuilder? customLeftAvatarBuilder;
  final CustomAvatarBuilder? customRightAvatarBuilder;

  /// 显示长按菜单
  final bool showLongPressMenu;

  final double textScaleFactor;

  final bool ignorePointer;
  final bool showLeftNickname;
  final bool showRightNickname;

  final Color? highlightColor;
  final Map<String, String> allAtMap;
  final List<MatchPattern> patterns;
  final Function()? onTapLeftAvatar;
  final Function()? onTapRightAvatar;
  final Function()? onLongPressLeftAvatar;
  final Function()? onLongPressRightAvatar;
  final Function(String? text)? onVisibleTrulyText;
  final Function()? onClickItemView;
  final Function()? onTapUnTranslateMenu;
  final Function()? onTapUnTtsMenu;

  /// MessageType.custom
  final CustomMessageBuilder? customMessageBuilder;

  /// 点击@内容
  final ValueChanged<String>? onClickAtText;

  /// Style of text content
  /// 文字消息的样式
  final TextStyle? textStyle;

  // /// Message background on the left side of the chat window
  // /// 收到的消息的气泡的背景色
  // final Color leftBubbleColor;
  //
  // /// Message background on the right side of the chat window
  // /// 发送的消息的气泡背景色
  // final Color rightBubbleColor;

  /// Click on the message to process voice playback, video playback, picture preview, etc.
  // final Subject<int> clickSubject;

  /// 时间装饰
  final BoxDecoration? timeDecoration;

  /// 上下间距
  final EdgeInsetsGeometry? timePadding;

  ///
  final String? timeStr;

  /// 每条消息时间
  final String? messageTimeStr;

  /// 当前是否是多选模式
  final bool isMultiSelMode;

  final Function(Message message)? onTapQuoteMessage;

  ///
  final Function(bool checked)? onMultiSelChanged;

  /// 是否在发送消息时，延迟显示消息发送中状态，既延迟显示加载框
  // final bool delaySendingStatus;

  /// 显示消息已读
  final bool enabledReadStatus;

  /// 是否开启阅后即焚
  final bool isPrivateChat;

  final bool? showRead;

  /// 阅后即焚回调
  final Function()? onDestroyMessage;

  /// 阅读时长s
  final int readingDuration;

  /// 预览群消息已读状态
  final Function()? onViewMessageReadStatus;

  /// 失败重发
  final Function()? onFailedToResend;

  ///
  final Function()? onTapQuoteMsg;

  final Function(bool show)? onPopMenuShowChanged;

  /// 点击系统软键盘返回键关闭菜单
  final Subject<bool>? popPageCloseMenuSubject;

  /// Customize the display style of messages,
  /// such as system messages or status messages such as withdrawal
  /// 自定义消息item view
  final CustomItemBuilder? customItemBuilder;

  /// When you need to customize the message style,
  /// Whether to use a bubble container
  /// 自定义消息item view时，是否使用默认的起泡背景
  // final bool isBubbleMsg;

  /// 当前播放的语音消息
  final bool isPlayingSound;

  final bool canReEdit;
  final Function()? onReEit;

  final Stream<String>? playingStateStream; // 添加这个参数

  /// 点击系统软键盘返回键关闭菜单
  final Subject<bool>? closePopMenuSubject;

  /// 文件下载精度
  final Widget? ChatFileDownloadProgressView;

  @override
  State<ChatItemView> createState() => _ChatItemViewState();
}

class _ChatItemViewState extends State<ChatItemView> {
  Message get _message => widget.message;
  final _popupCtrl = CustomPopupMenuController();
  final _popupTranslateMenuCtrl = CustomPopupMenuController();
  // final betaTestLogic = Get.find<BetaTestLogic>();

  bool get _isISend => _message.sendID == OpenIM.iMManager.userID;

  // bool get _isFromMsg => widget.message.sendID != OpenIM.iMManager.uid;
  //
  bool get _isChecked => widget.checkedList.contains(widget.message);

  late StreamSubscription<bool> _keyboardSubs;
  StreamSubscription<bool>? _closeMenuSubs;

  // bool get showMd =>
  //     (_message.isTextType || _message.isAtTextType) &&
  //     betaTestLogic.isBot(_message.sendID ?? "") &&
  //     betaTestLogic.openChatMd.value;

  @override
  void dispose() {
    _keyboardSubs.cancel();
    super.dispose();
  }

  @override
  void initState() {
    final keyboardVisibilityCtrl = KeyboardVisibilityController();

    _keyboardSubs = keyboardVisibilityCtrl.onChange.listen((bool visible) {
      print('Keyboard visibility update. Is visible: $visible');
      _popupCtrl.hideMenu();
    });

    _popupCtrl.addListener(() {
      widget.onPopMenuShowChanged?.call(_popupCtrl.menuIsShowing);
    });

    _closeMenuSubs = widget.popPageCloseMenuSubject?.listen((value) {
      if (value == true) {
        _popupCtrl.hideMenu();
      }
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // Widget? child;
    // // custom view
    // var view = _customItemView();
    // if (null != view) {
    //   if (widget.isBubbleMsg) {
    //     child = _buildCommonItemView(child: view);
    //   } else {
    //     child = view;
    //   }
    // } else {
    //   child = _buildChildView();
    // }
    return FocusDetector(
      child: Container(
        color: widget.highlightColor,
        margin: EdgeInsets.only(bottom: 20.h),
        padding: EdgeInsets.symmetric(horizontal: 10.w),
        child: Center(child: _child),
      ),
      onVisibilityLost: () {},
      onVisibilityGained: () {},
    );
  }

  Widget get _child =>
      widget.itemViewBuilder?.call(context, _message) ?? _buildChildView();

  Widget _buildChildView() {
    Widget? child;
    String? senderNickname;
    String? senderFaceURL;
    bool isBubbleBg = false;
    if (_message.isTextType) {
      isBubbleBg = true;
      child = ChatText(
        text: _message.textElem!.content!,
        textStyle: widget.textStyle,
        patterns: widget.patterns,
        textScaleFactor: widget.textScaleFactor,
        onVisibleTrulyText: widget.onVisibleTrulyText,
        isISend: _isISend,
        selectMode: true,
        onSelectionChanged: ({SelectedContent? selectedContent}) =>
            onSelectionChanged(_popupCtrl, selectedContent: selectedContent),
      );
    } else if (_message.isAtTextType) {
      isBubbleBg = true;
      child = ChatText(
        text: _message.atTextElem!.text!,
        // allAtMap: widget.allAtMap,
        allAtMap: IMUtils.getAtMapping(_message, widget.allAtMap),
        patterns: widget.patterns,
        textScaleFactor: widget.textScaleFactor,
        onVisibleTrulyText: widget.onVisibleTrulyText,
        isISend: _isISend,
        selectMode: true,
        onSelectionChanged: ({SelectedContent? selectedContent}) =>
            onSelectionChanged(_popupCtrl, selectedContent: selectedContent),
        // textStyle: widget.textStyle,
        // ),
      );
    } else if (_message.isPictureType) {
      child = widget.mediaItemBuilder?.call(context, _message) ??
          ChatPictureView(
            isISend: _isISend,
            message: _message,
            sendProgressStream: widget.sendProgressSubject,
          );
    } else if (_message.isVoiceType) {
      isBubbleBg = true;
      final sound = _message.soundElem;
      child = ChatVoiceView(
        isISend: _isISend,
        soundPath: sound?.soundPath,
        soundUrl: sound?.sourceUrl,
        duration: sound?.duration,
        isPlaying: widget.isPlayingSound,
      );
    } else if (_message.isVideoType) {
      child = widget.mediaItemBuilder?.call(context, _message) ??
          ChatVideoView(
            isISend: _isISend,
            message: _message,
            sendProgressStream: widget.sendProgressSubject,
          );
    } else if (_message.isFileType) {
      // var file = widget.message.fileElem;
      // if (file != null) {
      //   final mimeType = CommonUtil.getMediaType(file.fileName!);
      //   if (mimeType != null && mimeType.startsWith('image/')) {
      //     child = ChatFilePictureView(
      //       isISend: _isISend,
      //       message: _message,
      //       sendProgressStream: widget.sendProgressSubject,
      //     );
      //   } else if (mimeType != null && mimeType.startsWith('audio/')) {
      //     child = ChatFileVideoView(
      //       isISend: _isISend,
      //       message: _message,
      //       sendProgressStream: widget.sendProgressSubject,
      //     );
      //   } else {
      //     child = ChatFileView(
      //       msgId: widget.message.clientMsgID!,
      //       fileName: file.fileName!,
      //       bytes: file.fileSize ?? 0,
      //       width: 158.w,
      //       initProgress: 100,
      //       uploadStream: widget.sendProgressSubject,
      //     );
      //   }
      // }
      child = ChatFileView(
        message: _message,
        isISend: _isISend,
        sendProgressStream: widget.sendProgressSubject,
        ChatFileDownloadProgressView: widget.ChatFileDownloadProgressView,
      );
    } else if (_message.isLocationType) {
      var location = widget.message.locationElem;
      child = ChatLocationView(
        description: location!.description!,
        latitude: location.latitude!,
        longitude: location.longitude!,
      );
    } else if (_message.isQuoteType) {
      isBubbleBg = true;
      child = ChatText(
        text: widget.message.quoteElem?.text ?? '',
        // allAtMap: widget.allAtMap,
        allAtMap: IMUtils.getAtMapping(_message, widget.allAtMap),
        // textStyle: widget.textStyle,
        patterns: widget.patterns,
        textScaleFactor: widget.textScaleFactor,
        onVisibleTrulyText: widget.onVisibleTrulyText,
        isISend: _isISend,
        selectMode: true,
        onSelectionChanged: ({SelectedContent? selectedContent}) =>
            onSelectionChanged(_popupCtrl, selectedContent: selectedContent),
      );
    } else if (_message.isMergerType) {
      child = ChatMergeMsgView(
        title: widget.message.mergeElem?.title ?? '',
        summaryList: widget.message.mergeElem?.abstractList ?? [],
      );
    } else if (_message.isCardType) {
      child = ChatCarteView(cardElem: _message.cardElem!);
    } else if (_message.isCustomFaceType) {
      final face = _message.faceElem;
      child = ChatCustomEmojiView(
        index: face?.index,
        data: face?.data,
        isISend: _isISend,
        heroTag: _message.clientMsgID,
      );
    } else if (_message.isCustomType) {
      final info = widget.customTypeBuilder?.call(context, _message);
      if (null != info) {
        isBubbleBg = info.needBubbleBackground;
        child = info.customView;
        if (!info.needChatItemContainer) {
          return child;
        }
      }
    } else if (_message.isRevokeType) {
      return child = ChatRevokeView(
        message: _message,
        onReEdit: widget.onReEit,
        canReEdit: widget.canReEdit,
      );
    } else if (_message.isNotificationType) {
      if (_message.contentType ==
          MessageType.groupInfoSetAnnouncementNotification) {
        final map = json.decode(_message.notificationElem!.detail!);
        final ntf = GroupNotification.fromJson(map);
        final noticeContent = ntf.group?.notification;
        senderNickname = ntf.opUser?.nickname;
        senderFaceURL = ntf.opUser?.faceURL;
        child = ChatNoticeView(isISend: _isISend, content: noticeContent!);
      } else {
        return ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: ChatHintTextView(message: _message),
        );
      }
    }
    // md测试
    // if (showMd) {
    //   // child = _buildMarkdown();
    // }
    senderNickname ??= widget.leftNickname ?? _message.senderNickname;
    senderFaceURL ??= widget.leftFaceUrl ?? _message.senderFaceUrl;
    return child = ChatItemContainer(
      message: _message,
      id: _message.clientMsgID!,
      isISend: _isISend,
      leftNickname: senderNickname,
      leftFaceUrl: senderFaceURL,
      rightNickname: widget.rightNickname ?? OpenIM.iMManager.userInfo.nickname,
      rightFaceUrl: widget.rightFaceUrl ?? OpenIM.iMManager.userInfo.faceURL,
      showLeftNickname: widget.showLeftNickname,
      showRightNickname: widget.showRightNickname,
      timelineStr: widget.timelineStr,
      timeStr: IMUtils.getChatTimeline(_message.sendTime!, 'HH:mm:ss'),
      hasRead: _message.isRead!,
      isSending: _message.status == MessageStatus.sending,
      isSendFailed: _message.status == MessageStatus.failed,
      isMultiSelModel: widget.isMultiSelMode,
      isChecked: _isChecked,
      isBubbleBg: child == null ? true : isBubbleBg,
      menus: widget.showLongPressMenu ? _menusItem : [],
      isPrivateChat: widget.isPrivateChat,
      ignorePointer: widget.ignorePointer,
      onStartDestroy: widget.onDestroyMessage,
      readingDuration: widget.readingDuration,
      sendStatusStream: widget.sendStatusSubject,
      onRadioChanged: widget.onMultiSelChanged,
      onFailedToResend: widget.onFailedToResend,
      onLongPressLeftAvatar: widget.onLongPressLeftAvatar,
      onLongPressRightAvatar: widget.onLongPressRightAvatar,
      onTapLeftAvatar: widget.onTapLeftAvatar,
      onTapRightAvatar: widget.onTapRightAvatar,
      // showRadio: widget.multiSelMode,
      // menuBuilder: _menuBuilder,
      // popupCtrl: _popupCtrl,
      quoteView: _quoteMsgView,
      translateView: _translateView,
      ttsView: _ttsView,
      readStatusView: _readStatusView,
      voiceReadStatusView: _voiceReadStatusView,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: widget.onClickItemView,
        child: child ?? ChatText(text: StrRes.unsupportedMessage),
      ),
    );
  }

  // Widget _menuBuilder() => ChatLongPressMenu(
  //       controller: _popupCtrl,
  //       menus: widget.menus ?? _menusItem,
  //       // menuStyle: widget.menuStyle ??
  //       //     MenuStyle(
  //       //       crossAxisCount: 4,
  //       //       mainAxisSpacing: 13.w,
  //       //       crossAxisSpacing: 12.h,
  //       //       radius: 4,
  //       //       background: const Color(0xFF666666),
  //       //     ),
  //     );

  String get _who => !_isISend ? widget.message.senderNickname ?? '' : '你';

  int get _haveReadCount =>
      widget.message.attachedInfoElem?.groupHasReadInfo?.hasReadCount ?? 0;

  int get _needReadCount =>
      widget.message.attachedInfoElem?.groupHasReadInfo?.unreadCount ?? 0;

  bool get _haveUsableMenu =>
      widget.enabledCopyMenu ||
      widget.enabledDelMenu ||
      widget.enabledForwardMenu ||
      widget.enabledReplyMenu ||
      widget.enabledRevokeMenu ||
      widget.enabledMultiMenu ||
      widget.enabledTranslationMenu ||
      widget.enabledAddEmojiMenu;

  List<MenuInfo> get _menusItem => [
        MenuInfo(
          // icon: ImageUtil.menuSpeaker(),
          icon: ImageRes.menuCopy,
          text: '免提播放',
          enabled: widget.enabledSpeakerMenu,
          // textStyle: menuTextStyle,
          onTap: widget.onTapSpeakerMenu,
        ),
        // MenuInfo(
        //   icon: ImageUtil.menuSpeakToText(),
        //   text: '转文字',
        //   enabled: widget.enabledCopyMenu,
        //   textStyle: menuTextStyle,
        //   onTap: widget.onTapCopyMenu,
        // ),
        MenuInfo(
          // icon: ImageUtil.menuSpeak2Speed(),
          icon: ImageRes.menuCopy,
          text: '2X',
          enabled: widget.enabledSpeaker2SpeedMenu,
          // textStyle: menuTextStyle,
          onTap: widget.onTapSpeaker2SpeedMenu,
        ),
        MenuInfo(
          // icon: ImageUtil.menuCopy(),
          icon: ImageRes.menuCopy,
          text: '复制',
          enabled: widget.enabledCopyMenu,
          // textStyle: menuTextStyle,
          onTap: widget.onTapCopyMenu,
        ),
        MenuInfo(
          // icon: ImageUtil.menuDel(),
          icon: ImageRes.menuDel,
          text: '删除',
          enabled: widget.enabledDelMenu,
          // textStyle: menuTextStyle,
          onTap: widget.onTapDelMenu,
        ),
        MenuInfo(
          icon: ImageRes.menuForward,
          text: '转发',
          enabled: widget.enabledForwardMenu,
          // textStyle: menuTextStyle,
          onTap: widget.onTapForwardMenu,
        ),
        MenuInfo(
          icon: ImageRes.menuReply,
          text: '回复',
          enabled: widget.enabledReplyMenu,
          // textStyle: menuTextStyle,
          onTap: widget.onTapReplyMenu,
        ),
        MenuInfo(
            icon: ImageRes.menuRevoke,
            text: '撤回',
            enabled: widget.enabledRevokeMenu,
            // textStyle: menuTextStyle,
            onTap: widget.onTapRevokeMenu),
        MenuInfo(
          icon: ImageRes.menuMulti,
          text: StrRes.menuMulti,
          enabled: widget.enabledMultiMenu,
          // textStyle: menuTextStyle,
          onTap: widget.onTapMultiMenu,
        ),
        MenuInfo(
          icon: ImageRes.appMenuUnTranslate,
          text: '翻译',
          enabled: widget.enabledTranslationMenu,
          // textStyle: menuTextStyle,
          onTap: widget.onTapTranslationMenu,
        ),
        MenuInfo(
          icon: ImageRes.menuAddFace,
          text: StrRes.menuAdd,
          enabled: widget.enabledAddEmojiMenu,
          // textStyle: menuTextStyle,
          onTap: widget.onTapAddEmojiMenu,
        ),
      ];

  static var menuTextStyle = TextStyle(
    fontSize: 10.sp,
    color: const Color(0xFFFFFFFF),
  );

  Widget _buildTimeView() => Container(
        padding: widget.timePadding ??
            EdgeInsets.symmetric(
              vertical: 4.h,
              horizontal: 2.h,
            ),
        // height: 20.h,
        decoration: widget.timeDecoration,
        child: Text(
          widget.timeStr!,
          style: widget.timeStyle ?? _hintTextStyle,
        ),
      );

  var _hintTextStyle = TextStyle(
    color: Color(0xFF999999),
    fontSize: 12.sp,
  );

  // Widget? _customItemView() => widget.customItemBuilder?.call(
  //       context,
  //       widget.index,
  //       widget.message,
  //     );

  onSelectionChanged(CustomPopupMenuController popupCtrl,
      {SelectedContent? selectedContent}) async {
    // 防止输入框焦点切换到选择文本焦点导致菜单列表闪一下
    await Future.delayed(const Duration(milliseconds: 50));
    if (null != selectedContent) {
      popupCtrl.showMenu();
    } else {
      popupCtrl.hideMenu();
    }
  }

  Widget _buildMarkdown({String? text}) {
    // final config =
    //     _isISend ? MarkdownConfig.darkConfig : MarkdownConfig.defaultConfig;
    return Container(
        constraints: BoxConstraints(maxWidth: maxWidth), child: SizedBox()
        // Column(
        //   children: MarkdownGenerator(
        //     linesMargin: EdgeInsets.all(0),
        //   ).buildWidgets(
        //       null != text
        //           ? text
        //           : _message.isTextType
        //               ? _message.textElem!.content!
        //               : IMUtils.replaceMessageAtMapping(_message, {}),
        //       config: config.copy(configs: [
        //         PConfig(
        //           textStyle:
        //               _isISend ? Styles.ts_FFFFFF_16sp : Styles.ts_333333_16sp,
        //         ),
        //         ListConfig(
        //             marker: (bool isOrdered, int depth, int index) =>
        //                 getDefaultMarker(
        //                     isOrdered,
        //                     depth,
        //                     _isISend ? Styles.c_FFFFFF : Styles.c_000000,
        //                     index,
        //                     12,
        //                     config))
        //       ])),
        // ),
        );
  }

  Widget? get _quoteMsgView {
    final quoteMsg = _message.quoteMessage;
    return quoteMsg != null
        ? ChatQuoteView(
            quoteMsg: quoteMsg,
            onTap: widget.onTapQuoteMessage,
            allAtMap: IMUtils.getAtMapping(quoteMsg, widget.allAtMap),
          )
        : null;
  }

  Widget _translateView({String? text, required String status}) {
    List<MenuInfo> _translateMenusItem = [];
    if (null != text && status == "show") {
      _translateMenusItem = [
        MenuInfo(
          icon: ImageRes.menuCopy,
          text: StrRes.menuCopy,
          enabled: true,
          onTap: () => IMUtils.copy(text: text),
        ),
        MenuInfo(
          icon: ImageRes.appMenuUnTranslate,
          text: StrRes.unTranslate,
          enabled: widget.enabledUnTranslateMenu,
          onTap: widget.onTapUnTranslateMenu,
        ),
      ];
    }
    return status == "loading"
        ? Container(
            margin: EdgeInsets.only(top: 4.h),
            padding: EdgeInsets.symmetric(horizontal: 5.w),
            height: 42.h,
            alignment: Alignment.centerLeft,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Styles.c_FFFFFF,
              borderRadius: borderRadius(_isISend),
            ),
            child: ImageRes.appTranslateLoading.toImage..height = 24.h,
          )
        : Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            margin: EdgeInsets.only(top: 4.h),
            // constraints: BoxConstraints(maxWidth: maxWidth),
            decoration: BoxDecoration(
              color: _isISend ? Styles.c_8443F8 : Styles.c_FFFFFF,
              borderRadius: borderRadius(_isISend),
            ),
            child: status == "fail"
                ? ChatText(
                    text: StrRes.translateFail,
                    textStyle: Styles.ts_FF4E4C_16sp,
                    patterns: widget.patterns,
                    textScaleFactor: widget.textScaleFactor,
                    // onVisibleTrulyText: widget.onVisibleTrulyText,
                    isISend: _isISend,
                  )
                : CopyCustomPopupMenu(
                    controller: _popupTranslateMenuCtrl,
                    menuBuilder: () => ChatLongPressMenu(
                      popupMenuController: _popupTranslateMenuCtrl,
                      menus: _translateMenusItem,
                    ),
                    pressType: PressType.longPress,
                    arrowColor: Styles.c_333333_opacity85,
                    barrierColor: Colors.transparent,
                    verticalMargin: 0,
                    child:
                    // !showMd
                    //     ?
                    ChatText(
                            text: status == "show" ? text! : "",
                            patterns: widget.patterns,
                            textScaleFactor: widget.textScaleFactor,
                            isISend: _isISend,
                            selectMode: true,
                            onSelectionChanged: (
                                    {SelectedContent? selectedContent}) =>
                                onSelectionChanged(_popupTranslateMenuCtrl,
                                    selectedContent: selectedContent),
                          )
                        // : _buildMarkdown(text: text!),
                  ),
          );
  }

  Widget _ttsView({String? text, required String status}) {
    List<MenuInfo> _ttsMenusItem = [];
    if (null != text && status == "show") {
      _ttsMenusItem = [
        MenuInfo(
          icon: ImageRes.menuCopy,
          text: StrRes.menuCopy,
          enabled: true,
          onTap: () => IMUtils.copy(text: text),
        ),
        MenuInfo(
          icon: ImageRes.appMenuUnTts,
          text: StrRes.hide,
          enabled: widget.enabledUnTtsMenu,
          onTap: widget.onTapUnTtsMenu,
        ),
        // MenuInfo(
        //     icon: ImageLibrary.menuForward,
        //     text: StrLibrary .menuForward,
        //     enabled: true,
        //     onTap: widget.onTapForwardMenu,
        //   )
      ];
    }
    return status == "loading"
        ? Container(
            margin: EdgeInsets.only(top: 4.h),
            padding: EdgeInsets.symmetric(horizontal: 5.w),
            height: 42.h,
            alignment: Alignment.centerLeft,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Styles.c_FFFFFF,
              borderRadius: borderRadius(_isISend),
            ),
            child: ImageRes.appTranslateLoading.toImage..height = 24.h,
          )
        : Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            margin: EdgeInsets.only(top: 4.h),
            // constraints: BoxConstraints(maxWidth: maxWidth),
            decoration: BoxDecoration(
              color: _isISend ? Styles.c_8443F8 : Styles.c_FFFFFF,
              borderRadius: borderRadius(_isISend),
            ),
            child: status == "fail"
                ? ChatText(
                    text: StrRes.translateFail,
                    textStyle: Styles.ts_FF4E4C_16sp,
                    patterns: widget.patterns,
                    textScaleFactor: widget.textScaleFactor,
                    // onVisibleTrulyText: widget.onVisibleTrulyText,
                    isISend: _isISend,
                  )
                : CopyCustomPopupMenu(
                    controller: _popupTranslateMenuCtrl,
                    menuBuilder: () => ChatLongPressMenu(
                      popupMenuController: _popupTranslateMenuCtrl,
                      menus: _ttsMenusItem,
                    ),
                    pressType: PressType.longPress,
                    arrowColor: Styles.c_333333_opacity85,
                    barrierColor: Colors.transparent,
                    verticalMargin: 0,
                    child: ChatText(
                      text: status == "show" ? text! : "",
                      patterns: widget.patterns,
                      textScaleFactor: widget.textScaleFactor,
                      isISend: _isISend,
                      selectMode: true,
                      onSelectionChanged: (
                              {SelectedContent? selectedContent}) =>
                          onSelectionChanged(_popupTranslateMenuCtrl,
                              selectedContent: selectedContent),
                    ),
                  ),
          );
  }

  Widget? get _readStatusView => widget.enabledReadStatus &&
          _isISend &&
          _message.status == MessageStatus.succeeded
      ? ChatReadTagView(
          message: _message,
          onTap: widget.onViewMessageReadStatus,
          showRead: widget.showRead)
      : null;

  Widget? get _voiceReadStatusView => _message.isVoiceType && !_message.isRead!
      ? const ChatVoiceReadStatusView()
      : null;
}
