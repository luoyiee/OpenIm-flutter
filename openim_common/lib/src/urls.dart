import 'config.dart';

class Urls {
  static final updateUserInfo = "${Config.appAuthUrl}/user/update";
  static final getUsersFullInfo = "${Config.appAuthUrl}/user/find/full";
  static final searchUserFullInfo = "${Config.appAuthUrl}/user/search/full";
  static final searchFriendInfo = "${Config.appAuthUrl}/friend/search";
  static final queryUserInfo = "${Config.appAuthUrl}/user/info";
  static final getVerificationCode = "${Config.appAuthUrl}/account/code/send";
  static final checkVerificationCode = "${Config.appAuthUrl}/account/code/verify";
  static final register = "${Config.appAuthUrl}/account/register";
  static final resetPwd = "${Config.appAuthUrl}/account/password/reset";
  static final changePwd = "${Config.appAuthUrl}/account/password/change";
  static final login = "${Config.appAuthUrl}/account/login";
  static final upgrade = "${Config.appAuthUrl}/app/check";
  static final getTokenForRTC = "${Config.appAuthUrl}/user/rtc/get_token";


  ///拓展
  static var onlineStatus =
      "${Config.imApiUrl}/manager/get_users_online_status";
  static var userOnlineStatus =
      "${Config.imApiUrl}/user/get_users_online_status";

  static String get setTranslateConfig =>
      "${Config.appAuthUrl}/translate/config/set";

  static String get getBots => '${Config.appAuthUrl}/bot/find/public';

  static String get getMyAi => '${Config.appAuthUrl}/bot/find/mine';

  static String get checkServerValid => '/client_config/get';
}
