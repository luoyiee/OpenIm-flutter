import 'package:flutter/material.dart';
import 'package:flutter_bugly/flutter_bugly.dart';
import 'package:openim_common/openim_common.dart';

import 'app.dart';

// void main() => Config.init(() => runApp(const ChatApp()));
/// 使用flutter异常上报
// void main() => FlutterBugly.postCatchedException(() {
//   Config.init(() => runApp(ChatApp()));
// });

void main() => Config.init(() => runApp(const ChatApp()));