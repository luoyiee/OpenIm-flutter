import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_openim_sdk/flutter_openim_sdk.dart';
import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';
import 'package:openim_live/openim_live.dart';

import '../im_callback.dart';

class IMController extends GetxController with IMCallback, OpenIMLive {
  late Rx<UserFullInfo> userInfo;
  late String atAllTag;

  @override
  void onClose() {
    super.close();
    super.onClose();
    onCloseLive();
  }

  @override
  void onInit() async {
    super.onInit();
    onInitLive();
    // Initialize SDK
    WidgetsBinding.instance.addPostFrameCallback((_) => initOpenIM());
  }

  bool isLogined() {
    return OpenIM.iMManager.isLogined;
  }

  void initOpenIM() async {
    final initialized = await OpenIM.iMManager.initSDK(
      platformID: IMUtils.getPlatform(),
      apiAddr: Config.imApiUrl,
      wsAddr: Config.imWsUrl,
      dataDir: Config.cachePath,
      logLevel: 6,
      logFilePath: Config.cachePath,
      listener: OnConnectListener(
        onConnecting: () {
          imSdkStatus(IMSdkStatus.connecting);
        },
        onConnectFailed: (code, error) {
          imSdkStatus(IMSdkStatus.connectionFailed);
        },
        onConnectSuccess: () {
          imSdkStatus(IMSdkStatus.connectionSucceeded);
        },
        onKickedOffline: kickedOffline,
        onUserTokenExpired: kickedOffline,
      ),
    );
    // Set listener
    OpenIM.iMManager
      ..userManager.setUserListener(OnUserListener(
        onSelfInfoUpdated: (u) {
          userInfo.update((val) {
            val?.nickname = u.nickname;
            val?.faceURL = u.faceURL;
            val?.remark = u.remark;
            val?.ex = u.ex;
            val?.globalRecvMsgOpt = u.globalRecvMsgOpt;
          });
        },
      ))
      // Add message listener (remove when not in use)
      ..messageManager.setAdvancedMsgListener(OnAdvancedMsgListener(
          onRecvC2CReadReceipt: recvC2CMessageReadReceipt,
          onRecvNewMessage: (msg) {
            bool skip = false;

            if (msg.isCustomType) {
              final data = msg.customElem!.data;
              final map = jsonDecode(data!);
              final customType = map['customType'];
              if (customType == CustomMessageType.callingInvite ||
                  customType == CustomMessageType.callingAccept ||
                  customType == CustomMessageType.callingReject ||
                  customType == CustomMessageType.callingCancel ||
                  customType == CustomMessageType.callingHungup) {
                skip = true;

                final signaling = SignalingInfo(invitation: InvitationInfo.fromJson(map['data']));
                signaling.userID = signaling.invitation?.inviterUserID;

                switch (customType) {
                  case CustomMessageType.callingInvite:
                    receiveNewInvitation(signaling);
                    break;
                  case CustomMessageType.callingAccept:
                    inviteeAccepted(signaling);
                    break;
                  case CustomMessageType.callingReject:
                    inviteeRejected(signaling);
                    break;
                  case CustomMessageType.callingCancel:
                    invitationCancelled(signaling);
                    break;
                  case CustomMessageType.callingHungup:
                    beHangup(signaling);
                    break;
                }
              }
            }

            if (!skip) {
              recvNewMessage(msg);
            }
          },
          onRecvGroupReadReceipt: (v) {},
          onNewRecvMessageRevoked: recvMessageRevoked))

      // Set up message sending progress listener
      ..messageManager.setMsgSendProgressListener(OnMsgSendProgressListener(
        onProgress: progressCallback,
      ))
      ..messageManager.setCustomBusinessListener(OnCustomBusinessListener(
        onRecvCustomBusinessMessage: recvCustomBusinessMessage,
      ))
      // Set up friend relationship listener
      ..friendshipManager.setFriendshipListener(OnFriendshipListener(
        onBlackAdded: blacklistAdded,
        onBlackDeleted: blacklistDeleted,
        onFriendApplicationAccepted: friendApplicationAccepted,
        onFriendApplicationAdded: friendApplicationAdded,
        onFriendApplicationDeleted: friendApplicationDeleted,
        onFriendApplicationRejected: friendApplicationRejected,
        onFriendInfoChanged: friendInfoChanged,
        onFriendAdded: friendAdded,
        onFriendDeleted: friendDeleted,
      ))

      // Set up conversation listener
      ..conversationManager.setConversationListener(OnConversationListener(
        onConversationChanged: conversationChanged,
        onNewConversation: newConversation,
        onTotalUnreadMessageCountChanged: totalUnreadMsgCountChanged,
        onSyncServerFailed: () {
          imSdkStatus(IMSdkStatus.syncFailed);
        },
        onSyncServerFinish: () {
          imSdkStatus(IMSdkStatus.syncEnded);
        },
        onSyncServerStart: () {
          imSdkStatus(IMSdkStatus.syncStart);
        },
      ))
      ..groupManager.setGroupListener(OnGroupListener(
        onGroupApplicationAccepted: groupApplicationAccepted,
        onGroupApplicationAdded: groupApplicationAdded,
        onGroupApplicationDeleted: groupApplicationDeleted,
        onGroupApplicationRejected: groupApplicationRejected,
        onGroupInfoChanged: groupInfoChanged,
        onGroupMemberAdded: groupMemberAdded,
        onGroupMemberDeleted: groupMemberDeleted,
        onGroupMemberInfoChanged: groupMemberInfoChanged,
        onJoinedGroupAdded: joinedGroupAdded,
        onJoinedGroupDeleted: joinedGroupDeleted,
      ));

    initializedSubject.sink.add(initialized);
  }

