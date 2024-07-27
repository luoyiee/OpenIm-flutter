
import 'package:flutter/material.dart';
import 'package:flutter_openim_sdk/flutter_openim_sdk.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:openim_common/openim_common.dart';
import 'package:openim_common/src/utils/utils.dart';

import '../../../res/styles.dart';
import 'chat_at_text.dart';
import 'chat_merge_view.dart';
import 'titlebar.dart';

class PreviewMergeMsg extends StatelessWidget {
  PreviewMergeMsg({Key? key, required this.messageList, required this.title})
      : super(key: key);
  final List<Message> messageList;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: EnterpriseTitleBar.back(
        title: title,
        showShadow: false,
      ),
      backgroundColor: Styles.c_F8F8F8,
      body: ListView.builder(
        itemCount: messageList.length,
        shrinkWrap: true,
        itemBuilder: (_, index) => _buildItemView(index),
      ),
    );
  }

  Widget _buildItemView(int index) {
    var message = messageList.elementAt(index);
    var atMap = <String, String>{};
    var text;
    var child;
    switch (message.contentType) {
      case MessageType.text:
        {
          text = message.textElem;
        }
        break;
      case MessageType.atText:
        {
          try {
            // Map map = json.decode(message.atTextElem!);
            // text = map['text'];
            // var list = message.atTextElem!.atUsersInfo;
            // list?.forEach((element) {
            //   atMap[element.atUserID!] = element.groupNickname!;
            // });
          } catch (e) {}
        }
        break;
      case MessageType.picture:
        {
          text = '[图片]';
        }
        break;
      case MessageType.voice:
        {
          text = '[语音]';
        }
        break;
      case MessageType.video:
        {
          text = '[视频]';
        }
        break;
      case MessageType.file:
        {
          text = '[文件]';
        }
        break;
      case MessageType.location:
        {
          text = '[位置]';
        }
        break;
      case MessageType.quote:
        {
          text = message.quoteElem?.text ?? '';
        }
        break;
      case MessageType.card:
        {
          text = '[名片]';
        }
        break;
      case MessageType.merger:
        child = Container(
          // margin: EdgeInsets.only(left: 12.w),
          padding: EdgeInsets.only(left: 16.w, top: 4.h),
          // decoration: BoxDecoration(
          //   borderRadius: BorderRadius.circular(4),
          //   color: PageStyle.c_979797,
          // ),
          child: ChatMergeMsgView(
            title: message.mergeElem!.title!,
            summaryList: message.mergeElem!.abstractList!,
          ),
        );
        break;
      case MessageType.custom:
        {
          text = IMUtils.parseMsg(message);
        }
        break;
      default:
        {
          text = "";
        }
        break;
    }

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => IMUtils.parseClickEvent(message, messageList: messageList),
      child: Container(
        padding: EdgeInsets.only(
          left: 22.w,
          right: 22.w,
          top: 16.h,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AvatarView(
              width: 42.h,
              height: 42.h,
              url: message.senderFaceUrl,
              text: message.senderNickname,
            ),
            Expanded(
              child: Container(
                margin: EdgeInsets.only(left: 12.w),
                padding: EdgeInsets.only(bottom: 16.h),
                decoration: BoxDecoration(
                  border: BorderDirectional(
                    bottom: BorderSide(
                      color: Color(0xFFDFDFDF),
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            message.senderNickname ?? '',
                            style: Styles.ts_666666_12sp,
                          ),
                          if (text != null && child == null)
                            ChatAtText(
                              text: text,
                              textStyle: Styles.ts_333333_14sp,
                              allAtMap: atMap,
                              patterns: <MatchPattern>[
                                MatchPattern(
                                  type: PatternType.at,
                                  style: Styles.ts_999999_14sp,
                                ),
                                MatchPattern(
                                  type: PatternType.email,
                                  style: Styles.ts_999999_14sp,
                                ),
                                MatchPattern(
                                  type: PatternType.url,
                                  style: Styles.ts_999999_14sp,
                                ),
                                MatchPattern(
                                  type: PatternType.mobile,
                                  style: Styles.ts_999999_14sp,
                                ),
                                MatchPattern(
                                  type: PatternType.tel,
                                  style: Styles.ts_999999_14sp,
                                ),
                              ],
                            ),
                          if (child != null) child!,
                        ],
                      ),
                    ),
                    Text(
                      IMUtils.getChatTimeline(message.sendTime!),
                      style: Styles.ts_999999_12sp,
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
