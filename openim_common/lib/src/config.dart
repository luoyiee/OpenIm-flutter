import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_openim_sdk/flutter_openim_sdk.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:openim_common/openim_common.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_bugly/flutter_bugly.dart';
import 'package:speech_to_text/speech_to_text.dart';

class Config {
  static Future init(Function() runApp) async {
    WidgetsFlutterBinding.ensureInitialized();
    try {
      final path = (await getApplicationDocumentsDirectory()).path;
      cachePath = '$path/';
      await DataSp.init();
      await Hive.initFlutter(path);
      await SpeechToTextUtil.instance.initSpeech();
      HttpUtil.init();
    } catch (e) {
      print("Initialization error: $e");
    }

    runApp();

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    var brightness = Platform.isAndroid ? Brightness.dark : Brightness.light;
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarBrightness: brightness,
      statusBarIconBrightness: brightness,
    ));
    // FlutterBugly.init(androidAppId: "4103e474e9", iOSAppId: "28849b1ca6");
  }

  static late String cachePath;
  static const uiW = 375.0;
  static const uiH = 812.0;

  static const String deptName = "OpenIM";
  static const String deptID = '0';

  static const double textScaleFactor = 1.0;

  static const secret = 'tuoyun';

  static const mapKey = '';

  static OfflinePushInfo offlinePushInfo = OfflinePushInfo(
    title: StrRes.offlineMessage,
    desc: "",
    iOSBadgeCount: true,
    iOSPushSound: '+1',
  );

  static const friendScheme = "io.openim.app/addFriend/";
  static const groupScheme = "io.openim.app/joinGroup/";

  static const _host = "121.41.226.80";

  // static const _host = "web.rentsoft.cn";

  static const _ipRegex =
      '((2[0-4]\\d|25[0-5]|[01]?\\d\\d?)\\.){3}(2[0-4]\\d|25[0-5]|[01]?\\d\\d?)';

  static bool get _isIP => RegExp(_ipRegex).hasMatch(_host);

  static String get serverIp {
    String? ip;
    var server = DataSp.getServerConfig();
    if (null != server) {
      ip = server['serverIP'];
    }
    return ip ?? _host;
  }

  static String get appAuthUrl {
    String? url;
    var server = DataSp.getServerConfig();
    if (null != server) {
      url = server['authUrl'];
      LoggerUtil.print('authUrl: $url');
    }
    return url ?? (_isIP ? "http://$_host:10008" : "https://$_host/chat");
  }

  static String get imApiUrl {
    String? url;
    var server = DataSp.getServerConfig();
    if (null != server) {
      url = server['apiUrl'];
      LoggerUtil.print('apiUrl: $url');
    }
    return url ?? (_isIP ? 'http://$_host:10002' : "https://$_host/api");
  }

  static String get imWsUrl {
    String? url;
    var server = DataSp.getServerConfig();
    if (null != server) {
      url = server['wsUrl'];
      LoggerUtil.print('wsUrl: $url');
    }
    return url ?? (_isIP ? "ws://$_host:10001" : "wss://$_host/msg_gateway");
  }

  // 工作群最大数量
  static int get workGroupMaxItems => 500;

// 普通群最大数量
  static int get normalGroupMaxItems => 50;


  static const devUserIds = ["5155462645", "18318990002", "4618921056"];

  // 机器人id
  // 有方医疗-Sophie, Nicole-高尔夫导购, 有方医疗-朱教授, Camera, Nicole-高尔夫导购, 段永平
  static const botIDs = [
    "3216431598",
    "3319670832",
    "4845282902",
    "5020681160",
    "7541408629",
    "8448328647"
  ];

  // 用户id, 隐藏开关
  static const testUserIds = [
    // my2
    // "7541478128",
    "1686677011",
    "1800018477",
    "2955365368",
    "3549502745",
    "3726015595",
    "3792530703",
    "3839132661",
    "4320364602",
    "4675068457",
    "4820243086",
    "5123545998",
    "5554614127",
    "6115200582",
    "6655641917",
    "8861997996",
    "9207186213",
    "9321133105",
    "9418318828"
  ];
}
// https://web.rentsoft.cn/chat_enterprise/account/code/send
// https://web.rentsoft.cn/chat_enterprise/user/find/full
// https://web.rentsoft.cn/chat_enterprise/user/find/full




