import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:openim_common/openim_common.dart';

import 'chat_disable_input_box.dart';
import 'self/chat_voice_record_bar.dart';

double kInputBoxMinHeight = 56.h;

class ChatInputBox extends StatefulWidget {
  const ChatInputBox({
    super.key,
    required this.toolbox,
    required this.multiOpToolbox,
    required this.emojiView,
    required this.voiceRecordBar,
    this.allAtMap = const {},
    this.atCallback,
    this.controller,
    this.focusNode,
    this.style,
    this.atStyle,
    this.inputFormatters,
    this.enabled = true,
    this.isMultiModel = false,
    this.isNotInGroup = false,
    this.hintText,
    this.onSend,
    this.showEmojiButton = true,
    this.showToolsButton = true,
    this.isGroupMuted = false,
    this.isInBlacklist = false,
    this.keyboardIcon,
    this.muteEndTime = 0,
    this.mutedIconColor = const Color(0xFFbdbdbd),
    this.iconColor,
    this.emojiIcon,
    this.speakIcon,
    this.quoteContent,
  });

  final AtTextCallback? atCallback;
  final Map<String, String> allAtMap;
  final FocusNode? focusNode;
  final TextEditingController? controller;
  final TextStyle? style;
  final TextStyle? atStyle;
  final List<TextInputFormatter>? inputFormatters;
  final bool enabled;
  final bool isMultiModel;
  final bool isNotInGroup;
  final bool showEmojiButton;
  final bool showToolsButton;
  final bool isGroupMuted;
  final bool isInBlacklist;
  final String? hintText;
  final Widget toolbox;
  final Widget multiOpToolbox;
  final Widget emojiView;
  final Widget? keyboardIcon;
  final ValueChanged<String>? onSend;
  final int muteEndTime;
  final Color mutedIconColor;
  final Color? iconColor;
  final Widget? emojiIcon;
  final Widget? speakIcon;
  final ChatVoiceRecordBar voiceRecordBar;
  final String? quoteContent;

  @override
  State<ChatInputBox> createState() => _ChatInputBoxState();
}

class _ChatInputBoxState extends State<ChatInputBox> {
  bool _toolsVisible = false;
  bool _emojiVisible = false;
  bool _leftKeyboardButton = false;
  bool _rightKeyboardButton = false;
  bool _sendButtonVisible = false;

  double get _opacity => (widget.enabled ? 1 : .4);

  @override
  void initState() {
    widget.focusNode?.addListener(() {
      if (widget.focusNode!.hasFocus) {
        setState(() {
          _toolsVisible = false;
          _emojiVisible = false;
          _leftKeyboardButton = false;
          _rightKeyboardButton = false;
        });
      }
    });

    widget.controller?.addListener(() {
      setState(() {
        _sendButtonVisible = widget.controller!.text.isNotEmpty;
      });
    });

    super.initState();
  }

