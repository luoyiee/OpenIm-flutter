import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:openim/utils/account_util.dart';
import 'package:openim_common/openim_common.dart';

import 'core/controller/im_controller.dart';
import 'core/controller/permission_controller.dart';
import 'core/controller/push_controller.dart';
import 'routes/app_pages.dart';
import 'utils/ai_util.dart';
import 'utils/conversation_util.dart';
import 'utils/message_util.dart';
import 'widgets/app_view.dart';

class ChatApp extends StatefulWidget {
  const ChatApp({Key? key}) : super(key: key);

  @override
  State<ChatApp> createState() => _ChatAppState();
}

class _ChatAppState extends State<ChatApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // 恢复状态或重新加载数据
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppView(
      builder: (locale, builder) => GetMaterialApp(
        debugShowCheckedModeBanner: true,
        enableLog: true,
        builder: builder,
        logWriterCallback: LoggerUtil.print,
        translations: TranslationService(),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        fallbackLocale: TranslationService.fallbackLocale,
        locale: locale,
        localeResolutionCallback: (locale, list) {
          Get.locale ??= locale;
          return locale;
        },
        supportedLocales: const [Locale('zh', 'CN'), Locale('en', 'US')],
        getPages: AppPages.routes,
        initialBinding: InitBinding(),
        initialRoute: AppRoutes.splash,
      ),
    );
  }
}

class InitBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<PermissionController>(PermissionController());
    Get.put<IMController>(IMController());
    Get.put<PushController>(PushController());
    Get.put<CacheController>(CacheController());
    Get.put<DownloadController>(DownloadController());
    // Get.put(BetaTestLogic());
    // Get.put(AccountUtil());
    Get.put(AiUtil());
    Get.put(ConversationUtil());
    Get.put(TranslateLogic());
    Get.put(TtsLogic());
    Get.put(MessageUtil());
  }
}
