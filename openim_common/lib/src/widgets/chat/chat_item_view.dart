import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:openim_common/openim_common.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_openim_sdk/flutter_openim_sdk.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:openim_common/src/utils/common_util.dart';
import 'package:openim_common/src/widgets/chat/self/chat_file_picture_view.dart';
import 'package:openim_common/src/widgets/chat/self/chat_file_video_view.dart';
import 'package:openim_common/src/widgets/chat/self/chat_file_view.dart';
import 'package:rxdart/rxdart.dart';

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

double maxWidth = 247.w;
double pictureWidth = 120.w;
double videoWidth = 120.w;
double locationWidth = 220.w;

BorderRadius borderRadius(bool isISend) => BorderRadius.only(
      topLeft: Radius.circular(isISend ? 6.r : 0),
      topRight: Radius.circular(isISend ? 0 : 6.r),
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
  const ChatItemView({
    super.key,
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
    required this.index,
    this.menus,
    this.menuStyle,
    required this.enabledCopyMenu,
    required this.enabledDelMenu,
    required this.enabledForwardMenu,
    required this.enabledReplyMenu,
    required this.enabledRevokeMenu,
    required this.enabledMultiMenu,
    required this.enabledTranslationMenu,
    required this.enabledAddEmojiMenu,
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
    required this.showNoticeMessage,
    required this.showLongPressMenu,
    this.customLeftAvatarBuilder,
    this.customRightAvatarBuilder,
    required this.multiList,
    required this.multiSelMode,
    this.onMultiSelChanged,
    required this.delaySendingStatus,
    required this.enabledReadStatus,
    required this.isPrivateChat,
    this.onDestroyMessage,
    required this.readingDuration,
    this.onViewMessageReadStatus,
    this.onTapQuoteMsg,
    this.timeDecoration,
    this.timePadding,
    this.timeStr,
    this.messageTimeStr,
    this.onClickAtText,
    // this.leftBubbleColor,
    // this.rightBubbleColor,
    required this.clickSubject,
    required this.isSingleChat,
    this.avatarSize,
    this.timeStyle,
    this.onPopMenuShowChanged,
    this.popPageCloseMenuSubject,
    this.customItemBuilder,
    required this.isBubbleMsg,
    this.textStyle,
    this.isPlayingSound = false,
    this.enabledSpeakerMenu = false,
    this.enabledSpeaker2SpeedMenu = false,
    this.playingStateStream,
    this.customMessageBuilder,
  });

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
  final bool isSingleChat;

  /// 头像大小
  final double? avatarSize;

  /// 被选择的消息
  final List<Message> multiList;

  /// listview index
  final int index;

  /// long press menu list
  /// 长按消息起泡弹出的菜单列表
  final List<MenuInfo>? menus;

  /// menu list style
  /// 菜单样式
  final MenuStyle? menuStyle;

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
  final bool showNoticeMessage;

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
  final Subject<int> clickSubject;

  /// 时间装饰
  final BoxDecoration? timeDecoration;

  /// 上下间距
  final EdgeInsetsGeometry? timePadding;

  ///
  final String? timeStr;

  /// 每条消息时间
  final String? messageTimeStr;

  /// 当前是否是多选模式
  final bool multiSelMode;

  ///
  final Function(bool checked)? onMultiSelChanged;

  /// 是否在发送消息时，延迟显示消息发送中状态，既延迟显示加载框
  final bool delaySendingStatus;

  /// 显示消息已读
  final bool enabledReadStatus;

  /// 是否开启阅后即焚
  final bool isPrivateChat;

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
  final bool isBubbleMsg;

  /// 当前播放的语音消息
  final bool isPlayingSound;

  final Stream<String>? playingStateStream; // 添加这个参数

  @override
  State<ChatItemView> createState() => _ChatItemViewState();
}

class _ChatItemViewState extends State<ChatItemView> {
  Message get _message => widget.message;
  final _popupCtrl = CustomPopupMenuController();

  bool get _isISend => _message.sendID == OpenIM.iMManager.userID;

  // bool get _isFromMsg => widget.message.sendID != OpenIM.iMManager.uid;
  //
  bool get _checked => widget.multiList.contains(widget.message);

