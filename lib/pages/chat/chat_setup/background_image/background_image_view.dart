import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';

import 'background_image_logic.dart';

class BackgroundImagePage extends StatelessWidget {
  final logic = Get.find<BackgroundImageLogic>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TitleBar.back(
        title: StrRes.setChatBackground,
        right: _buildClearButton(),
      ),
      backgroundColor: Styles.c_F6F6F6,
      body: Column(
        children: [
          SizedBox(
            height: 12.h,
          ),
          _buildItemView(label: '从相册中选择', onTap: logic.openAlbum),
          _buildItemView(label: '拍摄', onTap: logic.openCamera),
        ],
      ),
    );
  }

  Widget _buildClearButton() => GestureDetector(
        onTap: logic.recover,
        behavior: HitTestBehavior.translucent,
        child: Container(
          height: 44.h,
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(
            horizontal: 10.w,
          ),
          child: Text(
            '还原',
            style: Styles.ts_333333_16sp,
          ),
        ),
      );

  Widget _buildItemView({
    required String label,
    Function()? onTap,
  }) =>
      Ink(
        color: Styles.c_FFFFFF,
        child: InkWell(
          onTap: onTap,
          child: Container(
            height: 50.h,
            padding: EdgeInsets.symmetric(horizontal: 22.w),
            decoration: BoxDecoration(
              border: BorderDirectional(
                  bottom: BorderSide(
                color: Styles.c_999999_opacity40p,
                width: 0.5,
              )),
            ),
            child: Row(
              children: [
                Text(
                  label,
                  style: Styles.ts_333333_16sp,
                ),
                Spacer(),
                Image.asset(
                  ImageRes.ic_moreArrow,
                  width: 18.h,
                  height: 18.h,
                  package: 'openim_common',
                ),
              ],
            ),
          ),
        ),
      );
}
