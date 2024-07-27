import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:openim_common/openim_common.dart';

class ChatRadio extends StatelessWidget {
  const ChatRadio({
    super.key,
    this.checked = false,
    this.showRadio = false,
    this.onTap,
    this.enabled = true,
  });

  final bool checked;
  final Function()? onTap;
  final bool enabled;
  final bool showRadio;

  @override
  Widget build(BuildContext context) {
    // return GestureDetector(
    //   behavior: HitTestBehavior.translucent,
    //   child:
    //       (checked || !enabled ? ImageRes.radioSel : ImageRes.radioNor).toImage
    //         ..width = 20.w
    //         ..height = 20.h
    //         ..opacity = (enabled ? 1 : .5),
    // );
    return Visibility(
      visible: showRadio,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        // child: Container(
        //   margin: EdgeInsets.symmetric(horizontal: 12.w),
          child: (checked || !enabled ? ImageRes.radioSel : ImageRes.radioNor)
              .toImage
            ..width = 20.w
            ..height = 20.h
            ..opacity = (enabled ? 1 : .5),
        // ),
      ),
    );
  }
}
