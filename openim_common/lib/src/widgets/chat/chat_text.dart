import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:openim_common/openim_common.dart';

class ChatText extends StatelessWidget {
  const ChatText(
      {super.key,
      this.isISend = false,
      required this.text,
      this.allAtMap = const <String, String>{},
      this.prefixSpan,
      this.patterns = const <MatchPattern>[],
      this.textAlign = TextAlign.left,
      this.overflow = TextOverflow.clip,
      this.textStyle,
      this.maxLines,
      this.textScaleFactor = 1.0,
      this.model = TextModel.match,
      this.onVisibleTrulyText,
      this.selectMode = false,
      this.onSelectionChanged});

  final bool isISend;
  final String text;
  final TextStyle? textStyle;
  final InlineSpan? prefixSpan;
  final TextAlign textAlign;
  final TextOverflow overflow;
  final int? maxLines;
  final double textScaleFactor;
  final Map<String, String> allAtMap;
  final List<MatchPattern> patterns;
  final TextModel model;
  final Function(String? text)? onVisibleTrulyText;
  final bool selectMode;
  final Function({SelectedContent? selectedContent})? onSelectionChanged;

  @override
  Widget build(BuildContext context) => MatchTextView(
      text: text,
      textStyle: textStyle ??
          (isISend ? Styles.ts_FFFFFF_16sp : Styles.ts_333333_16sp),
      matchTextStyle: textStyle ??
          (isISend ? Styles.ts_FFFFFF_16sp : Styles.ts_333333_16sp),
      prefixSpan: prefixSpan,
      textAlign: textAlign,
      overflow: overflow,
      textScaleFactor: textScaleFactor,
      allAtMap: allAtMap,
      patterns: patterns,
      model: model,
      maxLines: maxLines,
      onVisibleTrulyText: onVisibleTrulyText,
      selectMode: selectMode,
      onSelectionChanged: onSelectionChanged);
}
