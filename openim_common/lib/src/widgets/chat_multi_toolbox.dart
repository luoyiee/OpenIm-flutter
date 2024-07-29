import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../res/styles.dart';
import '../utils/image_util.dart';

class ChatMultiSelToolbox extends StatelessWidget {
  const ChatMultiSelToolbox({Key? key, this.onDelete, this.onMergeForward})
      : super(key: key);
  final Function()? onDelete;
  final Function()? onMergeForward;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: 40.h),
      decoration: BoxDecoration(color: Color(0xFFF6F6F6), boxShadow: [
        // BoxShadow(color: Color(0xFF000000).withOpacity(0.2), blurRadius: 6)
      ]),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          GestureDetector(
              onTap: onDelete,
              behavior: HitTestBehavior.translucent,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    color: Colors.white,
                    margin: EdgeInsets.only(bottom: 4.h),
                    padding: EdgeInsets.all(12.h),
                    child: ImageUtil.assetImage('ic_multi_tool_del',
                        width: 20.w, height: 22.h, color: Styles.c_FF381F),
                  ),
                  Text(
                    '删除',
                    style: TextStyle(fontSize: 13, color: Styles.c_FF381F),
                  )
                ],
              )),
          GestureDetector(
              onTap: onMergeForward,
              behavior: HitTestBehavior.translucent,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    color: Colors.white,
                    margin: EdgeInsets.only(bottom: 4.h),
                    padding: EdgeInsets.all(12.h),
                    child: ImageUtil.assetImage(
                      'ic_multi_tool_merge_forward',
                      width: 19.w,
                      height: 19.h,
                    ),
                  ),
                  Text(
                    '合并转发',
                    style: TextStyle(fontSize: 13),
                  )
                ],
              ))
        ],
      ),
    );
  }
}
