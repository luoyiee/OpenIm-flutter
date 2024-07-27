import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sprintf/sprintf.dart';

import '../../../../openim_common.dart';

class ChatSingleLayout extends StatefulWidget {
  final CustomPopupMenuController popupCtrl;
  final Widget child;
  final String msgId;
  final bool isSingleChat;
  final int index;
  final Sink<int> clickSink;
  final Widget Function() menuBuilder;
  final Function()? onTapLeftAvatar;
  final Function()? onLongPressLeftAvatar;
  final Function()? onTapRightAvatar;
  final Function()? onLongPressRightAvatar;
  final String? leftAvatar;
  final String? leftName;
  final String? rightAvatar;
  final double avatarSize;
  final bool isReceivedMsg;
  final bool? isUnread;
  final Color leftBubbleColor;
  final Color rightBubbleColor;
  final Stream<MsgStreamEv<bool>>? sendStatusStream;
  final bool isSendFailed;
  final bool isSending;
  final Widget? timeView;

  // final Widget? quoteView;
  final bool isBubbleBg;
  final bool isHintMsg;
  final bool checked;
  final bool showRadio;
  final Function(bool checked)? onRadioChanged;
  final bool delaySendingStatus;
  final bool enabledReadStatus;
  final bool isPrivateChat;
  final Function()? onStartDestroy;
  final int readingDuration;
  final int haveReadCount;
  final int needReadCount;
  final Function()? viewMessageReadStatus;
  final Function()? failedResend;

  // final CustomAvatarBuilder? customLeftAvatarBuilder;
  // final CustomAvatarBuilder? customRightAvatarBuilder;
  final bool haveUsableMenu;
  final bool showLongPressMenu;
  final bool isVoiceMessage;

  const ChatSingleLayout({
    super.key,
    required this.child,
    required this.msgId,
    required this.index,
    required this.isSingleChat,
    required this.menuBuilder,
    required this.clickSink,
    required this.sendStatusStream,
    required this.popupCtrl,
    required this.isReceivedMsg,
    this.rightAvatar,
    this.leftAvatar,
    required this.leftName,
    this.avatarSize = 42.0,
    this.isUnread,
    this.leftBubbleColor = const Color(0xFFF0F0F0),
    this.rightBubbleColor = const Color(0xFFDCEBFE),
    this.onLongPressRightAvatar,
    this.onTapRightAvatar,
    this.onLongPressLeftAvatar,
    this.onTapLeftAvatar,
    this.isSendFailed = false,
    this.isSending = true,
    this.timeView,
    // this.quoteView,
    this.isBubbleBg = true,
    this.isHintMsg = false,
    this.checked = false,
    this.showRadio = false,
    this.onRadioChanged,
    this.delaySendingStatus = false,
    this.enabledReadStatus = true,
    this.readingDuration = 0,
    this.isPrivateChat = false,
    this.onStartDestroy,
    this.haveReadCount = 0,
    this.needReadCount = 0,
    this.viewMessageReadStatus,
    this.failedResend,
    // this.customLeftAvatarBuilder,
    // this.customRightAvatarBuilder,
    this.haveUsableMenu = true,
    this.showLongPressMenu = true,
    this.isVoiceMessage = false,
  });

  @override
  State<ChatSingleLayout> createState() => _ChatSingleLayoutState();

  static var haveReadStyle = TextStyle(
    fontSize: 12.sp,
    color: Color(0xFF999999),
  );
  static var unreadStyle = TextStyle(
    fontSize: 12.sp,
    color: Color(0xFF006AFF),
  );
}

class _ChatSingleLayoutState extends State<ChatSingleLayout> {
  bool _checked = false;

  @override
  void initState() {
    _checked = widget.checked;
    super.initState();
  }

