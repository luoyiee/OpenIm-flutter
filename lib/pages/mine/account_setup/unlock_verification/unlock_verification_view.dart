import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';

import '../../../../widgets/switch_button.dart';
import 'unlock_verification_logic.dart';

class UnlockVerificationPage extends StatelessWidget {
  final logic = Get.find<UnlockVerificationLogic>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TitleBar.back(
        title: '解锁设置',
      ),
      backgroundColor: Styles.c_F8F8F8,
      body: Obx(() => Column(
            children: [
              12.verticalSpace,
              _buildItemView(
                label: StrRes.password,
                on: logic.passwordEnabled.value,
                onTap: logic.togglePwdLock,
              ),
              if (logic.passwordEnabled.value &&
                  (logic.isSupportedBiometric.value &&
                      logic.canCheckBiometrics.value))
                _buildItemView(
                  label: StrRes.biometrics,
                  on: logic.biometricsEnabled.value,
                  onTap: logic.toggleBiometricLock,
                ),
              // _buildItemView(
              //   label: StrRes.gesture,
              // ),
            ],
          )),
    );
  }

  Widget _buildItemView({
    required String label,
    bool on = false,
    Function()? onTap,
  }) =>
      Container(
        height: 58.h,
        padding: EdgeInsets.symmetric(horizontal: 22.w),
        decoration: BoxDecoration(
          color: Styles.c_FFFFFF,
          border: BorderDirectional(
            bottom: BorderSide(
              color: Styles.c_999999_opacity40p,
              width: .5,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: Styles.ts_333333_18sp,
              ),
            ),
            SwitchButton(
              width: 42.w,
              height: 25.h,
              on: on,
              onTap: onTap,
            )
          ],
        ),
      );
}
