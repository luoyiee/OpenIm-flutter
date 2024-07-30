import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../../openim_common.dart';
import '../plus/my_logger.dart';

class ChatCustomEmojiView extends StatelessWidget {
  const ChatCustomEmojiView({
    Key? key,
    this.index,
    this.data,
    // this.widgetWidth = 100,
    this.heroTag,
    required this.isISend,
  }) : super(key: key);

  /// 内置表情包，按位置显示
  final int? index;

  /// 收藏的表情包以加载url的方式
  /// {"url:"", "width":0, "height":0 }
  final String? data;

  // final double widgetWidth;
  final bool isISend;
  final String? heroTag;

  @override
  Widget build(BuildContext context) {
    // 收藏的url表情
    try {
      if (data != null) {
        var map = json.decode(data!);
        var url = map['url'];
        var w = map['width'] ?? 1.0;
        var h = map['height'] ?? 1.0;
        if (w is int) {
          w = w.toDouble();
        }
        if (h is int) {
          h = h.toDouble();
        }
        double trulyWidth;
        double trulyHeight;
        if (pictureWidth < w) {
          trulyWidth = pictureWidth;
          trulyHeight = trulyWidth * h / w;
        } else {
          trulyWidth = w;
          trulyHeight = h;
        }

        final child = ClipRRect(
          borderRadius: borderRadius(isISend),
          child: ImageUtil.networkImage(
            url: url,
            width: trulyWidth,
            height: trulyHeight,
            fit: BoxFit.fitWidth,
          ),
        );
        return null != heroTag ? Hero(tag: heroTag!, child: child) : child;
      }
    } catch (e, s) {
      myLogger.e({"error": e, "stack": s});
    }
    // 位置表情
    return Container();
  }
}