  void _onRadioChanged(bool value) {
    setState(() {
      _checked = value;
    });
    if (widget.onRadioChanged != null) {
      widget.onRadioChanged!(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.isPrivateChat
          ? null
          : widget.showRadio
              ? () {
                  _onRadioChanged(!_checked);
                  // widget.onRadioChanged?.call(!widget.checked);
                }
              : null,
      behavior: HitTestBehavior.translucent,
      child: IgnorePointer(
        ignoring: widget.showRadio,
        child: Row(
          // mainAxisAlignment: _layoutAlignment(),
          children: [
            if (!widget.isHintMsg && !widget.isPrivateChat)
              ChatRadio(checked: _checked, showRadio: widget.showRadio),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.timeView != null) widget.timeView!,
                _buildContentView(),
                Container(
                  margin: EdgeInsets.only(
                    left: widget.isReceivedMsg ? widget.avatarSize + 10.w : 0,
                    right: widget.isReceivedMsg ? 0 : widget.avatarSize + 10.w,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: _layoutAlignment(),
                    children: [
                      // if (quoteView != null) _buildQuoteMsgView(),
                      ..._getReadStatusView(),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentView() {
    if (widget.isHintMsg) {
      return widget.child;
    }
    return widget.isReceivedMsg ? _isFromWidget() : _isToWidget();
  }

  Widget _isFromWidget() => Row(
        mainAxisAlignment: _layoutAlignment(),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // _buildAvatar(
          //   leftAvatar,
          //   isReceivedMsg,
          //   onTap: onTapLeftAvatar,
          //   onLongPress: onLongPressLeftAvatar,
          //   builder: customLeftAvatarBuilder,
          // ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Visibility(
                    visible: widget.isReceivedMsg && !widget.isSingleChat,
                    child: Container(
                      margin: EdgeInsets.only(bottom: 2.h, left: 10.w),
                      child: Text(
                        widget.leftName ?? '',
                        style: TextStyle(
                          color: Color(0xFF666666),
                          fontSize: 10.sp,
                        ),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      !widget.showLongPressMenu
                          ? _buildChildView(BubbleType.receiver)
                          : CopyCustomPopupMenu(
                              controller: widget.popupCtrl,
                              barrierColor: Colors.transparent,
                              arrowColor: Color(0xFF666666),
                              verticalMargin: 0,
                              // horizontalMargin: 0,
                              child: _buildChildView(BubbleType.receiver),
                              menuBuilder: widget.menuBuilder,
                              pressType: PressType.longPress,
                              showArrow: widget.haveUsableMenu,
                            ),
                      /*if (enabledReadStatus) */ _buildVoiceReadStatusView(),
                    ],
                  ),
                ],
              ),
              if (widget.isSingleChat) _buildDestroyAfterReadingView(),
            ],
          )
        ],
      );

  Widget _buildChildView(BubbleType type) => widget.isBubbleBg
      ? GestureDetector(
          onTap: () => _onItemClick?.add(widget.index),
          child: ChatBubble(
            constraints: BoxConstraints(minHeight: widget.avatarSize),
            bubbleType: type,
            child: widget.child,
            backgroundColor: _bubbleColor(),
          ),
        )
      : _noBubbleBgView();

  // avatarSize + 10
  Widget _isToWidget() => Row(
        mainAxisAlignment: _layoutAlignment(),
        children: [
          if (widget.isSingleChat) _buildDestroyAfterReadingView(),
          if (widget.delaySendingStatus) _delayedStatusView(),
          if (!widget.delaySendingStatus)
            Visibility(
              visible: widget.isSending && !widget.isSendFailed,
              child: const CupertinoActivityIndicator(),
            ),
          ChatSendFailedView(
            id: widget.msgId,
            isISend: widget.isReceivedMsg,
            stream: widget.sendStatusStream,
            isFailed: widget.isSendFailed,
            onFailedToResend: widget.failedResend,
          ),
          // ..._getReadStatusView(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              !widget.showLongPressMenu
                  ? _buildChildView(BubbleType.send)
                  : CopyCustomPopupMenu(
                      controller: widget.popupCtrl,
                      barrierColor: Colors.transparent,
                      arrowColor: Color(0xFF666666),
                      verticalMargin: 0,
                      // horizontalMargin: 0,
                      child: _buildChildView(BubbleType.send),
                      menuBuilder: widget.menuBuilder,
                      pressType: PressType.longPress,
                      showArrow: widget.haveUsableMenu,
                    ),
              // _buildSendFailView(isReceivedMsg, fail: !isSenSuccess),
              // _buildAvatar(
              //   rightAvatar,
              //   !isReceivedMsg,
              //   onTap: onTapRightAvatar,
              //   onLongPress: onLongPressRightAvatar,
              //   builder: customRightAvatarBuilder,
              // )
            ],
          ),
        ],
      );

  Widget _noBubbleBgView() => Container(
        margin: EdgeInsets.only(right: 10.w, left: 10.w),
        // padding: EdgeInsets.all(1),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          // border: Border.all(
          //   color: Color(0xFFE6E6E6),
          //   width: 1,
          // ),
          // boxShadow: [
          //   BoxShadow(
          //     color: Color(0xFF000000).withOpacity(0.1),
          //     offset: Offset(0, 2.h),
          //     blurRadius: 4,
          //   ),
          // ],
        ),
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: widget.child,
          ),
          onTap: () => _onItemClick?.add(widget.index),
        ),
      );

  Sink<int>? get _onItemClick => widget.clickSink;

  MainAxisAlignment _layoutAlignment() =>
      widget.isReceivedMsg ? MainAxisAlignment.start : MainAxisAlignment.end;

  // BubbleNip _nip() =>
  Color _bubbleColor() =>
      widget.isReceivedMsg ? widget.leftBubbleColor : widget.rightBubbleColor;

  Widget _buildAvatar(
    String? url,
    bool show, {
    final Function()? onTap,
    final Function()? onLongPress,
    CustomAvatarBuilder? builder,
  }) =>
      AvatarView(
        url: url,
        // visible: show,
        onTap: onTap,
        onLongPress: onLongPress,
        width: widget.avatarSize,
        height: widget.avatarSize,
        builder: builder,
      );

  /// 语音未读状态
  Widget _buildVoiceReadStatusView() {
    return Visibility(
      visible: widget.isVoiceMessage && widget.isUnread!,
      child: Container(
        width: 6.w,
        height: 6.w,
        decoration: BoxDecoration(
          color: const Color(0xFFF44038),
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  /// 单聊
  Widget _buildReadStatusView() {
    bool read = !widget.isUnread!;
    return Visibility(
      visible: !widget.isReceivedMsg,
      child: read
          ? Text(
              '已读',
              style: ChatSingleLayout.haveReadStyle,
            )
          : Text(
              '未读',
              style: ChatSingleLayout.unreadStyle,
            ),
    );
  }

  /// 群聊
  Widget _buildGroupReadStatusView() {
    if (widget.needReadCount == 0) return SizedBox();
    int unreadCount = widget.needReadCount - widget.haveReadCount - 1;
    bool isAllRead = unreadCount <= 0;
    return Visibility(
      visible: !widget.isReceivedMsg,
      child: GestureDetector(
        onTap: widget.viewMessageReadStatus,
        behavior: HitTestBehavior.translucent,
        child: Text(
          isAllRead ? '全部已读' : '$unreadCount人未读',
          // sprintf(UILocalizations.groupUnread, [])
          style: isAllRead
              ? ChatSingleLayout.haveReadStyle
              : ChatSingleLayout.unreadStyle,
        ),
      ),
    );
  }

  Widget _delayedStatusView() => FutureBuilder(
        future: Future.delayed(
          Duration(seconds: (widget.isSending && !widget.isSendFailed) ? 1 : 0),
          () => widget.isSending && !widget.isSendFailed,
        ),
        builder: (_, AsyncSnapshot<bool> hot) => Visibility(
          visible: widget.index == 0
              ? (hot.data == true)
              : (widget.isSending && !widget.isSendFailed),
          child: CupertinoActivityIndicator(),
        ),
      );

  /// 阅后即焚
  Widget _buildDestroyAfterReadingView() {
    bool haveRead = !widget.isUnread!;
    // if (isPrivateChat && haveRead && readingDuration <= 0) {
    //   onStartDestroy?.call();
    // }
    return Visibility(
      visible: haveRead && widget.isPrivateChat /*&& readingDuration > 0*/,
      child: TimingView(
        sec: widget.readingDuration,
        onFinished: widget.onStartDestroy,
      ),
    );
  }

  /// 显示单聊已读状态
  bool get _showSingleChatReadStatus =>
      widget.isSingleChat &&
      !widget.isSendFailed &&
      !widget.isSending &&
      widget.enabledReadStatus;

  /// 显示群聊已读状态
  bool get _showGroupChatReadStatus =>
      !widget.isSingleChat &&
      !widget.isSendFailed &&
      !widget.isSending &&
      widget.enabledReadStatus;

  /// 读状态
  List<Widget> _getReadStatusView() => [
        if (_showSingleChatReadStatus) _buildReadStatusView(),
        if (_showGroupChatReadStatus) _buildGroupReadStatusView(),
      ];
}
