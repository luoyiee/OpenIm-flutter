import 'dart:io';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:openim_common/openim_common.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ImageUtil {
  ImageUtil._();

  static const _package = "openim_common";

  static Widget assetImage(
    String res, {
    double? width,
    double? height,
    BoxFit? fit,
    Color? color,
  }) =>
      Image.asset(
        imageResStr(res),
        width: width,
        height: height,
        fit: fit,
        color: color,
        package: _package,
      );

  static Widget networkImage({
    required String url,
    double? width,
    double? height,
    int? cacheWidth,
    int? cacheHeight,
    BoxFit? fit,
    bool loadProgress = true,
    bool clearMemoryCacheWhenDispose = false,
    bool lowMemory = false,
    Widget? errorWidget,
    BorderRadius? borderRadius,
  }) =>
      ExtendedImage.network(
        url,
        width: width,
        height: height,
        fit: fit,
        borderRadius: borderRadius,
        cacheWidth: _calculateCacheWidth(width, cacheWidth, lowMemory),
        cacheHeight: _calculateCacheHeight(height, cacheHeight, lowMemory),
        cache: true,
        clearMemoryCacheWhenDispose: clearMemoryCacheWhenDispose,
        handleLoadingProgress: true,
        clearMemoryCacheIfFailed: true,
        loadStateChanged: (ExtendedImageState state) {
          switch (state.extendedImageLoadState) {
            case LoadState.loading:
              {
                final ImageChunkEvent? loadingProgress = state.loadingProgress;
                final double? progress =
                    loadingProgress?.expectedTotalBytes != null
                        ? loadingProgress!.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null;

                return SizedBox(
                  width: 15.0,
                  height: 15.0,
                  child: loadProgress
                      ? Center(
                          child: SizedBox(
                            width: 15.0,
                            height: 15.0,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              value: progress,
                            ),
                          ),
                        )
                      : null,
                );
              }
            case LoadState.completed:
              return null;
            case LoadState.failed:
              state.imageProvider.evict();
              return errorWidget ??
                  (ImageRes.pictureError.toImage
                    ..width = width
                    ..height = height);
          }
        },
      );

  static Widget fileImage({
    required File file,
    double? width,
    double? height,
    int? cacheWidth,
    int? cacheHeight,
    BoxFit? fit,
    bool loadProgress = true,
    bool clearMemoryCacheWhenDispose = false,
    bool lowMemory = false,
    Widget? errorWidget,
    BorderRadius? borderRadius,
  }) =>
      ExtendedImage.file(
        file,
        width: width,
        height: height,
        fit: fit,
        borderRadius: borderRadius,
        cacheWidth: _calculateCacheWidth(width, cacheWidth, lowMemory),
        cacheHeight: _calculateCacheHeight(height, cacheHeight, lowMemory),
        clearMemoryCacheWhenDispose: clearMemoryCacheWhenDispose,
        clearMemoryCacheIfFailed: true,
        loadStateChanged: (ExtendedImageState state) {
          switch (state.extendedImageLoadState) {
            case LoadState.loading:
              {
                final ImageChunkEvent? loadingProgress = state.loadingProgress;
                final double? progress =
                    loadingProgress?.expectedTotalBytes != null
                        ? loadingProgress!.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null;

                return SizedBox(
                  width: 15.0,
                  height: 15.0,
                  child: loadProgress
                      ? Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            value: progress,
                          ),
                        )
                      : null,
                );
              }
            case LoadState.completed:
              return null;
            case LoadState.failed:
              state.imageProvider.evict();
              return errorWidget ?? ImageRes.pictureError.toImage;
          }
        },
      );

  static int? _calculateCacheWidth(
    double? width,
    int? cacheWidth,
    bool lowMemory,
  ) {
    if (!lowMemory) return null;
    if (null != cacheWidth) return cacheWidth;
    final maxW = .6.sw;
    return (width == null ? maxW : (width < maxW ? width : maxW)).toInt();
  }

  static int? _calculateCacheHeight(
    double? height,
    int? cacheHeight,
    bool lowMemory,
  ) {
    if (!lowMemory) return null;
    if (null != cacheHeight) return cacheHeight;
    final maxH = .6.sh;
    return (height == null ? maxH : (height < maxH ? height : maxH)).toInt();
  }

  ///拓展区域
  static Widget sendFailed() => assetImage(
        'ic_send_failed',
        width: 16.h,
        height: 16.h,
      );

  static Widget lowMemoryNetworkImage({
    required String url,
    double? width,
    double? height,
    int? cacheWidth,
    int? cacheHeight,
    BoxFit? fit,
    bool loadProgress = true,
    bool clearMemoryCacheWhenDispose = true,
    bool lowMemory = true,
    Widget? errorWidget,
  }) =>
      _cachedNetworkImage(
        url: url,
        width: width,
        height: height,
        cacheWidth: cacheHeight,
        cacheHeight: cacheHeight,
        fit: fit,
        loadProgress: loadProgress,
        clearMemoryCacheWhenDispose: clearMemoryCacheWhenDispose,
        lowMemory: lowMemory,
        errorWidget: errorWidget,
      );

  static Widget _cachedNetworkImage({
    required String url,
    double? width,
    double? height,
    int? cacheWidth,
    int? cacheHeight,
    BoxFit? fit,
    bool loadProgress = true,
    bool clearMemoryCacheWhenDispose = true,
    bool lowMemory = true,
    Widget? errorWidget,
  }) =>
      CachedNetworkImage(
        imageUrl: url,
        width: width,
        height: height,
        fit: fit,
        memCacheWidth: _calculateCacheWidthOld(width),
        // memCacheHeight: cacheHeight,
        // placeholder: placeholder,
        progressIndicatorBuilder: (context, url, progress) => SizedBox(
          width: 10.0,
          height: 10.0,
          child: loadProgress
              ? Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    value: progress.progress ?? 0,
                  ),
                )
              : null,
        ),
        errorWidget: (_, url, er) =>
            errorWidget ?? error(width: width, height: height),
      );

  static int? _calculateCacheWidthOld(double? width) {
    return (width == null ? 1.sw : (width < 1.sw ? width : 1.sw)).toInt();
  }

  static Widget error({
    double? width,
    double? height,
  }) =>
      assetImage('ic_load_error',
          height: height, width: width, color: const Color(0x8F999999));

  ///拓展
  static Widget menuSpeaker() => Icon(
        Icons.volume_up,
        size: 18.w,
        color: Colors.white,
      );

  ///拓展【没有免费的】
  // static Widget menuSpeakToText() =>
  //     Icon(Icons.font_download_sharp, size: 18.w);
  ///拓展
  static Widget menuSpeak2Speed() => Icon(
        Icons.play_arrow,
        size: 18.w,
        color: Colors.white,
      );

  static Widget menuCopy() =>
      assetImage('ic_menu_copy', width: 18.w, height: 18.w);

  static Widget menuDel() => assetImage(
        'ic_menu_del',
        width: 18.w,
        height: 18.w,
      );

  static Widget menuForward() => assetImage(
        'ic_menu_forward',
        width: 16.w,
        height: 16.w,
      );

  static Widget menuMultiChoice() => assetImage(
        'ic_menu_multichoice',
        width: 18.w,
        height: 18.w,
      );

  static Widget menuReply() => assetImage(
        'ic_menu_reply',
        width: 18.w,
        height: 18.w,
      );

  static Widget menuRevoke() => assetImage(
        'ic_menu_revoke',
        width: 18.w,
        height: 18.w,
      );

  static Widget menuDownload() => assetImage(
        'ic_menu_download',
        width: 18.w,
        height: 18.w,
      );

  static Widget menuTranslation() => assetImage(
        'ic_menu_translation',
        width: 18.w,
        height: 18.w,
      );

  static Widget menuAddEmoji() => assetImage(
        'ic_menu_add_emoji',
        width: 19.w,
        height: 19.w,
      );

  static AssetImage emojiImage(String key) => AssetImage(
        ImageUtil.imageResStr(emojiFaces[key]),
        package: _package,
      );

  static String imageResStr(var name) => "assets/images/$name.webp";

  static Widget search() => assetImage(
        'ic_search',
        width: 24.h,
        height: 24.h,
        color: Color(0xFF333333),
      );

  static Widget back({Color color = const Color(0xFF333333)}) => assetImage(
        'ic_back',
        width: 12.w,
        height: 20.h,
        color: color,
      );

  static Widget add() => assetImage(
        "ic_add",
        width: 24.h,
        height: 24.h,
        color: Color(0xFF333333),
      );

  static Widget keyboard({Color? color}) => svg(
        'ic_keyboard',
        width: 32.h,
        height: 32.h,
        // color: color,
        color: Color(0xFF333333),
      );

  static Widget svg(
    String name, {
    double? width,
    double? height,
    BoxFit? fit,
    Color? color,
  }) {
    return SvgPicture.asset(
      "assets/images/$name.svg",
      width: width,
      height: height,
      color: color,
      package: _package,
    );
  }

  static Widget emoji({Color? color}) => svg(
        'ic_emoji',
        width: 32.h,
        height: 32.h,
        // color: color,
        color: Color(0xFF333333),
      );

  static Widget speak({Color? color}) => svg(
        'ic_speak',
        width: 32.h,
        height: 32.h,
        // color: color,
        color: Color(0xFF333333),
      );

  static Widget delQuote() => assetImage(
        'ic_del_quote',
        width: 14.w,
        height: 15.w,
      );

  static Widget tools({Color? color}) => svg(
        'ic_tools',
        width: 26.h,
        height: 26.h,
        color: color,
      );
}
