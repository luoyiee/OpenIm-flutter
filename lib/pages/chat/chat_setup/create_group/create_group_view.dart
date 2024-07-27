import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:openim/src/models/contacts_info.dart';
import 'package:openim_common/openim_common.dart';
import 'package:sprintf/sprintf.dart';

import 'create_group_logic.dart';

class CreateGroupInChatSetupPage extends StatelessWidget {
  final logic = Get.find<CreateGroupInChatSetupLogic>();

  @override
  Widget build(BuildContext context) {
    return TouchCloseSoftKeyboard(
      child: Scaffold(
        backgroundColor: Styles.c_F6F6F6,
        appBar: TitleBar.back(
          title: '发起群聊',
        ),
        body: SafeArea(
          child: Column(
            children: [
              _buildGroupInfoView(),
              _buildGroupMemberView(),
              Spacer(),
              _buildButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroupInfoView() => Container(
        height: 80.h,
        padding: EdgeInsets.symmetric(horizontal: 22.w),
        margin: EdgeInsets.only(top: 10.h, bottom: 10.h),
        color: Styles.c_FFFFFF,
        child: Row(
          children: [
            Obx(() => logic.avatarUrl.value.isNotEmpty
                ? AvatarView(
                    url: logic.avatarUrl.value,
                    width: 44.h,
                    height: 44.h,
                    onTap: () => logic.setAvatar(),
                  )
                : ImageButton(
                    onTap: () => logic.setAvatar(),
                    imgStrRes: ImageRes.ic_uploadPhoto,
                    imgWidth: 44.h,
                    imgHeight: 44.h,
                  )),
            SizedBox(
              width: 20.w,
            ),
            Expanded(
              child: TextField(
                controller: logic.nameCtrl,
                decoration: InputDecoration(
                  hintText: '取个群名称方便后续搜索',
                  hintStyle: Styles.ts_999999_16sp,
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            )
          ],
        ),
      );

  Widget _buildGroupMemberView() => Obx(() => Container(
        height: 140.h,
        decoration: BoxDecoration(
          color: Styles.c_FFFFFF,
          boxShadow: [
            BoxShadow(
              color: Styles.c_000000_opacity10p,
              blurRadius: 4,
              offset: Offset(0, 2.h),
            ),
          ],
        ),
        padding: EdgeInsets.only(
          left: 22.w,
          right: 22.w,
          top: 14.h,
        ),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  StrRes.groupMember,
                  style: Styles.ts_999999_14sp,
                ),
                Spacer(),
                Text(
                  '${logic.memberList.length}人',
                  style: Styles.ts_999999_14sp,
                ),
                // SizedBox(
                //   width: 4.w,
                // ),
                // Image.asset(
                //   ImageRes.ic_next,
                //   width: 8.w,
                //   height: 14.h,
                // ),
              ],
            ),
            Expanded(
              child: GridView.builder(
                itemCount: logic.length(),
                // padding: EdgeInsets.zero,
                padding: EdgeInsets.only(top: 16.h),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                ),
                itemBuilder: (_, index) {
                  return logic.itemBuilder(
                    index: index,
                    builder: (info) => _buildItemView(info),
                    addButton: () => _buildAddDelBtn(
                      imgStrRes: ImageRes.ic_memberAdd,
                      onTap: logic.opMember,
                    ),
                    delButton: () => _buildAddDelBtn(
                      imgStrRes: ImageRes.ic_memberDel,
                      onTap: logic.opMember,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ));

  Widget _buildItemView(ContactsInfo info) => Container(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AvatarView(
              width: 40.h,
              height: 40.h,
              url: info.faceURL,
              text: info.nickname,
            ),
            SizedBox(
              height: 6.h,
            ),
            Container(
              width: 50.w,
              alignment: Alignment.center,
              child: Text(
                info.getShowName(),
                style: Styles.ts_999999_12sp,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            )
          ],
        ),
      );

  Widget _buildAddDelBtn({
    required String imgStrRes,
    Function()? onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          child: Column(
            children: [
              Image.asset(
                imgStrRes,
                width: 40.h,
                height: 40.h,
              ),
              SizedBox(
                height: 6.h,
              ),
              Text(
                '',
                style: Styles.ts_999999_12sp,
              )
            ],
          ),
        ),
      );

  Widget _buildButton() => DebounceButton(
        onTap: () async => await logic.completeCreation(),
        builder: (context, onTap) {
          return Ink(
            color: Styles.c_1B72EC,
            height: 45.h,
            child: InkWell(
              onTap: onTap,
              child: Container(
                alignment: Alignment.center,
                child: Text(
                  StrRes.completeCreation,
                  style: Styles.ts_FFFFFF_18sp,
                ),
              ),
            ),
          );
        },
      );
// Widget _buildButton() => Ink(
//       color: PageStyle.c_1B72EC,
//       height: 45.h,
//       child: InkWell(
//         onTap: () => logic.completeCreation(),
//         child: Container(
//           alignment: Alignment.center,
//           child: Text(
//             StrRes.completeCreation,
//             style: PageStyle.ts_FFFFFF_18sp,
//           ),
//         ),
//       ),
//     );
}