  Future login(String userID, String token) async {
    try {
      var user = await OpenIM.iMManager.login(
        userID: userID,
        token: token,
        defaultValue: () async => UserInfo(userID: userID),
      );
      userInfo = UserFullInfo.fromJson(user.toJson()).obs;
      _queryMyFullInfo();
      _queryAtAllTag();
    } catch (e, s) {
      LoggerUtil.print('e: $e  s:$s');
      await _handleLoginRepeatError(e);
      return Future.error(e, s);
    }
  }

  Future logout() {
    return OpenIM.iMManager.logout();
  }

  void _queryAtAllTag() async {
    atAllTag = OpenIM.iMManager.conversationManager.atAllTag;
  }

  void _queryMyFullInfo() async {
    final data = await Apis.queryMyFullInfo();
    if (data is UserFullInfo) {
      userInfo.update((val) {
        val?.allowAddFriend = data.allowAddFriend;
        val?.allowBeep = data.allowBeep;
        val?.allowVibration = data.allowVibration;
        val?.nickname = data.nickname;
        val?.faceURL = data.faceURL;
        val?.phoneNumber = data.phoneNumber;
        val?.email = data.email;
        val?.birth = data.birth;
        val?.gender = data.gender;
      });
    }
  }

  _handleLoginRepeatError(e) async {
    if (e is PlatformException && e.code == "13002") {
      await logout();
      await DataSp.removeLoginCertificate();
    }
  }


  // void reBuildSubject() {
  //   close();
  //   recvGroupReadReceiptSubject = BehaviorSubject<GroupMessageReceipt>();
  //
  //   /// 新增会话
  //   conversationAddedSubject = BehaviorSubject<List<ConversationInfo>>();
  //
  //   /// 旧会话更新
  //   conversationChangedSubject = BehaviorSubject<List<ConversationInfo>>();
  //
  //   /// 未读消息数
  //   unreadMsgCountEventSubject = PublishSubject<int>();
  //
  //   /// 好友申请列表变化（包含自己发出的以及收到的）
  //   friendApplicationChangedSubject = BehaviorSubject<FriendApplicationInfo>();
  //
  //   /// 新增好友
  //   friendAddSubject = BehaviorSubject<FriendInfo>();
  //
  //   /// 删除好友
  //   friendDelSubject = BehaviorSubject<FriendInfo>();
  //
  //   /// 好友信息改变
  //   friendInfoChangedSubject = BehaviorSubject<FriendInfo>();
  //
  //   /// 自己信息更新
  //   selfInfoUpdatedSubject = BehaviorSubject<UserInfo>();
  //
  //   /// 用户在线状态更新
  //   userStatusChangedSubject = BehaviorSubject<UserStatusInfo>();
  //
  //   /// 组信息更新
  //   groupInfoUpdatedSubject = BehaviorSubject<GroupInfo>();
  //
  //   /// 组申请列表变化（包含自己发出的以及收到的）
  //   groupApplicationChangedSubject = BehaviorSubject<GroupApplicationInfo>();
  //
  //   initializedSubject = PublishSubject<bool>();
  //
  //   /// 群成员收到：群成员已进入
  //   memberAddedSubject = BehaviorSubject<GroupMembersInfo>();
  //
  //   /// 群成员收到：群成员已退出
  //   memberDeletedSubject = BehaviorSubject<GroupMembersInfo>();
  //
  //   /// 群成员信息变化
  //   memberInfoChangedSubject = PublishSubject<GroupMembersInfo>();
  //
  //   /// 被踢
  //   joinedGroupDeletedSubject = BehaviorSubject<GroupInfo>();
  //
  //   /// 拉人
  //   joinedGroupAddedSubject = BehaviorSubject<GroupInfo>();
  //
  //   onKickedOfflineSubject = PublishSubject();
  //
  //   imSdkStatusSubject = BehaviorSubject<IMSdkStatus>();
  //
  //   roomParticipantDisconnectedSubject = PublishSubject<RoomCallingInfo>();
  //
  //   roomParticipantConnectedSubject = PublishSubject<RoomCallingInfo>();
  //
  //   momentsSubject = PublishSubject<WorkMomentsNotification>();
  //
  //   inviteApplySubject = PublishSubject<Map<String, dynamic>>();
  //
  //   inviteApplyHandleSubject = PublishSubject<Map<String, dynamic>>();
  //
  //   // customBusinessSubject = PublishSubject();
  //
  //   // meetingSteamChangedSubject = PublishSubject<dynamic>();
  // }
}
