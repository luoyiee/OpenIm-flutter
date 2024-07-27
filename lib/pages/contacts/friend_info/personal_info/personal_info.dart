import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';
import 'package:url_launcher/url_launcher.dart';

import '../friend_info_logic.dart';

class PersonalInfoPage extends StatelessWidget {
  final logic = Get.find<FriendInfoLogic>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Styles.c_F8F8F8,
      appBar: TitleBar.back(),
      body: Obx(
        () => SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(
                height: 12.h,
              ),
              _buildItemView(
                label: StrRes.avatar,
                url: logic.userInfo.value.faceURL,
                showAvatar: true,
                name: logic.userInfo.value.showName,
              ),
              _buildItemView(
                label: StrRes.nickname,
                value: logic.userInfo.value.showName,
              ),
              _buildItemView(
                label: StrRes.gender,
                value: logic.userInfo.value.isMale ? StrRes.man : StrRes.woman,
              ),
              _buildItemView(
                label: '生日',
                value: '${logic.userInfo.value.birth}',
              ),
              if (null != logic.userInfo.value.phoneNumber &&
                  logic.userInfo.value.phoneNumber!.isNotEmpty)
                _buildItemView(
                    label: '手机号码',
                    value: logic.userInfo.value.phoneNumber,
                    onTap: () {
                      Get.bottomSheet(
                        BottomSheetView(
                          // itemBgColor: PageStyle.c_FFFFFF,
                          items: [
                            SheetItem(
                              label: '',
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(30),
                                topRight: Radius.circular(30),
                              ),
                              textStyle: Styles.ts_666666_16sp,
                              // height: 53.h,
                            ),
                            SheetItem(
                              label: '复制',
                              alignment: MainAxisAlignment.center,
                              onTap: () {
                                IMUtils.copy(text: logic.userInfo.value.phoneNumber!);
                              },
                            ),
                            SheetItem(
                              label: '拨打',
                              alignment: MainAxisAlignment.center,
                              onTap: () async {
                                final url = 'tel:${logic.userInfo.value.phoneNumber!}';
                                if (await canLaunch(url)) {
                                  await launch(url);
                                } else {
                                  throw 'Could not launch $url';
                                }
                              },
                            ),
                          ],
                        ),
                        // barrierColor: Colors.transparent,
                      );
                    }),
              if (null != logic.userInfo.value.email && logic.userInfo.value.email!.isNotEmpty)
                _buildItemView(
                  label: StrRes.email,
                  value: logic.userInfo.value.email,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemView({
    required String label,
    String? name,
    String? value,
    String? url,
    bool showAvatar = false,
    bool showQrIcon = false,
    bool showArrow = false,
    Function()? onTap,
  }) =>
      Ink(
        height: 58.h,
        color: Styles.c_FFFFFF,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 22.w),
            decoration: BoxDecoration(
                border: BorderDirectional(
              bottom: BorderSide(
                color: Styles.c_999999_opacity40p,
                width: 0.5,
              ),
            )),
            child: Row(
              children: [
                Text(
                  label,
                  style: Styles.ts_333333_18sp,
                ),
                Spacer(),
                if (showAvatar)
                  AvatarView(
                    width: 40.w,
                    height: 40.h,
                    url: url,
                    text: name,
                    enabledPreview: true,
                  ),
                if (showQrIcon)
                  Image.asset(
                    ImageRes.ic_mineQrCode,
                    width: 22.w,
                    height: 22.h,
                    color: Styles.c_999999,
                  ),
                if (null != value && value.isNotEmpty)
                  Text(
                    value,
                    style: Styles.ts_999999_16sp,
                  ),
                if (showArrow)
                  Padding(
                    padding: EdgeInsets.only(left: 12.w),
                    child: Image.asset(
                      ImageRes.ic_next,
                      width: 10.w,
                      height: 17.h,
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
}
