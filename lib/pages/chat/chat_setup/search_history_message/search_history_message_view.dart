import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_openim_sdk/flutter_openim_sdk.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:search_keyword_text/search_keyword_text.dart';

import 'search_history_message_logic.dart';

class SearchHistoryMessagePage extends StatelessWidget {
  final logic = Get.find<SearchHistoryMessageLogic>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Styles.c_FFFFFF,
      appBar:
      TitleBar.search(
        focusNode: logic.focusNode,
        controller: logic.searchCtrl,
        onSubmitted: (_) => logic.search,
        onCleared: () => logic.focusNode.requestFocus(),
        onChanged: logic.onChanged,
      ),

      body: Obx(
        () => TouchCloseSoftKeyboard(
          child: logic.isNotKey()
              ? _buildDefaultView()
              : (logic.messageList.isEmpty
                  ? _buildNoFoundView()
                  : SmartRefresher(
                      controller: logic.refreshController,
                      footer: IMViews.buildFooter(),
                      enablePullDown: false,
                      enablePullUp: true,
                      onLoading: logic.load,
                      child: ListView.builder(
                        itemCount: logic.messageList.length,
                        itemBuilder: (_, index) {
                          var msg = logic.messageList.elementAt(index);
                          return _buildItemView(
                            message: msg,
                            url: msg.senderFaceUrl,
                            name: msg.senderNickname!,
                            // matchText: msg.content!,
                            matchText: msg.textElem?.content ?? "",
                            keyText: logic.searchCtrl.text.trim(),
                            time: msg.sendTime!,
                          );
                        },
                      ),
                    )),
        ),
      ),
    );
  }

  Widget _buildDefaultView() => Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            height: 57.h,
          ),
          Text(
            '指定搜索内容',
            style: Styles.ts_666666_14sp,
          ),
          SizedBox(
            height: 21.h,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: logic.searchPicture,
                child: Text(
                  StrRes.picture,
                  style: Styles.ts_1B61D6_16sp,
                ),
              ),
              GestureDetector(
                onTap: logic.searchVideo,
                behavior: HitTestBehavior.translucent,
                child: Text(
                  StrRes.video,
                  style: Styles.ts_1B61D6_16sp,
                ),
              ),
              GestureDetector(
                onTap: logic.searchFile,
                behavior: HitTestBehavior.translucent,
                child: Text(
                  StrRes.file,
                  style: Styles.ts_1B61D6_16sp,
                ),
              ),
            ],
          )
        ],
      );

  Widget _buildNoFoundView() => Container(
        alignment: Alignment.topCenter,
        margin: EdgeInsets.only(top: 98.h),
        child: logic.noFoundText(),
      );

  Widget _buildItemView({
    required Message message,
    String? url,
    required String name,
    required String matchText,
    required String keyText,
    required int time,
  }) =>
      GestureDetector(
        onTap: () => logic.previewMessageHistory(message),
        behavior: HitTestBehavior.translucent,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 22.w),
          child: Row(
            children: [
              AvatarView(
                url: url,
                width: 42.h,
                height: 42.h,
                text: name,
              ),
              Expanded(
                child: Container(
                  height: 64.h,
                  margin: EdgeInsets.only(left: 12.w),
                  decoration: BoxDecoration(
                    border: BorderDirectional(
                      bottom: BorderSide(
                        color: Styles.c_999999_opacity40p,
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Text(
                            name,
                            style: Styles.ts_333333_14sp,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Spacer(),
                          Text(
                            IMUtils.getChatTimeline(time),
                            style: Styles.ts_999999_12sp,
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 4.h,
                      ),
                      SearchKeywordText(
                        text: logic.calContent(message),
                        keyText: keyText,
                        style: Styles.ts_666666_14sp,
                        keyStyle: Styles.ts_1B61D6_14sp,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}
