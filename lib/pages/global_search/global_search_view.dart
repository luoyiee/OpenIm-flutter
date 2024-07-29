import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:flutter_openim_sdk/flutter_openim_sdk.dart';
import 'package:search_keyword_text/search_keyword_text.dart';
import 'package:sprintf/sprintf.dart';
import 'global_search_logic.dart';

class GlobalSearchPage extends StatelessWidget {
  final logic = Get.find<GlobalSearchLogic>();

  GlobalSearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return TouchCloseSoftKeyboard(
      child: Scaffold(
        appBar: TitleBar.search(
          focusNode: logic.focusNode,
          controller: logic.searchCtrl,
          onSubmitted: (_) => logic.search(),
          onCleared: () => logic.focusNode.requestFocus(),
        ),
        backgroundColor: Styles.c_F8F9FA,
        body:
            // _emptyListView,
            Obx(
          () => Column(
            children: [
              _buildTabBar(),
              // if (logic.isSearchEmpty()) _buildNoSearch(),
              // if (!logic.isSearchEmpty())
              Expanded(
                child: SmartRefresher(
                  controller: logic.refreshController,
                  enablePullDown: false,
                  enablePullUp: logic.index.value == 1,
                  footer: IMViews.buildFooter(),
                  onLoading: () {
                    if (logic.index.value == 1) {
                      logic.searchFriend();
                    }
                  },
                  child: _childView(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget get _emptyListView => SizedBox(
        width: 1.sw,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            44.verticalSpace,
            StrRes.searchNotFound.toText..style = Styles.ts_8E9AB0_17sp,
          ],
        ),
      );

  Widget _buildTabBar() => Container(
        decoration: BoxDecoration(
          color: Styles.c_FFFFFF,
          border: BorderDirectional(
            bottom: BorderSide(
              color: Styles.c_EAEAEA,
              width: 1,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(
            logic.tabs.length,
            (index) => _buildTabItem(
              index: index,
              label: logic.tabs.elementAt(index),
              isChecked: logic.index.value == index,
            ),
          ),
        ),
      );

  Widget _buildTabItem({
    required String label,
    required int index,
    bool isChecked = false,
  }) =>
      GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => logic.switchTab(index),
        child: Container(
          height: 39.h,
          alignment: Alignment.center,
          child: Text(
            label,
            style: isChecked ? Styles.ts_1B72EC_14sp : Styles.ts_B0B0B0_14sp,
          ),
          decoration: BoxDecoration(
            border: BorderDirectional(
              bottom: BorderSide(
                color: isChecked ? Styles.c_1B72EC : Colors.transparent,
                width: 2,
              ),
            ),
          ),
        ),
      );

  // Widget _buildNoSearch() => SingleChildScrollView(
  //   child: Column(
  //     children: [
  //       SizedBox(
  //         height: 162.h,
  //       ),
  //       Image.asset(
  //         ImageRes.ic_searchEmpty,
  //         width: 163.h,
  //         height: 163.h,
  //       ),
  //       Text('没有更多搜索结果',
  //         style: Styles.ts_BABABA_16sp,
  //       )
  //     ],
  //   ),
  // );

  Widget _childView() {
    Widget child = SizedBox();
    if (logic.isSearchEmpty()) return _emptyListView;
    if (logic.index.value == 0) child = _buildAllSearchResultBody();
    if (logic.index.value == 1) child = _buildContactsSearchResultBody();
    if (logic.index.value == 2) child = _buildGroupSearchResultBody();
    if (logic.index.value == 3) child = _buildChatHistorySearchResultBody();
    if (logic.index.value == 4) child = _buildFileSearchResultBody();
    return child;
  }

  Widget _buildAllSearchResultBody() => ListView(
        children: [
          if (logic.contactsList.isNotEmpty)
            _buildGroupChildren(
              label: '联系人',
              onSeeMore: () => logic.switchTab(1),
              seeMore: logic.showMoreFriends,
              margin: EdgeInsets.zero,
              children: logic.subList(logic.contactsList).map((e) {
                return _buildFriendItemView(e);
              }).toList(),
            ),
          // if (logic.deptMemberList.isNotEmpty)
          //   _buildGroupChildren(
          //     label: StrRes.searchDeptMemberLabel,
          //     seeMore: logic.showMoreDeptMember,
          //     onSeeMore: () => logic.switchTab(1),
          //     children: logic.subList(logic.deptMemberList).map((e) {
          //       return _buildDeptMemberItemView(e);
          //     }).toList(),
          //   ),
          if (logic.groupList.isNotEmpty)
            _buildGroupChildren(
              label: '群组',
              onSeeMore: () => logic.switchTab(2),
              seeMore: logic.showMoreGroup,
              children: logic.subList(logic.groupList).map((e) {
                return _buildGroupItemView(
                  info: e,
                  showName: e.groupName!,
                );
              }).toList(),
            ),
          if (logic.textSearchResultItems.isNotEmpty)
            _buildGroupChildren(
              label: '聊天记录',
              onSeeMore: () => logic.switchTab(3),
              seeMore: logic.showMoreMessage,
              children: logic.subList(logic.textSearchResultItems).map((e) {
                return _buildChatHistoryItemView(
                  item: e,
                  showName: e.showName!,
                  faceURL: e.faceURL,
                  conversationType: e.conversationType!,
                  messageList: e.messageList!,
                  messageCount: e.messageCount!,
                );
              }).toList(),
            ),
          if (logic.fileMessageList.isNotEmpty)
            _buildGroupChildren(
              label: '文件',
              onSeeMore: () => logic.switchTab(4),
              seeMore: logic.showMoreFile,
              children: logic.subList(logic.fileMessageList).map((e) {
                return _buildFileItemView(
                  message: e,
                  fileName: e.fileElem!.fileName!,
                  showName: e.senderNickname!,
                );
              }).toList(),
            ),
        ],
      );

  Widget _buildGroupChildren({
    required String label,
    required List<Widget> children,
    Function()? onSeeMore,
    EdgeInsetsGeometry? margin,
    bool seeMore = true,
  }) =>
      Container(
        color: Styles.c_FFFFFF,
        margin: margin ?? EdgeInsets.only(bottom: 12.h),
        child: Column(
          children: [
            GestureDetector(
              onTap: seeMore ? onSeeMore : null,
              behavior: HitTestBehavior.translucent,
              child: Container(
                padding: EdgeInsets.only(
                  left: 22.w,
                  right: 22.w,
                  top: 12.h,
                ),
                child: Row(
                  children: [
                    Text(
                      label,
                      style: Styles.ts_333333_12sp,
                    ),
                    Spacer(),
                    if (seeMore)
                      Text(
                        '查看更多',
                        style: Styles.ts_1B72EC_12sp,
                      ),
                  ],
                ),
              ),
            ),
            ...children,
          ],
        ),
      );

  Widget _buildFileItemView({
    required Message message,
    required String fileName,
    required String showName,
  }) =>
      _buildInkButton(
        onTap: () => logic.previewFile(message),
        child: Row(
          children: [
            FaIcon(
              CommonUtil.fileIcon(fileName),
              color: Color(0xFFfec852),
              size: 40.h,
            ),
            // FaIcon(
            //   FontAwesomeIcons.solidFolderClosed,
            //   size: 42.h,
            //   color: Color(0xFFfec852),
            // ),
            SizedBox(width: 10.h),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SearchKeywordText(
                  text: fileName,
                  keyText: logic.searchKey,
                  style: Styles.ts_333333_14sp,
                  keyStyle: Styles.ts_1B72EC_14sp,
                ),
                Text(
                  showName,
                  style: Styles.ts_ADADAD_10sp,
                ),
              ],
            ),
          ],
        ),
      );

  Widget _buildInkButton({
    required Widget child,
    Function()? onTap,
  }) =>
      Ink(
        color: Styles.c_FFFFFF,
        child: InkWell(
          onTap: onTap,
          child: Container(
            // margin: EdgeInsets.only(bottom: 40),
            // height: 62.h,
            constraints: BoxConstraints(minHeight: 62.h),
            padding: EdgeInsets.symmetric(horizontal: 22.w),
            child: child,
          ),
        ),
      );

  Widget _buildChatHistoryItemView({
    required SearchResultItems item,
    required String showName,
    String? faceURL,
    required int conversationType,
    required int messageCount,
    required List<Message> messageList,
  }) =>
      _buildInkButton(
        onTap: () => logic.viewMessage(item),
        child: Row(
          children: [
            AvatarView(
              width: 42.h,
              height: 42.h,
              text: showName,
              url: faceURL,
              isGroup: conversationType == 2,
            ),
            SizedBox(width: 10.h),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Container(
                        constraints: BoxConstraints(maxWidth: 140.w),
                        child: Text(
                          showName,
                          style: Styles.ts_333333_14sp,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Spacer(),
                      if (messageCount > 0)
                        Text(
                          IMUtils.getCallTimeline(messageList.first.sendTime!),
                          style: Styles.ts_ADADAD_10sp,
                        ),
                    ],
                  ),
                  if (messageCount == 1)
                    SearchKeywordText(
                      text: logic.calContent(messageList.first),
                      keyText: logic.searchKey,
                      style: Styles.ts_ADADAD_12sp,
                      keyStyle: Styles.ts_1B72EC_12sp,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (messageCount > 1)
                    SearchKeywordText(
                      text: sprintf(StrRes.relatedChatHistory, [messageCount]),
                      // keyText: '三',
                      style: Styles.ts_ADADAD_12sp,
                      keyStyle: Styles.ts_1B72EC_12sp,
                    ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildGroupItemView({
    required GroupInfo info,
    required String showName,
  }) =>
      _buildInkButton(
        onTap: () => logic.viewGroup(info),
        child: Row(
          children: [
            AvatarView(
              width: 42.h,
              height: 42.h,
              isGroup: true,
            ),
            SizedBox(width: 10.h),
            Container(
              constraints: BoxConstraints(maxWidth: 200.w),
              child: SearchKeywordText(
                text: showName,
                keyText: logic.searchKey,
                style: Styles.ts_333333_14sp,
                keyStyle: Styles.ts_1B72EC_14sp,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );

  Widget _buildFriendItemView(UserInfo info) => _buildInkButton(
    onTap: () => logic.viewUserProfile(info),
    child: Row(
      children: [
        AvatarView(
          url: info.faceURL,
          text: info.nickname,
          width: 42.h,
          height: 42.h,
        ),
        Expanded(
          child: Container(
            constraints: BoxConstraints(minHeight: 42.h),
            margin: EdgeInsets.only(left: 14.w),
            padding: EdgeInsets.only(
              right: 22.w,
              top: 7.h,
              bottom: 7.h,
            ),
            // decoration: BoxDecoration(
            //   border: BorderDirectional(
            //     bottom: BorderSide(
            //       color: Color(0xFFF0F0F0),
            //       width: 1,
            //     ),
            //   ),
            // ),
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SearchKeywordText(
                  text: info.nickname ?? '',
                  keyText: logic.searchCtrl.text.trim(),
                  style: Styles.ts_333333_14sp,
                  keyStyle: Styles.ts_1B72EC_14sp,
                ),
                if (null != info.remark && info.remark!.isNotEmpty)
                  SearchKeywordText(
                    text: '${StrRes.remark}：${info.remark}',
                    keyText: logic.searchCtrl.text.trim(),
                    style: Styles.ts_ADADAD_10sp,
                    keyStyle: Styles.ts_1B72EC_10sp,
                  ),
              ],
            ),
          ),
        ),
      ],
    ),
  );


  Widget _buildContactsSearchResultBody() => CustomScrollView(
    // shrinkWrap: true,
    slivers: [
      if (logic.contactsList.isNotEmpty)
        SliverToBoxAdapter(
          child: Container(
            padding: EdgeInsets.only(left: 22.w, right: 22.w, top: 12.h),
            color: Styles.c_FFFFFF,
            child: Text(
           '联系人',
              style: Styles.ts_333333_12sp,
            ),
          ),
        ),
      if (logic.contactsList.isNotEmpty)
        SliverList(
          delegate: SliverChildBuilderDelegate(
                (context, index) =>
                _buildFriendItemView(logic.contactsList.elementAt(index)),
            childCount: logic.contactsList.length,
          ),
        ),
      // if (logic.deptMemberList.isNotEmpty)
      //   SliverToBoxAdapter(
      //     child: Container(
      //       padding: EdgeInsets.only(left: 22.w, right: 22.w, top: 12.h),
      //       color: PageStyle.c_FFFFFF,
      //       child: Text(
      //         StrRes.searchDeptMemberLabel,
      //         style: Styles.ts_333333_12sp,
      //       ),
      //     ),
      //   ),
      // if (logic.deptMemberList.isNotEmpty)
      //   SliverList(
      //     delegate: SliverChildBuilderDelegate(
      //           (context, index) => _buildDeptMemberItemView(
      //           logic.deptMemberList.elementAt(index)),
      //       childCount: logic.deptMemberList.length,
      //     ),
      //   ),
    ],
  );

  Widget _buildChatHistorySearchResultBody() => ListView(
    children: logic.textSearchResultItems.map((e) {
      return _buildChatHistoryItemView(
        item: e,
        showName: e.showName!,
        faceURL: e.faceURL,
        conversationType: e.conversationType!,
        messageList: e.messageList!,
        messageCount: e.messageCount!,
      );
    }).toList(),
  );

  Widget _buildGroupSearchResultBody() => ListView(
    children: logic.groupList.map((e) {
      return _buildGroupItemView(
        info: e,
        showName: e.groupName!,
      );
    }).toList(),
  );

  Widget _buildFileSearchResultBody() => ListView(
    children: logic.fileMessageList.map((e) {
      return _buildFileItemView(
        message: e,
        fileName: e.fileElem!.fileName!,
        showName: e.senderNickname!,
      );
    }).toList(),
  );
}