  late StreamSubscription<bool> _keyboardSubs;
  StreamSubscription<bool>? _closeMenuSubs;

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
      // child = ChatText(
      //   text: _message.textElem!.content!,
      //   patterns: widget.patterns,
      //   textScaleFactor: widget.textScaleFactor,
      //   onVisibleTrulyText: widget.onVisibleTrulyText,
      // );
      child = ChatAtText(
        text: _message.textElem!.content!,
        textStyle: widget.textStyle,
        patterns: widget.patterns,
        textScaleFactor: widget.textScaleFactor,
        // onVisibleTrulyText: widget.onVisibleTrulyText,
      );
    } else if (_message.isAtTextType) {
      isBubbleBg = true;
      // child = ChatText(
      //   text: _message.atTextElem!.text!,
      //   allAtMap: IMUtils.getAtMapping(_message, widget.allAtMap),
      //   patterns: widget.patterns,
      //   textScaleFactor: widget.textScaleFactor,
      //   onVisibleTrulyText: widget.onVisibleTrulyText,
      // );
      child =
          // _buildCommonItemView(
          // child : ChatText(
          //   text: _message.atTextElem!.text!,
          //   allAtMap: IMUtils.getAtMapping(_message, widget.allAtMap),
          //   patterns: widget.patterns,
          //   textScaleFactor: widget.textScaleFactor,
          //   onVisibleTrulyText: widget.onVisibleTrulyText,
          // )

          ChatAtText(
        text: _message.atTextElem!.text!,
        allAtMap: widget.allAtMap,
        textStyle: widget.textStyle,
        textScaleFactor: widget.textScaleFactor,
        patterns: widget.patterns,
        // ),
      );
    } else if (_message.isPictureType) {
      // child = ChatPictureView(
      //   isISend: _isISend,
      //   message: _message,
      //   sendProgressStream: widget.sendProgressSubject,
      // );
      child = _buildCommonItemView(
          isBubbleBg: false,
          child: ChatPictureView(
            isISend: _isISend,
            message: _message,
            sendProgressStream: widget.sendProgressSubject,
          ));
    } else if (_message.isVoiceType) {
      var sound = widget.message.soundElem;
      child = _buildCommonItemView(
        child: ChatVoiceView(
          msgId: widget.message.clientMsgID ?? "",
          index: widget.index,
          clickStream: widget.clickSubject.stream,
          isReceived: !_isISend,
          soundPath: sound?.soundPath,
          soundUrl: sound?.sourceUrl,
          duration: sound?.duration,
          isPlaying: widget.isPlayingSound,
          playingStateStream: widget.playingStateStream,
        ),
      );
    } else if (_message.isVideoType) {
      // final video = _message.videoElem;
      // child = ChatVideoView(
      //   isISend: _isISend,
      //   message: _message,
      //   sendProgressStream: widget.sendProgressSubject,
      // );
      var video = widget.message.videoElem;
      child = _buildCommonItemView(
          isBubbleBg: false,
          child: ChatVideoView(
            isISend: _isISend,
            message: _message,
            sendProgressStream: widget.sendProgressSubject,
          ));
    } else if (_message.isFileType) {
      var file = widget.message.fileElem;
      if (file != null) {
        final mimeType = CommonUtil.getMediaType(file.fileName!);
        if (mimeType != null && mimeType.startsWith('image/')) {
          child = _buildCommonItemView(
              child: ChatFilePictureView(
            isISend: _isISend,
            message: _message,
            sendProgressStream: widget.sendProgressSubject,
          ));
        } else if (mimeType != null && mimeType.startsWith('audio/')) {
          child = _buildCommonItemView(
              child: ChatFileVideoView(
            isISend: _isISend,
            message: _message,
            sendProgressStream: widget.sendProgressSubject,
          ));
        } else {
          child = _buildCommonItemView(
              child: ChatFileView(
            msgId: widget.message.clientMsgID!,
            fileName: file.fileName!,
            bytes: file.fileSize ?? 0,
            width: 158.w,
            initProgress: 100,
            uploadStream: widget.sendProgressSubject,
          ));
        }
      }
    } else if (_message.isCardType) {
      var data = widget.message.cardElem;
      child = _buildCommonItemView(
        isBubbleBg: false,
        child: ChatCarteView(
          name: data?.nickname ?? "",
          url: data?.faceURL,
        ),
      );
    } else if (_message.isLocationType) {
      var data = widget.message.locationElem;
      child = _buildCommonItemView(
        isBubbleBg: false,
        child: ChatLocationView(
          description: data!.description!,
          latitude: data.latitude!,
          longitude: data.longitude!,
        ),
      );
    } else if (_message.isQuoteType) {
      child = _buildCommonItemView(
        child: ChatAtText(
          text: widget.message.quoteElem?.text ?? '',
          allAtMap: widget.allAtMap,
          textStyle: widget.textStyle,
          textScaleFactor: widget.textScaleFactor,
          patterns: widget.patterns,
        ),
      );
    } else if (_message.isMergerType) {
      child = _buildCommonItemView(
        child: ChatMergeMsgView(
          title: widget.message.mergeElem?.title ?? '',
          summaryList: widget.message.mergeElem?.abstractList ?? [],
        ),
      );
    } else if (_message.isCustomFaceType) {
      var face = widget.message.faceElem;
      child = _buildCommonItemView(
        isBubbleBg: false,
        child: ChatCustomEmojiView(
          index: face?.index,
          data: face?.data,
          widgetWidth: 100.w,
        ),
      );
    } else if (_message.isCustomType) {
      final info = widget.customTypeBuilder?.call(context, _message);
      if (null != info) {
        // child = _buildCommonItemView(
        //     isBubbleBg: info.needBubbleBackground, child: info.customView);

        isBubbleBg = info.needBubbleBackground;
        child = info.customView;

        if (!info.needChatItemContainer) {
          return child;
        }
      }
    } else if (_message.isNotificationType) {
      if (_message.contentType ==
          MessageType.groupInfoSetAnnouncementNotification) {
      } else {
        return ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: ChatHintTextView(message: _message),
        );
      }
    }
    senderNickname ??= widget.leftNickname ?? _message.senderNickname;
    senderFaceURL ??= widget.leftFaceUrl ?? _message.senderFaceUrl;
    return child = ChatItemContainerNew(
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
      isSending: _message.status == MessageStatus.sending,
      isSendFailed: _message.status == MessageStatus.failed,
      isBubbleBg: child == null ? true : isBubbleBg,
      ignorePointer: widget.ignorePointer,
      sendStatusStream: widget.sendStatusSubject,
      onFailedToResend: widget.onFailedToResend,
      onLongPressLeftAvatar: widget.onLongPressLeftAvatar,
      onLongPressRightAvatar: widget.onLongPressRightAvatar,
      onTapLeftAvatar: widget.onTapLeftAvatar,
      onTapRightAvatar: widget.onTapRightAvatar,
      showRadio: widget.multiSelMode,
      checked: _checked,
      onRadioChanged: widget.onMultiSelChanged,
      menuBuilder: _menuBuilder,
      popupCtrl: _popupCtrl,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: widget.onClickItemView,
        child: child ?? ChatText(text: StrRes.unsupportedMessage),
      ),
    );
  }

  Widget _buildCommonItemView({
    required Widget child,
    bool isBubbleBg = true,
    bool isHintMsg = false,
  }) =>
      ChatSingleLayout(
        msgId: widget.message.clientMsgID!,
        index: widget.index,
        menuBuilder: _menuBuilder,
        haveUsableMenu: _haveUsableMenu,
        clickSink: widget.clickSubject.sink,
        sendStatusStream: widget.sendStatusSubject,
        popupCtrl: _popupCtrl,
        isReceivedMsg: !_isISend,
        isSingleChat: widget.isSingleChat,
        avatarSize: widget.avatarSize ?? 42.h,
        // rightAvatar: widget.rightFaceUrl ?? OpenIM.iMManager.userInfo.faceURL,
        // leftAvatar: widget.leftFaceUrl ?? widget.message.senderFaceUrl,
        leftName: widget.leftNickname ?? widget.message.senderNickname ?? '',
        isUnread: !widget.message.isRead!,
        // leftBubbleColor: widget.leftBubbleColor,
        // rightBubbleColor: widget.rightBubbleColor,
        onLongPressRightAvatar: widget.onLongPressRightAvatar,
        onTapRightAvatar: widget.onTapRightAvatar,
        onLongPressLeftAvatar: widget.onLongPressLeftAvatar,
        onTapLeftAvatar: widget.onTapLeftAvatar,
        isSendFailed: widget.message.status == MessageStatus.failed,
        isSending: widget.message.status == MessageStatus.sending,
        timeView: widget.timeStr == null ? null : _buildTimeView(),
        isBubbleBg: isBubbleBg,
        isHintMsg: isHintMsg,
        // quoteView: _quoteView,
        showRadio: widget.multiSelMode,
        checked: _checked,
        onRadioChanged: widget.onMultiSelChanged,
        delaySendingStatus: widget.delaySendingStatus,
        enabledReadStatus: widget.enabledReadStatus,
        isPrivateChat: widget.isPrivateChat,
        onStartDestroy: widget.onDestroyMessage,
        readingDuration: widget.readingDuration,
        needReadCount: _needReadCount,
        haveReadCount: _haveReadCount,
        viewMessageReadStatus: widget.onViewMessageReadStatus,
        failedResend: widget.onFailedToResend,
        // customLeftAvatarBuilder: widget.customLeftAvatarBuilder,
        // customRightAvatarBuilder: widget.customRightAvatarBuilder,
        showLongPressMenu: widget.showLongPressMenu,
        isVoiceMessage: widget.message.contentType == MessageType.voice,
        child: child,
      );

  Widget _menuBuilder() => ChatLongPressMenu(
        controller: _popupCtrl,
        menus: widget.menus ?? _menusItem(),
        menuStyle: widget.menuStyle ??
            MenuStyle(
              crossAxisCount: 4,
              mainAxisSpacing: 13.w,
              crossAxisSpacing: 12.h,
              radius: 4,
              background: const Color(0xFF666666),
            ),
      );

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

  List<MenuInfo> _menusItem() => [
        MenuInfo(
          icon: ImageUtil.menuSpeaker(),
          text: '免提播放',
          enabled: widget.enabledSpeakerMenu,
          textStyle: menuTextStyle,
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
          icon: ImageUtil.menuSpeak2Speed(),
          text: '2X',
          enabled: widget.enabledSpeaker2SpeedMenu,
          textStyle: menuTextStyle,
          onTap: widget.onTapSpeaker2SpeedMenu,
        ),
        MenuInfo(
          icon: ImageUtil.menuCopy(),
          text: '复制',
          enabled: widget.enabledCopyMenu,
          textStyle: menuTextStyle,
          onTap: widget.onTapCopyMenu,
        ),
        MenuInfo(
          icon: ImageUtil.menuDel(),
          text: '删除',
          enabled: widget.enabledDelMenu,
          textStyle: menuTextStyle,
          onTap: widget.onTapDelMenu,
        ),
        MenuInfo(
          icon: ImageUtil.menuForward(),
          text: '转发',
          enabled: widget.enabledForwardMenu,
          textStyle: menuTextStyle,
          onTap: widget.onTapForwardMenu,
        ),
        MenuInfo(
          icon: ImageUtil.menuReply(),
          text: '回复',
          enabled: widget.enabledReplyMenu,
          textStyle: menuTextStyle,
          onTap: widget.onTapReplyMenu,
        ),
        MenuInfo(
            icon: ImageUtil.menuRevoke(),
            text: '撤回',
            enabled: widget.enabledRevokeMenu,
            textStyle: menuTextStyle,
            onTap: widget.onTapRevokeMenu),
        MenuInfo(
          icon: ImageUtil.menuMultiChoice(),
          text: '多选',
          enabled: widget.enabledMultiMenu,
          textStyle: menuTextStyle,
          onTap: widget.onTapMultiMenu,
        ),
        MenuInfo(
          icon: ImageUtil.menuTranslation(),
          text: '翻译',
          enabled: widget.enabledTranslationMenu,
          textStyle: menuTextStyle,
          onTap: widget.onTapTranslationMenu,
        ),
        MenuInfo(
          icon: ImageUtil.menuAddEmoji(),
          text: '添加',
          enabled: widget.enabledAddEmojiMenu,
          textStyle: menuTextStyle,
          onTap: widget.onTapAddEmojiMenu,
        ),
      ];

  static var menuTextStyle = TextStyle(
    fontSize: 10.sp,
    color: const Color(0xFFFFFFFF),
  );

  Widget? get _quoteView {
    if (widget.message.contentType == MessageType.quote) {
      return ChatQuoteView(
        message: widget.message.quoteElem!.quoteMessage!,
        onTap: widget.onTapQuoteMsg,
      );
    } else if (widget.message.contentType == MessageType.text) {
      var message = widget.message.atTextElem!.quoteMessage;
      if (message != null) {
        return ChatQuoteView(
          message: message,
          onTap: widget.onTapQuoteMsg,
        );
      }
    }
    return null;
  }

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

  Widget? _customItemView() => widget.customItemBuilder?.call(
        context,
        widget.index,
        widget.message,
      );
}
