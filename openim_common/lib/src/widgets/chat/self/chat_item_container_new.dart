import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:openim_common/openim_common.dart';

class ChatItemContainerNew extends StatefulWidget {
  const ChatItemContainerNew({
    super.key,
    required this.id,
    this.leftFaceUrl,
    this.rightFaceUrl,
    this.leftNickname,
    this.rightNickname,
    this.timelineStr,
    this.timeStr,
    required this.isBubbleBg,
    required this.isISend,
    required this.isSending,
    required this.isSendFailed,
    required this.popupCtrl,
    required this.menuBuilder,
    this.ignorePointer = false,
    this.showLeftNickname = true,
    this.showRightNickname = false,
    this.isPrivateChat = false,
    this.showRadio = false,
    this.isHintMsg = false,
    this.checked = false,
    this.haveUsableMenu = true,
    this.showLongPressMenu = true,
    required this.child,
    this.sendStatusStream,
    this.onTapLeftAvatar,
    this.onTapRightAvatar,
    this.onLongPressLeftAvatar,
    this.onLongPressRightAvatar,
    this.onFailedToResend,
    this.onRadioChanged,
  });

  final String id;
  final String? leftFaceUrl;
  final String? rightFaceUrl;
  final String? leftNickname;
  final String? rightNickname;
  final String? timelineStr;
  final String? timeStr;
  final bool isBubbleBg;
  final bool isISend;
  final bool isSending;
  final bool isSendFailed;
  final bool ignorePointer;
  final bool showLeftNickname;
  final bool showRightNickname;
  final bool showRadio;
  final bool checked;
  final bool haveUsableMenu;
  final bool showLongPressMenu;
  final bool isHintMsg;
  final Widget child;
  final bool isPrivateChat;
  final Stream<MsgStreamEv<bool>>? sendStatusStream;
  final Function()? onTapLeftAvatar;
  final Function()? onTapRightAvatar;
  final Function()? onLongPressLeftAvatar;
  final Function()? onLongPressRightAvatar;
  final Function()? onFailedToResend;
  final Function(bool checked)? onRadioChanged;
  final CustomPopupMenuController popupCtrl;
  final Widget Function() menuBuilder;

  @override
  State<ChatItemContainerNew> createState() => _ChatItemContainerNewState();

  static var haveReadStyle = TextStyle(
    fontSize: 12.sp,
    color: Color(0xFF999999),
  );
  static var unreadStyle = TextStyle(
    fontSize: 12.sp,
    color: Color(0xFF006AFF),
  );
}

class _ChatItemContainerNewState extends State<ChatItemContainerNew> {
  bool _checked = false;

  @override
  void initState() {
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
                }
              : null,
      behavior: HitTestBehavior.translucent,
      child: IgnorePointer(
        ignoring: widget.ignorePointer,
        child: Row(mainAxisAlignment: MainAxisAlignment.start, children: [
          if (!widget.isHintMsg && !widget.isPrivateChat)
            ChatRadio(checked: _checked, showRadio: widget.showRadio),
          10.horizontalSpace,
          Expanded(
            child: Column(
              children: [
                if (null != widget.timelineStr)
                  ChatTimelineView(
                    timeStr: widget.timelineStr!,
                    margin: EdgeInsets.only(bottom: 20.h),
                  ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: widget.isISend
                      ? MainAxisAlignment.end
                      : MainAxisAlignment.start,
                  children: [
                    // Expanded(child:
                    widget.isISend ? _buildRightView() : _buildLeftView()
                    // ),
                  ],
                ),
              ],
            ),
          )
        ]),
      ),
    );
  }

  Widget _buildChildView(BubbleType type) => widget.isBubbleBg
      ? ChatBubble(bubbleType: type, child: widget.child)
      : widget.child;

  Widget _buildLeftView() => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          AvatarView(
            width: 44.w,
            height: 44.h,
            textStyle: Styles.ts_FFFFFF_14sp_medium,
            url: widget.leftFaceUrl,
            text: widget.leftNickname,
            onTap: widget.onTapLeftAvatar,
            onLongPress: widget.onLongPressLeftAvatar,
          ),
          10.horizontalSpace,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              ChatNicknameView(
                nickname: widget.showLeftNickname ? widget.leftNickname : null,
                timeStr: widget.timeStr,
              ),
              4.verticalSpace,
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // _buildChildView(BubbleType.receiver),
                  !widget.showLongPressMenu
                      ? _buildChildView(BubbleType.receiver)
                      : _buildCopyCustomPopupMenu(),
                ],
              ),
            ],
          ),
        ],
      );

  Widget _buildRightView() => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              ChatNicknameView(
                nickname:
                    widget.showRightNickname ? widget.rightNickname : null,
                timeStr: widget.timeStr,
              ),
              4.verticalSpace,
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // _buildChildView(BubbleType.send),
                  !widget.showLongPressMenu
                      ? _buildChildView(BubbleType.send)
                      : _buildCopyCustomPopupMenu(),
                ],
              ),
            ],
          ),
          10.horizontalSpace,
          AvatarView(
            width: 44.w,
            height: 44.h,
            textStyle: Styles.ts_FFFFFF_14sp_medium,
            url: widget.rightFaceUrl,
            text: widget.rightNickname,
            onTap: widget.onTapRightAvatar,
            onLongPress: widget.onLongPressRightAvatar,
          ),
        ],
      );

// MainAxisAlignment _layoutAlignment() =>
//     widget.isReceivedMsg ? MainAxisAlignment.start : MainAxisAlignment.end;

  Widget _buildCopyCustomPopupMenu() => CopyCustomPopupMenu(
        controller: widget.popupCtrl,
        barrierColor: Colors.transparent,
        arrowColor: Color(0xFF666666),
        verticalMargin: 0,
        menuBuilder: widget.menuBuilder,
        pressType: PressType.longPress,
        showArrow: widget.haveUsableMenu,
        // horizontalMargin: 0,
        child: _buildChildView(BubbleType.receiver),
      );
}
