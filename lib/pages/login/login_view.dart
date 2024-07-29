import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';

import 'login_logic.dart';

class LoginPage extends StatelessWidget {
  final logic = Get.find<LoginLogic>();

  LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      child: TouchCloseSoftKeyboard(
        isGradientBg: true,
        child: SingleChildScrollView(
          child: Column(
            children: [
              88.verticalSpace,
              ImageRes.loginLogo.toImage
                ..width = 64.w
                ..height = 64.h
                ..onDoubleTap = logic.configService,
              StrRes.welcome.toText..style = Styles.ts_0089FF_17sp_semibold,
              51.verticalSpace,
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 32.w),
                child: Obx(() => Column(
                      children: [
                        Obx(
                          () => logic.loginIndex.value == 0
                              ? InputBox.phone(
                                  label: StrRes.phoneNumber,
                                  hintText: StrRes.plsEnterPhoneNumber,
                                  code: logic.areaCode.value,
                                  onAreaCode: logic.openCountryCodePicker,
                                  controller: logic.phoneCtrl,
                                )
                              : InputBox.email(
                                  label: '邮箱',
                                  hintText: '请输入邮箱',
                                  controller: logic.emailCtrl,
                                ),
                        ),
                        16.verticalSpace,
                        Obx(
                          () => logic.isPasswordLogin
                              ? InputBox.password(
                                  label: StrRes.password,
                                  hintText: StrRes.plsEnterPassword,
                                  controller: logic.pwdCtrl,
                                )
                              : InputBox.verificationCode(
                                  label: StrRes.verificationCode,
                                  hintText: StrRes.plsEnterVerificationCode,
                                  inputFormatters: <TextInputFormatter>[
                                    FilteringTextInputFormatter.allow(
                                        RegExp(r'[0-9]')),
                                    LengthLimitingTextInputFormatter(
                                        6), // 设置最大长度为10
                                  ],
                                  controller: logic.codeCtrl,
                                ),
                        ),
                        16.verticalSpace,
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            GestureDetector(
                              // onTap: () => logic.forgetPassword(),
                              onTap: () =>
                                  _showCupertinoModalPopup(context, false),
                              behavior: HitTestBehavior.translucent,
                              child: Text(
                                '忘记密码',
                                style: TextStyle(
                                    color: Colors.black.withOpacity(0.7),
                                    fontSize: 12),
                              ),
                            ),
                            GestureDetector(
                              onTap: logic.switchLoginType,
                              behavior: HitTestBehavior.translucent,
                              child: Obx(() => Text(
                                    logic.isPasswordLogin ? '验证码登录' : '密码登录',
                                    style: Styles.ts_0089FF_12sp,
                                  )),
                            ),
                          ],
                        ),
                        46.verticalSpace,
                        Button(
                          text: StrRes.login,
                          enabled: logic.enabled.value,
                          onTap: logic.login,
                        ),
                        26.verticalSpace,
                      ],
                    )),
              ),
              Divider(color: Colors.black.withOpacity(0.1), height: 1.h),
              26.verticalSpace,
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 32.w),
                child: Obx(
                  () => Button(
                    enabledColor: Styles.c_E8EAEF.withOpacity(0.6),
                    textStyle: TextStyle(
                      color: Styles.c_0089FF,
                      fontSize: 16.sp,
                    ),
                    text: logic.loginIndex.value == 0 ? '邮箱 登录' : '手机号 登录',
                    onTap: () {
                      logic.switchLoginTab(logic.loginIndex.value == 0 ? 1 : 0);
                    },
                  ),
                ),
              ),
              142.verticalSpace,
              RichText(
                text: TextSpan(
                  text: StrRes.noAccountYet,
                  style: Styles.ts_8E9AB0_12sp,
                  children: [
                    TextSpan(
                      text: StrRes.registerNow,
                      style: Styles.ts_0089FF_12sp,
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => _showCupertinoModalPopup(context, true),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCupertinoModalPopup(BuildContext context, bool register) {
    showCupertinoModalPopup<int>(
      context: context,
      builder: (BuildContext context) {
        return CupertinoActionSheet(
          // title: Text('选择一个选项'),
          actions: <CupertinoActionSheetAction>[
            CupertinoActionSheetAction(
              child: Text(register ? '邮箱 立即注册' : '通过邮箱',
                  style: TextStyle(color: Styles.c_0089FF)),
              onPressed: () {
                Navigator.pop(context); // Return index 0
                if (register) {
                  logic.registerNow(0);
                } else {
                  logic.forgetPassword(0);
                }
              },
            ),
            CupertinoActionSheetAction(
              child: Text(register ? '手机号 立即注册' : '通过手机号',
                  style: TextStyle(color: Styles.c_0089FF)),
              onPressed: () {
                Navigator.pop(context); // Return index 1
                if (register) {
                  logic.registerNow(1);
                } else {
                  logic.forgetPassword(1);
                }
              },
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            child: Text('取消', style: TextStyle(color: Styles.c_0089FF)),
            onPressed: () {
              Navigator.pop(context, null); // Return null for cancellation
            },
          ),
        );
      },
    );
  }
}
