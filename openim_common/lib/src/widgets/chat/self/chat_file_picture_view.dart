import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_openim_sdk/flutter_openim_sdk.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:openim_common/openim_common.dart';

class ChatFilePictureView extends StatefulWidget {
  const ChatFilePictureView({
    super.key,
    required this.message,
    required this.isISend,
    this.sendProgressStream,
  });
  final Stream<MsgStreamEv<int>>? sendProgressStream;
  final bool isISend;
  final Message message;

  @override
  State<ChatFilePictureView> createState() => _ChatFilePictureViewState();
}

class _ChatFilePictureViewState extends State<ChatFilePictureView> {
  String? _sourcePath;
  String? _sourceUrl;

  String? _snapshotUrl;
  late double _trulyWidth;
  late double _trulyHeight;

  Message get _message => widget.message;

  Widget? _child;

  @override
  void initState() {
    final picture = _message.fileElem;
    _sourcePath = picture?.filePath;
    _sourceUrl = picture?.sourceUrl;
    // _snapshotUrl = picture?.snapshotPicture?.url;

    var w = 1.0;
    var h = 1.0;

    // if (pictureWidth > w) {
    //   _trulyWidth = w;
    //   _trulyHeight = h;
    // } else {
      _trulyWidth = pictureWidth;
      _trulyHeight = _trulyWidth * h / w;
    // }

    final height = pictureWidth * 1.sh / 1.sw;

    if (_trulyHeight > 2 * height) {
      _trulyHeight = _trulyWidth;
    }

    _createChildView();
    super.initState();
  }

  Future<bool> _checkingPath() async {
    final valid = IMUtils.isNotNullEmptyStr(_sourcePath) &&
        await Permissions.checkStorage() &&
        await File(_sourcePath!).exists();
    _message.exMap['validPath_$_sourcePath'] = valid;
    return valid;
  }

  bool? get isValidPath => _message.exMap['validPath_$_sourcePath'];

  _createChildView() async {
    if (widget.isISend &&
        (isValidPath == true || isValidPath == null && await _checkingPath())) {
      _child = _buildPathPicture(path: _sourcePath!);
    } else if (IMUtils.isNotNullEmptyStr(_snapshotUrl)) {
      _child = _buildUrlPicture(url: _snapshotUrl!);
    } else if (IMUtils.isNotNullEmptyStr(_sourceUrl)) {
      _child = _buildUrlPicture(url: _sourceUrl!);
    }
    if (null != _child) {
      if (!mounted) return;
      setState(() {});
    }
  }

  Widget _buildUrlPicture({required String url}) => ImageUtil.networkImage(
    url: url,
    height: _trulyHeight,
    width: _trulyWidth,
    fit: BoxFit.fitWidth,
  );

  Widget _buildPathPicture({required String path}) => Stack(
    children: [
      ImageUtil.fileImage(
        file: File(path),
        height: _trulyHeight,
        width: _trulyWidth,
        fit: BoxFit.fitWidth,
      ),
      ChatProgressView(
        height: _trulyHeight,
        width: _trulyWidth,
        id: _message.clientMsgID!,
        stream: widget.sendProgressStream,
        isISend: widget.isISend,
        type: ProgressType.picture,
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final child = ClipRRect(
      borderRadius: borderRadius(widget.isISend),
      child: SizedBox(width: _trulyWidth, height: _trulyHeight, child: _child),
    );
    return child;
  }
}
