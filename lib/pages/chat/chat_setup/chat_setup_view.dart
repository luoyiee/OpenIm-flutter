import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';

import '../../../routes/app_navigator.dart';
import '../../../widgets/switch_button.dart';
import 'chat_setup_logic.dart';

class ChatSetupPage extends StatelessWidget {
  final logic = Get.find<ChatSetupLogic>();

  ChatSetupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TitleBar.back(),
      backgroundColor: Styles.c_F8F9FA,
      body: SingleChildScrollView(
        child: Obx(() => Column(
              children: [
                _buildBaseInfoView(),


                SizedBox(height: 12.h),
                Container(
                  height: 140.h,
                  color: Styles.c_FFFFFF,
                  padding: EdgeInsets.fromLTRB(22.w, 18.h, 22.w, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '查找聊天记录',
                        style: Styles.ts_333333_16sp,
                      ),
                      SizedBox(height: 26.h),
                      Row(
                        children: [
                          _buildItemBtn(
                            imgStr: ImageRes.ic_searchHistory,
                            label: StrRes.search,
                            onTap: logic.searchMessage,
                          ),
                          _buildItemBtn(
                            imgStr: ImageRes.ic_searchPic,
                            label: StrRes.picture,
                            onTap: logic.searchPicture,
                          ),
                          _buildItemBtn(
                            imgStr: ImageRes.ic_searchVideo,
                            label: StrRes.video,
                            onTap: logic.searchVideo,
                          ),
                          _buildItemBtn(
                            imgStr: ImageRes.ic_searchFile,
                            label: StrRes.file,
                            onTap: logic.searchFile,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12.h),
                _buildItemView(
                  label: StrRes.topContacts,
                  on: logic.topContacts.value,
                  showSwitchBtn: true,
                  onClickSwitchBtn: () => logic.toggleTopContacts(),
                  showUnderline: true,
                ),
                _buildItemView(
                  label: '消息免打扰',
                  on: logic.noDisturb.value,
                  showSwitchBtn: true,
                  onClickSwitchBtn: () => logic.toggleNoDisturb(),
                  showUnderline: true,
                ),
                if (logic.noDisturb.value)
                  _buildItemView(
                    label: '好友消息设置',
                    showArrow: true,
                    value: logic.noDisturbIndex.value == 0
                        ? '接收消息但不提示'
                        : '屏蔽该好友',
                    onTap: logic.noDisturbSetting,
                    showUnderline: logic.noDisturb.value,
                  ),
                _buildItemView(
                  label: StrRes.burnAfterReading,
                  showSwitchBtn: true,
                  onTap: logic.togglePrivateChat,
                  on: logic.burnAfterReading.value,
                  showUnderline: logic.burnAfterReading.value,
                ),
                if (logic.burnAfterReading.value)
                  _buildItemView(
                    label: '时间设置',
                    showArrow: true,
                    value: logic.getBurnAfterReadingDuration(),
                    onTap: logic.setBurnAfterReadingDuration,
                  ),
                SizedBox(height: 12.h),
                _buildItemView(
                  label: StrRes.setChatBackground,
                  showArrow: true,
                  onTap: logic.background,
                  showUnderline: true,
                ),
                _buildItemView(
                  label: StrRes.fontSize,
                  showArrow: true,
                  onTap: logic.fontSize,
                ),
                // SizedBox(height: 12.h),
                // _buildItemView(
                //   label: StrRes.complaint,
                //   showArrow: true,
                // ),
                SizedBox(height: 12.h),
                _buildItemView(
                  label: '清空聊天记录',
                  showArrow: true,
                  onTap: () => logic.clearChatHistory(),
                ),
                SizedBox(height: 40.h),
              ],
            )),
      ),
    );
  }

  Widget _buildBaseInfoView() => Container(
        margin: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: Styles.c_FFFFFF,
          borderRadius: BorderRadius.circular(6.r),
        ),
        child: Row(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: logic.viewUserInfo,
              child: SizedBox(
                width: 60.w,
                child: Column(
                  children: [
                    AvatarView(
                      width: 44.w,
                      height: 44.h,
                      text: logic.conversationInfo.value.showName,
                      url: logic.conversationInfo.value.faceURL,
                    ),
                    8.verticalSpace,
                    (logic.conversationInfo.value.showName ?? '').toText
                      ..style = Styles.ts_8E9AB0_14sp
                      ..maxLines = 1
                      ..overflow = TextOverflow.ellipsis,
                  ],
                ),
              ),
            ),
            SizedBox(
              width: 60.w,
              child: Column(
                children: [
                  ImageRes.addFriendTobeGroup.toImage
                    ..width = 44.w
                    ..height = 44.h
                    ..onTap = logic.createGroup,
                  8.verticalSpace,
                  ''.toText
                    ..style = Styles.ts_8E9AB0_14sp
                    ..maxLines = 1
                    ..overflow = TextOverflow.ellipsis,
                ],
              ),
            ),
          ],
        ),
      );



  Widget _buildItemView({
    required String label,
    String? value,
    bool showArrow = false,
    bool showSwitchBtn = false,
    Function()? onTap,
    bool on = true,
    Function()? onClickSwitchBtn,
    bool showUnderline = false,
  }) =>
      GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: onTap,
        child: Container(
          height: 50.h,
          padding: EdgeInsets.symmetric(horizontal: 22.w),
          decoration: BoxDecoration(
            color: Styles.c_FFFFFF,
            border: showUnderline
                ? BorderDirectional(
              bottom: BorderSide(
                color: Color(0x66999999),
                width: 0.5,
              ),
            )
                : null,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: Styles.ts_333333_16sp,
                ),
              ),
              if (null != value)
                Text(
                  value,
                  style: Styles.ts_999999_14sp,
                ),
              if (showArrow)
                Padding(
                  padding: EdgeInsets.only(left: 6.w),
                  child: Image.asset(
                    ImageRes.ic_next,
                    width: 10.w,
                    height: 17.h,
                    color: Styles.c_999999,
                    package: 'openim_common',
                  ),
                ),
              if (showSwitchBtn)
                SwitchButton(
                  onTap: onClickSwitchBtn,
                  on: on,
                )
            ],
          ),
        ),
      );

  Widget _buildItemBtn({
    required String imgStr,
    required String label,
    Function()? onTap,
  }) =>
      Expanded(
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.translucent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                imgStr,
                width: 22.w,
                height: 18.h,
                package: 'openim_common',
              ),
              SizedBox(height: 11.h),
              Text(
                label,
                style: Styles.ts_666666_12sp,
              ),
            ],
          ),
        ),
      );

  void fontSize() {
    AppNavigator.startFontSizeSetup();
  }

  void background() {
    AppNavigator.startSetChatBackground();
    /*IMWidget.openPhotoSheet(
      toUrl: false,
      crop: false,
      onData: (String path, String? url) async {
        String? value = await CommonUtil.createThumbnail(
          path: path,
          minWidth: 1.sw,
          minHeight: 1.sh,
        );
        if (null != value) chatLogic.changeBackground(value);
      },
    );*/
  }
}
