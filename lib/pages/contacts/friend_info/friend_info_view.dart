import 'dart:ui';

import 'package:common_utils/common_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';

import '../../../widgets/switch_button.dart';
import '../../home/home_logic.dart';
import 'friend_info_logic.dart';

class FriendInfoPage extends StatelessWidget {
  final logic = Get.find<FriendInfoLogic>();
  final homeLogic = Get.find<HomeLogic>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TitleBar.back(),
      backgroundColor: Styles.c_F6F6F6,
      body: Obx(
        () => Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildHeaderView(),
                        8.verticalSpace,
                        if (logic.isMyFriend)
                          _buildItemView(
                            label: 'ID号',
                            onTap: () => logic.copyID(),
                            margin: EdgeInsets.only(bottom: 8.h),
                            child: _buildIDCopyView(
                              label: 'ID号',
                              value: logic.userInfo.value.userID,
                            ),
                          ),
                        if (logic.iHaveAdminOrOwnerPermission.value)
                          Container(
                            margin: EdgeInsets.only(bottom: 8.h),
                            child: _buildGroupMemberSetupView(),
                          ),
                        if (logic.canViewProfile)
                          _buildItemView(
                            label: StrRes.personalInfo,
                            onTap: () => logic.viewPersonalInfo(),
                            margin: EdgeInsets.only(bottom: 8.h),
                            showArrowBtn: true,
                          ),
                        if (logic.isMyFriend)
                          _buildItemView(
                            label: '好友设置',
                            onTap: () => logic.toFriendSettings(),
                            margin: EdgeInsets.only(bottom: 8.h),
                            showArrowBtn: true,
                          ),
                        SizedBox(height: 116.h),
                      ],
                    ),
                  ),
                  _buildButtonGroupView(),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderView() => Container(
        height: 96.h,
        padding: EdgeInsets.symmetric(horizontal: 22.w),
        color: Styles.c_FFFFFF,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AvatarView(
              width: 48.h,
              height: 48.h,
              url: logic.userInfo.value.faceURL,
              text: logic.userInfo.value.nickname,
              textStyle: Styles.ts_FFFFFF_24sp,
              enabledPreview: true,
            ),
            SizedBox(width: 18.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Text(
                      logic.getShowName(),
                      style: Styles.ts_333333_20sp,
                    ),
                    SizedBox(width: 6.w),
                    if (logic.userInfo.value.isMale)
                      FaIcon(
                        FontAwesomeIcons.mars,
                        color: Styles.c_71BCFF,
                        size: 11.w,
                      ),
                    if (!logic.userInfo.value.isMale)
                      FaIcon(
                        FontAwesomeIcons.venus,
                        color: Styles.c_EB84CA,
                        size: 11.w,
                      ),
                  ],
                ),
                if (logic.onlineStatusDesc.isNotEmpty)
                  Row(
                    children: [
                      Container(
                        margin: EdgeInsets.only(
                          right: 4.w,
                          top: 2.h,
                        ),
                        width: 6.h,
                        height: 6.h,
                        decoration: BoxDecoration(
                          color: logic.onlineStatus.value
                              ? Styles.c_10CC64
                              : Styles.c_959595,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Text(
                        logic.onlineStatusDesc.value,
                        style: Styles.ts_999999_12sp,
                      )
                    ],
                  ),
                // if (homeLogic.organizationName.isNotEmpty)
                //   Text(
                //     homeLogic.organizationName,
                //     style: PageStyle.ts_1D6BED_14sp,
                //   ),
              ],
            ),
          ],
        ),
      );

  Widget _buildGroupMemberSetupView() => Column(
        children: [
          _buildItemGroupMemberInfoView(
            label: '群昵称',
            value: logic.groupUserNickname.value,
          ),
          if (logic.joinGroupTime.value != 0)
            _buildItemGroupMemberInfoView(
              label: '入群时间',
              value: DateUtil.formatDateMs(
                logic.joinGroupTime.value * 1000,
                format: DateFormats.zh_y_mo_d,
              ),
            ),
          if (logic.joinGroupMethod.isNotEmpty)
            _buildItemGroupMemberInfoView(
              label: StrRes.joinGroupMethod,
              value: logic.joinGroupMethod.value,
            ),
          if (logic.showSetAdminFunction.value)
            _buildItemView(
              label: '设为管理员',
              showSwitchBtn: true,
              switchOn: logic.hasAdminPermission.value,
              onTap: () => logic.toggleAdmin(),
            ),
          if (logic.showMuteFunction.value)
            _buildItemView(
              label: StrRes.setMute,
              value: logic.mutedTime.isEmpty ? null : logic.mutedTime.value,
              onTap: () => logic.setMute(),
              showArrowBtn: true,
              showLine: false,
            ),
        ],
      );

  Widget _buildBtn({
    required String icon,
    required String label,
    required TextStyle style,
    Function()? onTap,
  }) =>
      GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: onTap,
        child: Column(
          children: [
            // Image.asset(
            //   icon,
            //   width: 50.h,
            //   height: 50.h,
            // ),
            icon.toImage
              ..width = 50.h
              ..height = 50.h,
            SizedBox(
              height: 4.h,
            ),
            Text(
              label,
              style: style,
            ),
          ],
        ),
      );

  Widget _buildItemView({
    required String label,
    String? value,
    TextStyle? style,
    AlignmentGeometry alignment = Alignment.centerLeft,
    Function()? onTap,
    bool showArrowBtn = false,
    bool showSwitchBtn = false,
    bool switchOn = false,
    bool showLine = false,
    EdgeInsetsGeometry? margin,
    Widget? child,
  }) =>
      Container(
        margin: margin,
        child: Ink(
          color: Styles.c_FFFFFF,
          height: 55.h,
          child: InkWell(
            onTap: showSwitchBtn ? null : onTap,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 22.w),
              decoration: showLine
                  ? BoxDecoration(
                      border: BorderDirectional(
                        bottom: BorderSide(
                          width: .5,
                          color: Styles.c_999999_opacity40p,
                        ),
                      ),
                    )
                  : null,
              alignment: alignment,
              child: child ??
                  (showArrowBtn || showSwitchBtn
                      ? Row(
                          children: [
                            Text(
                              label,
                              style: style ?? Styles.ts_333333_18sp,
                            ),
                            Spacer(),
                            if (null != value)
                              Text(
                                value,
                                style: style ?? Styles.ts_1B61D6_16sp,
                              ),
                            SizedBox(
                              width: 5.w,
                            ),
                            if (showArrowBtn)
                              ImageRes.ic_next.toImage
                                ..width = 7.w
                                ..height = 13.h,
                            if (showSwitchBtn)
                              SwitchButton(
                                width: 51.w,
                                height: 31.h,
                                on: switchOn,
                                onTap: onTap,
                              ),
                          ],
                        )
                      : Text(
                          label,
                          style: style ?? Styles.ts_333333_18sp,
                        )),
            ),
          ),
        ),
      );

  Widget _buildItemGroupMemberInfoView({
    required String label,
    String? value,
  }) =>
      Container(
        height: 55.h,
        color: Styles.c_FFFFFF,
        padding: EdgeInsets.symmetric(horizontal: 22.w),
        child: Row(
          children: [
            Container(
              constraints: BoxConstraints(minWidth: 100.w),
              child: Text(
                label,
                style: Styles.ts_333333_18sp,
              ),
            ),
            if (value != null)
              Text(
                value,
                style: Styles.ts_333333_16sp,
              ),
          ],
        ),
      );

  Widget _buildIDCopyView({
    required String label,
    String? value,
    TextStyle? style,
  }) =>
      Row(
        children: [
          Container(
            constraints: BoxConstraints(minWidth: 100.w),
            child: Text(
              label,
              style: style ?? Styles.ts_333333_18sp,
            ),
          ),
          if (value != null)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  constraints: BoxConstraints(maxWidth: 150.w),
                  child: Text(
                    value,
                    style: style ?? Styles.ts_333333_18sp,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(
                  width: 8.w,
                ),
                FaIcon(
                  FontAwesomeIcons.copy,
                  color: Styles.c_1D6BED,
                  size: 12.w,
                ),
              ],
            ),
        ],
      );

  Widget _buildOrganizationInfoView({
    required String label,
    String? value,
  }) =>
      Container(
        padding: EdgeInsets.only(bottom: 16.h),
        child: Row(
          children: [
            Container(
              constraints: BoxConstraints(minWidth: 80.w),
              child: Text(
                label,
                style: Styles.ts_999999_16sp,
              ),
            ),
            if (value != null)
              Text(
                value,
                style: Styles.ts_333333_16sp,
              ),
          ],
        ),
      );

  // List<Widget> _buildDeptListView() {
  //   final list = <Widget>[];
  //   logic.userDeptList.forEach((e) {
  //     list
  //       ..add(_buildOrganizationInfoView(
  //         label: StrRes.department,
  //         value: e.department?.name ?? '',
  //       ))
  //       ..add(_buildOrganizationInfoView(
  //         label: StrRes.position,
  //         value: e.member?.position ?? '',
  //       ))
  //       ..add(Container(
  //         color: PageStyle.c_999999_opacity40p,
  //         height: 0.5,
  //         margin: EdgeInsets.only(bottom: 16.h),
  //       ));
  //   });
  //   if (list.isNotEmpty) list.removeLast();
  //   return list;
  // }

  Widget _buildButtonGroupView() => logic.isMyself()
      ? SizedBox()
      : Positioned(
          bottom: 0.h,
          width: 1.sw,
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
              child: Container(
                padding: EdgeInsets.only(top: 15.h, bottom: 25.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (logic.showMsgSendButton)
                      _buildBtn(
                        icon: ImageRes.ic_sendMsg,
                        label: '发送消息',
                        style: Styles.ts_1D6BED_14sp,
                        onTap: () => logic.toChat(),
                      ),
                    if (logic.showAddFriendButton)
                      _buildBtn(
                        icon: ImageRes.ic_sendAddFriendMsg,
                        label: StrRes.addFriend,
                        style: Styles.ts_1D6BED_14sp,
                        onTap: () => logic.addFriend(),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
}
