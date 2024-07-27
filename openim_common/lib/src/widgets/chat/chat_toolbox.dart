import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:openim_common/openim_common.dart';

class ChatToolBox extends StatelessWidget {
  const ChatToolBox({
    super.key,
    this.onTapAlbum,
    this.onTapCall,
    this.onTapCamera,
    this.onTapCard,
    this.onTapFile,
    this.onTapLocation,
    this.onStartVoiceInput,
    this.onStopVoiceInput,
  });
  final Function()? onTapAlbum;
  final Function()? onTapCamera;
  final Function()? onTapCall;
  final Function()? onTapFile;
  final Function()? onTapCard;
  final Function()? onTapLocation;
  final Function()? onStartVoiceInput;
  final Function()? onStopVoiceInput;

  @override
  Widget build(BuildContext context) {
    final items = [
      if (onTapAlbum != null)
      ToolboxItemInfo(
        text: StrRes.toolboxAlbum,
        icon: ImageRes.toolboxAlbum,
        onTap: () {
          if (Platform.isAndroid) {
            Permissions.storage(onTapAlbum);
          } else {
            Permissions.photos(onTapAlbum);
          }
        },
      ),
      if (onTapAlbum != null)
      ToolboxItemInfo(
        text: StrRes.toolboxCamera,
        icon: ImageRes.toolboxCamera,
        onTap: () => Permissions.camera(onTapCamera),
      ),

      if (onTapCall != null)
        ToolboxItemInfo(
          text: StrRes.toolboxCall,
          icon: ImageRes.toolboxCall,
          onTap: onTapCall,
        ),

      if (onTapFile != null)
        ToolboxItemInfo(
          text: StrRes.toolboxFile,
          icon: ImageRes.toolboxFile,
          onTap: () => Permissions.storage(onTapFile),
        ),
      if (onTapCard != null)
        ToolboxItemInfo(
          text: StrRes.toolboxCard,
          icon: ImageRes.toolboxCard,
          onTap: onTapCard,
        ),
      if (onTapLocation != null)
        ToolboxItemInfo(
          text: StrRes.toolboxLocation,
          icon: ImageRes.toolboxLocation,
          onTap: () => Permissions.location(onTapLocation),
        ),
    ];

    return Container(
      color: Styles.c_F0F2F6,
      height: 224.h,
      child: GridView.builder(
        itemCount: items.length,
        padding: EdgeInsets.only(
          left: 16.w,
          right: 16.w,
          top: 6.h,
          bottom: 6.h,
        ),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          childAspectRatio: 78.w / 105.h,
          crossAxisSpacing: 10.w,
          mainAxisSpacing: 2.h,
        ),
        itemBuilder: (_, index) {
          final item = items.elementAt(index);
          return _buildItemView(
            icon: item.icon,
            text: item.text,
            onTap: item.onTap,
          );
        },
      ),
    );
  }

  Widget _buildItemView({
    required String text,
    required String icon,
    Function()? onTap,
  }) =>
      Column(
        children: [
          icon.toImage
            ..width = 58.w
            ..height = 58.h
            ..onTap = onTap,
          10.verticalSpace,
          text.toText..style = Styles.ts_0C1C33_12sp,
        ],
      );

  // Widget _buildVoiceInputLayout() => AnimatedBuilder(
  //     animation: _controller,
  //     builder: (BuildContext context, Widget? child) {
  //       return Transform.translate(
  //         offset: Offset(0, 190.h * _animation.value),
  //         child: Visibility(
  //           visible: _enabledVoiceInput,
  //           child: Container(
  //             color: Colors.white,
  //             child: Stack(
  //               children: [
  //                 Center(
  //                   child: LongPressRippleAnimation(
  //                     radius: 44.h,
  //                     child: ImageUtil.voiceInputNor(),
  //                     onStart: widget.onStartVoiceInput,
  //                     onStop: widget.onStopVoiceInput,
  //                   ),
  //                 ),
  //                 Align(
  //                   alignment: Alignment.centerLeft,
  //                   child: Container(
  //                     margin: EdgeInsets.only(left: 30.w),
  //                     child: IconButton(
  //                       icon: Icon(
  //                         Icons.arrow_drop_down,
  //                         // size: 48.w,
  //                       ),
  //                       onPressed: () {
  //                         _controller.reverse();
  //                       },
  //                     ),
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ),
  //       );
  //     });
}

class ToolboxItemInfo {
  String text;
  String icon;
  Function()? onTap;

  ToolboxItemInfo({required this.text, required this.icon, this.onTap});
}
