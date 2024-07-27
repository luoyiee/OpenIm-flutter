import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sprintf/sprintf.dart';

import '../../title_bar.dart';

class ChatWebViewMap extends StatefulWidget {
  const ChatWebViewMap({
    super.key,
    this.mapAppKey = "",
  });

  final String mapAppKey;

  @override
  _ChatWebViewMapState createState() => _ChatWebViewMapState();
}

class _ChatWebViewMapState extends State<ChatWebViewMap> {
  final GlobalKey webViewKey = GlobalKey();
  // static final mapKey = "TMNBZ-3CGC6-C6SSL-EJA3B-E2P5Q-V7F6Q";
  // static final mapKey = "";

  static final mapKey = "FURBZ-KUHEJ-CXTFQ-XB5WL-CYDB5-LXBIB";
  static final mapBackUrl = "http://callback";
  // static final mapBackUrl = "http://3gimg.qq.com/lightmap/components/locationPicker2/back.html";

  // https://apis.map.qq.com/tools/locpicker?search=1&type=0&backurl=http://3gimg.qq.com/lightmap/components/locationPicker2/back.html&key=yourkey&referer=myapp
 // "https://apis.map.qq.com/tools/locpicker?search=1&type=0&backurl=http://3gimg.qq.com/lightmap/components/locationPicker2/back.html&key=OB4BZ-D4W3U-B7VVO-4PJWW-6TKDJ-WPB77&referer=myapp"

  // static final mapThumbnailSize = '600*300';
  static final mapThumbnailSize = '1200*600';
  InAppWebViewController? webViewController;
  InAppWebViewGroupOptions options = InAppWebViewGroupOptions(
      crossPlatform: InAppWebViewOptions(
        useShouldOverrideUrlLoading: true,
        mediaPlaybackRequiresUserGesture: false,
      ),
      android: AndroidInAppWebViewOptions(
        useHybridComposition: true,
        domStorageEnabled: true,
        geolocationEnabled: true,
      ),
      ios: IOSInAppWebViewOptions(
        allowsInlineMediaPlayback: true,
      ));

  late PullToRefreshController pullToRefreshController;

  String url = "";
  double progress = 0;
  double? latitude;
  double? longitude;
  String? description;

  ///高德地图 https://lbs.amap.com/api/lightmap/guide/picker?type=spa

  ///https://blog.csdn.net/Cynthia_Yue27/article/details/109999359
  final mapUrl =
      "https://apis.map.qq.com/tools/locpicker?search=1&type=0&backurl=$mapBackUrl&key=$mapKey&referer=im-android&policy=1";
  final mapThumbnailUrl =
      "https://apis.map.qq.com/ws/staticmap/v2/?center=%s&zoom=18&size=$mapThumbnailSize&maptype=roadmap&markers=size:large|color:0xFFCCFF|label:k|%s&key=$mapKey";

  @override
  void initState() {
    super.initState();

    pullToRefreshController = PullToRefreshController(
      options: PullToRefreshOptions(
        color: Colors.blue,
      ),
      onRefresh: () async {
        if (Platform.isAndroid) {
          webViewController?.reload();
        } else if (Platform.isIOS) {
          webViewController?.loadUrl(
              urlRequest: URLRequest(url: await webViewController?.getUrl()));
        }
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: TitleBar.back(
        title: '位置',
        titleStyle: TextStyle(
          fontSize: 18.sp,
          color: Color(0xFF333333),
        ),
        right: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            if (null == latitude || null == longitude) {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text(
                    '请选择一个位置',
                    style: TextStyle(
                      fontSize: 18.sp,
                      color: Color(0xFF333333),
                    ),
                  ),
                  actions: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      behavior: HitTestBehavior.translucent,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        child: Text(
                          '确定',
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: Color(0xFF1B72EC),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
              return;
            }
            Navigator.pop(context, {
              'latitude': latitude,
              'longitude': longitude,
              'description': description,
            });
          },
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 22.w),
            child: Text(
              '确认',
              style: TextStyle(
                fontSize: 18.sp,
                color: Color(0xFF333333),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            InAppWebView(
              key: webViewKey,
              // contextMenu: contextMenu,
              initialUrlRequest: URLRequest(url: Uri.parse(mapUrl)),
              // initialFile: "assets/index.html",
              initialUserScripts: UnmodifiableListView<UserScript>([]),
              initialOptions: options,
              pullToRefreshController: pullToRefreshController,
              onWebViewCreated: (controller) {
                webViewController = controller;
              },
              onLoadStart: (controller, url) {},
              androidOnGeolocationPermissionsShowPrompt:
                  (controller, origin) async {
                return GeolocationPermissionShowPromptResponse(
                    origin: origin, allow: true, retain: true);
              },
              androidOnPermissionRequest: (ctrl, origin, res) async {
                return PermissionRequestResponse(
                  resources: res,
                  action: PermissionRequestResponseAction.GRANT,
                );
              },
              shouldOverrideUrlLoading: (controller, navigationAction) async {
                var uri = navigationAction.request.url!;
                if (uri.toString().startsWith(mapBackUrl)) {
                  try {
                    print('${uri.queryParameters}');
                    var _result = <String, String>{};
                    _result.addAll(uri.queryParameters);
                    var lat = _result['latng'];
                    //latitude, longitude
                    var list = lat!.split(",");
                    _result['latitude'] = list[0];
                    _result['longitude'] = list[1];
                    _result['url'] = sprintf(mapThumbnailUrl, [lat, lat]);
                    // log('--url:${_result['url']}');
                    latitude = double.tryParse(_result['latitude']!);
                    longitude = double.tryParse(_result['longitude']!);
                    description = jsonEncode(_result);
                  } catch (e) {
                    print('e:$e');
                  }
                  return NavigationActionPolicy.CANCEL;
                }
                return NavigationActionPolicy.ALLOW;
              },
              onLoadStop: (controller, url) async {
                pullToRefreshController.endRefreshing();
                this.url = url.toString();
              },
              onLoadError: (controller, url, code, message) {
                pullToRefreshController.endRefreshing();
              },
              onProgressChanged: (controller, progress) {
                if (progress == 100) {
                  pullToRefreshController.endRefreshing();
                }
                setState(() {
                  this.progress = progress / 100;
                });
              },
              onUpdateVisitedHistory: (controller, url, androidIsReload) {
                this.url = url.toString();
              },
              onConsoleMessage: (controller, consoleMessage) {
                print(consoleMessage);
              },
            ),
            progress < 1.0
                ? LinearProgressIndicator(value: progress)
                : Container(),
          ],
        ),
      ),
    );
  }
}