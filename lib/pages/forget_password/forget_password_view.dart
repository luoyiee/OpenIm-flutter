import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';
import '../../widgets/phone_input_box.dart';
import 'forget_password_logic.dart';

class ForgetPasswordPage extends StatelessWidget {
  final logic = Get.find<ForgetPasswordLogic>();

  @override
  Widget build(BuildContext context) {
    return TouchCloseSoftKeyboard(
      child: Scaffold(
        backgroundColor: Styles.c_FFFFFF,
        appBar: TitleBar.back(),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // TitleBar.backButton(),
                Padding(
                  padding: EdgeInsets.only(left: 32.w, top: 49.h),
                  child: Text(
                    '忘记密码',
                    style: Styles.ts_171A1D_26sp_medium,
                  ),
                ),
                Container(
                    margin: EdgeInsets.only(left: 32.w, top: 44.h, right: 32.w),
                    child: Obx(() => logic.isPhoneRegister
                        ? InputBox.phone(
                            label: StrRes.phoneNumber,
                            hintText: StrRes.plsEnterPhoneNumber,
                            code: logic.areaCode.value,
                            onAreaCode: logic.openCountryCodePicker,
                            controller: logic.controller,
                          )
                        : InputBox.email(
                            label: '邮箱',
                            hintText: '请输入邮箱',
                            controller: logic.controller,
                          ))),
                Obx(() => Button(
                      margin:
                          EdgeInsets.only(top: 206.h, left: 32.w, right: 32.w),
                      text: StrRes.verificationCode,
                      enabled: logic.enabled.value,
                      onTap: logic.nextStep,
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