  @override
  void dispose() {
    widget.controller?.dispose();
    widget.focusNode?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) widget.controller?.clear();
    return widget.isNotInGroup
        ? const ChatDisableInputBox()
        : widget.isMultiModel
            // ? const SizedBox()
            ? widget.multiOpToolbox
            : Column(
                children: [
                  Container(
                    constraints: BoxConstraints(minHeight: kInputBoxMinHeight),
                    color: Styles.c_F0F2F6,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _leftKeyboardButton ? _keyboardLeftBtn() : _speakBtn(),
                        // 12.horizontalSpace,
                        Flexible(
                          child: Stack(
                            children: [
                              Offstage(
                                  offstage: _leftKeyboardButton,
                                  child: Column(
                                    children: [
                                      _textFiled,
                                      if (widget.quoteContent != null &&
                                          "" != widget.quoteContent)
                                        _QuoteView(
                                            content: widget.quoteContent!),
                                    ],
                                  )),
                              Offstage(
                                offstage: !_leftKeyboardButton,
                                child: widget.voiceRecordBar,
                              ),
                            ],
                          ),
                        ),

                        12.horizontalSpace,
                        if (widget.showEmojiButton)
                          _rightKeyboardButton
                              ? _keyboardRightBtn()
                              : _emojiBtn(),
                        (_sendButtonVisible
                                ? ImageRes.sendMessage
                                : ImageRes.openToolbox)
                            .toImage
                          ..width = 32.w
                          ..height = 32.h
                          ..opacity = _opacity
                          ..onTap = _sendButtonVisible ? send : toggleToolbox,
                        12.horizontalSpace,
                      ],
                    ),
                  ),
                  Visibility(
                    visible: _toolsVisible,
                    child: FadeInUp(
                      duration: const Duration(milliseconds: 200),
                      child: widget.toolbox,
                    ),
                  ),
                  Visibility(
                    visible: _emojiVisible,
                    child: FadeInUp(
                      duration: const Duration(milliseconds: 200),
                      child: widget.emojiView,
                    ),
                  ),
                ],
              );
  }

  SizedBox get spaceView => SizedBox(
      width: widget.showEmojiButton || widget.showToolsButton ? 0 : 10.w);

  Widget get _textFiled => Container(
      alignment: Alignment.center,
      constraints: BoxConstraints(minHeight: kVoiceRecordBarHeight),
      margin: EdgeInsets.only(top: 10.h, bottom: 10.h),
      decoration: BoxDecoration(
        color: Styles.c_FFFFFF,
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Stack(
        children: [
          ChatTextField(
            allAtMap: widget.allAtMap,
            atCallback: widget.atCallback,
            controller: widget.controller,
            focusNode: widget.focusNode,
            style: widget.style ?? Styles.ts_0C1C33_17sp,
            atStyle: widget.atStyle ?? Styles.ts_0089FF_17sp,
            inputFormatters: widget.inputFormatters,
            enabled: widget.enabled,
            hintText: widget.hintText,
            textAlign: widget.enabled ? TextAlign.start : TextAlign.center,
          ),
          Visibility(
            visible: _isMuted,
            child: Container(
              alignment: Alignment.center,
              constraints: BoxConstraints(minHeight: 40.h),
              child: Text(
                widget.isInBlacklist
                    ? '对方已被拉入黑名单'
                    : (widget.isGroupMuted ? '已开启群禁言' : '你已被禁言'),
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Color(0xFF999999),
                ),
              ),
            ),
          ),
        ],
      ));

  void send() {
    if (!widget.enabled) return;
    if (!_emojiVisible) focus();
    if (null != widget.onSend && null != widget.controller) {
      widget.onSend!(widget.controller!.text.toString().trim());
    }
  }

  void toggleToolbox() {
    if (!widget.enabled) return;
    setState(() {
      _toolsVisible = !_toolsVisible;
      _emojiVisible = false;
      _leftKeyboardButton = false;
      _rightKeyboardButton = false;
      if (_toolsVisible) {
        unfocus();
      } else {
        focus();
      }
    });
  }

  void onTapSpeak() {
    if (!widget.enabled) return;
    Permissions.microphone(() => setState(() {
          _leftKeyboardButton = true;
          _rightKeyboardButton = false;
          _toolsVisible = false;
          _emojiVisible = false;
          unfocus();
        }));
  }

  void onTapLeftKeyboard() {
    if (!widget.enabled) return;
    setState(() {
      _leftKeyboardButton = false;
      _toolsVisible = false;
      _emojiVisible = false;
      focus();
    });
  }

  void onTapRightKeyboard() {
    if (!widget.enabled) return;
    setState(() {
      _rightKeyboardButton = false;
      _toolsVisible = false;
      _emojiVisible = false;
      focus();
    });
  }

  void onTapEmoji() {
    if (!widget.enabled) return;
    setState(() {
      _rightKeyboardButton = true;
      _leftKeyboardButton = false;
      _emojiVisible = true;
      _toolsVisible = false;
      unfocus();
    });
  }

  focus() => FocusScope.of(context).requestFocus(widget.focusNode);

  unfocus() => FocusScope.of(context).requestFocus(FocusNode());

  bool get _isMuted =>
      widget.isGroupMuted || _isUserMuted || widget.isInBlacklist;

  bool get _isUserMuted =>
      widget.muteEndTime * 1000 > DateTime.now().millisecondsSinceEpoch;

  Color? get _color => _isMuted ? widget.mutedIconColor : widget.iconColor;

  Widget _speakBtn() => _buildBtn(
        icon: widget.speakIcon ?? ImageUtil.speak(color: _color),
        onTap: _isMuted
            ? null
            : () {
                setState(() {
                  _leftKeyboardButton = true;
                  _rightKeyboardButton = false;
                  _toolsVisible = false;
                  _emojiVisible = false;
                  unfocus();
                });
              },
      );

  Widget _keyboardLeftBtn() => _buildBtn(
        icon: widget.keyboardIcon ?? ImageUtil.keyboard(color: _color),
        onTap: _isMuted
            ? null
            : () {
                setState(() {
                  _leftKeyboardButton = false;
                  _toolsVisible = false;
                  _emojiVisible = false;
                  focus();
                });
              },
      );

  Widget _keyboardRightBtn() => _buildBtn(
        // padding: emojiButtonPadding,
        icon: widget.keyboardIcon ?? ImageUtil.keyboard(color: _color),
        onTap: _isMuted
            ? null
            : () {
                setState(() {
                  _rightKeyboardButton = false;
                  _toolsVisible = false;
                  _emojiVisible = false;
                  focus();
                });
              },
      );

  // Widget _toolsBtn() => _buildBtn(
  //   icon: widget.toolsIcon ?? ImageUtil.tools(color: _color),
  //   padding: toolsButtonPadding,
  //   onTap: _isMuted
  //       ? null
  //       : () {
  //     setState(() {
  //       _toolsVisible = !_toolsVisible;
  //       _emojiVisible = false;
  //       _leftKeyboardButton = false;
  //       _rightKeyboardButton = false;
  //       if (_toolsVisible) {
  //         unfocus();
  //       } else {
  //         focus();
  //       }
  //     });
  //   },
  // );

  Widget _emojiBtn() => _buildBtn(
        padding: emojiButtonPadding,
        icon: widget.emojiIcon ?? ImageUtil.emoji(color: _color),
        onTap: _isMuted
            ? null
            : () {
                onTapEmoji();
              },
      );

  Widget _buildBtn({
    required Widget icon,
    Function()? onTap,
    EdgeInsetsGeometry? padding,
  }) =>
      GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.translucent,
        child: Container(
          padding: padding ?? EdgeInsets.symmetric(horizontal: 10.w),
          child: icon,
        ),
      );

  EdgeInsetsGeometry get emojiButtonPadding {
    if (widget.showToolsButton) {
      return EdgeInsets.only(left: 10.w, right: 5.w);
    } else {
      return EdgeInsets.only(left: 10.w, right: 10.w);
    }
  }
}

class _QuoteView extends StatelessWidget {
  const _QuoteView({
    Key? key,
    this.onClearQuote,
    required this.content,
  }) : super(key: key);
  final Function()? onClearQuote;
  final String content;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: 10.h, left: 56.w, right: 100.w),
      color: Styles.c_F0F2F6,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: onClearQuote,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 1.h, horizontal: 4.w),
          decoration: BoxDecoration(
            color: Styles.c_FFFFFF,
            borderRadius: BorderRadius.circular(4.r),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  content,
                  style: Styles.ts_8E9AB0_14sp,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              ImageRes.delQuote.toImage
                ..width = 14.w
                ..height = 14.h,
            ],
          ),
        ),
      ),
    );
  }
}
