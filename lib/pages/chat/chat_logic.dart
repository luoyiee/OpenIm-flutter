import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:audio_session/audio_session.dart';
import 'package:collection/collection.dart';
import 'package:common_utils/common_utils.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_openim_sdk/flutter_openim_sdk.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:openim/pages/chat/group_setup/group_member_list/group_member_list_logic.dart';
import 'package:openim_common/openim_common.dart';
import 'package:openim_live/openim_live.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:rxdart/rxdart.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'package:wechat_camera_picker/wechat_camera_picker.dart';

import '../../core/controller/app_controller.dart';
import '../../core/controller/im_controller.dart';
import '../../core/im_callback.dart';
import '../../routes/app_navigator.dart';
import '../contacts/select_contacts/select_contacts_logic.dart';
import '../conversation/conversation_logic.dart';
import 'package:rxdart/rxdart.dart' as rx;

class ChatLogic extends GetxController {
  final imLogic = Get.find<IMController>();
  final appLogic = Get.find<AppController>();
  final conversationLogic = Get.find<ConversationLogic>();
  final cacheLogic = Get.find<CacheController>();
  final downloadLogic = Get.find<DownloadController>();

  final inputCtrl = TextEditingController();
  final focusNode = FocusNode();
  final scrollController = ScrollController();
  final refreshController = RefreshController();

  final forceCloseToolbox = PublishSubject<bool>();
  final forceCloseMenuSub = PublishSubject<bool>();
  final sendStatusSub = PublishSubject<MsgStreamEv<bool>>();
  final sendProgressSub = BehaviorSubject<MsgStreamEv<int>>();
  final downloadProgressSub = PublishSubject<MsgStreamEv<double>>();

  final _playingStateController = StreamController<String>.broadcast();

  Stream<String> get playingStateStream => _playingStateController.stream;

  late ConversationInfo conversationInfo;
  Message? searchMessage;
  final nickname = ''.obs;
  final faceUrl = ''.obs;
  Timer? typingTimer;
  final typing = false.obs;
  final intervalSendTypingMsg = IntervalDo();
  Message? quoteMsg;
  final messageList = <Message>[].obs;
  final quoteContent = "".obs;
  final atUserNameMappingMap = <String, String>{};
  final atUserInfoMappingMap = <String, UserInfo>{};
  final curMsgAtUser = <String>[];
  var _lastCursorIndex = -1;
  final onlineStatus = false.obs;
  final onlineStatusDesc = ''.obs;
  final showEncryptTips = false.obs;
  Timer? onlineStatusTimer;
  final memberUpdateInfoMap = <String, GroupMembersInfo>{};
  final groupMessageReadMembers = <String, List<String>>{};
  final groupMemberRoleLevel = 1.obs;
  GroupInfo? groupInfo;
  GroupMembersInfo? groupMembersInfo;

  final isInGroup = true.obs;
  final memberCount = 0.obs;
  final isInBlacklist = false.obs;
  // final aiUtil = Get.find<AiUtil>();

  final scrollingCacheMessageList = <Message>[];
  late StreamSubscription memberAddSub;
  late StreamSubscription memberDelSub;
  late StreamSubscription joinedGroupAddedSub;
  late StreamSubscription joinedGroupDeletedSub;
  late StreamSubscription memberInfoChangedSub;
  late StreamSubscription groupInfoUpdatedSub;
  late StreamSubscription friendInfoChangedSub;

  late StreamSubscription connectionSub;
  final syncStatus = IMSdkStatus.syncEnded.obs;
  final extraMessageList = <Message>[].obs;
  int? lastMinSeq;

  bool _isReceivedMessageWhenSyncing = false;
  bool _isStartSyncing = false;
  bool _isFirstLoad = false;
  var isShowPopMenu = false.obs;

  String? groupOwnerID;

  String? get userID => conversationInfo.userID;

  String? get groupID => conversationInfo.groupID;

  bool get isSingleChat => null != userID && userID!.trim().isNotEmpty;

  bool get isGroupChat => null != groupID && groupID!.trim().isNotEmpty;

  RTCBridge? rtcBridge = PackageBridge.rtcBridge;

  bool get rtcIsBusy => rtcBridge?.hasConnection == true;

  /// 禁言条件；全员禁言，单独禁言，拉入黑名单
  bool get isMuted => isGroupMuted || isUserMuted || isInBlacklist.value;

  /// 群开启禁言，排除群组跟管理员
  bool get isGroupMuted =>
      groupMutedStatus.value == 3 &&
      groupMemberRoleLevel.value == GroupRoleLevel.member;

  /// 单独被禁言
  bool get isUserMuted =>
      muteEndTime.value * 1000 > DateTime.now().millisecondsSinceEpoch;

  List<Message> get messageListV2 {
    // return [...messageList, ...(disabledChatInput ? extraMessageList : [])];
    return [...messageList];
  }

  // bool get isAiSingleChat => isSingleChat && aiUtil.isAi(userID);


  // bool get disabledChatInput {
  //   // if (!isAiSingleChat || messageList.isEmpty) {
  //   if (messageList.isEmpty) {
  //     return false;
  //   } else {
  //     final lastMsgSendTime = messageList.last.sendTime;
  //     final waitingST =
  //         conversationUtil.getConversationStoreById(conversationID)?.waitingST;
  //     return null != lastMsgSendTime &&
  //         null != waitingST &&
  //         -1 != waitingST &&
  //         lastMsgSendTime <= waitingST &&
  //         // 防止时间误差导致禁用, 可能会导致焚烧后最后一条消息不对导致解除
  //         messageList.last.sendID == OpenIM.iMManager.userID &&
  //         curTime.value < lastMsgSendTime + 60000;
  //   }
  // }

  /// 群禁言状态
  var groupMutedStatus = 0.obs;

  /// 单人被禁言时长
  var muteEndTime = 0.obs;

  var multiSelList = <Message>[].obs;

  final checkedList = <UserInfo>[];
  final defaultCheckedList = <UserInfo>[];
  final allList = <UserInfo>[].obs;

  var multiSelMode = false.obs;

  var privateMessageList = <Message>[];

  /// Click on the message to process voice playback, video playback, picture preview, etc.
  final clickSubject = rx.PublishSubject<int>();

  final _audioPlayer = AudioPlayer();
  var _currentPlayClientMsgID = "".obs;
  var _borderRadius = BorderRadius.only(
    topLeft: Radius.circular(30),
    topRight: Radius.circular(30),
  );

  bool isCurrentChat(Message message) {
    var senderId = message.sendID;
    var receiverId = message.recvID;
    var groupId = message.groupID;
    // var sessionType = message.sessionType;
    var isCurSingleChat = message.isSingleChat &&
        isSingleChat &&
        (senderId == userID ||
            senderId == OpenIM.iMManager.userID && receiverId == userID);
    var isCurGroupChat =
        message.isGroupChat && isGroupChat && groupID == groupId;
    return isCurSingleChat || isCurGroupChat;
  }

  /// 禁言后 清除所有状态
  void _mutedClearAllInput() {
    if (isMuted) {
      inputCtrl.clear();
      setQuoteMsg(null);
      closeMultiSelMode();
    }
  }

  void scrollBottom() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      scrollController.jumpTo(0);
    });
  }

  @override
  void onReady() {
    _checkInBlacklist();
    _isJoinedGroup();
    // getAtMappingMap();
    readDraftText();
    queryUserOnlineStatus();
    _resetGroupAtType();
    super.onReady();
  }

  @override
  void onInit() {
    var arguments = Get.arguments;
    conversationInfo = arguments['conversationInfo'];
    searchMessage = arguments['searchMessage'];
    nickname.value = conversationInfo.showName ?? '';
    faceUrl.value = conversationInfo.faceURL ?? '';

    defaultCheckedList.addAll([]);
    checkedList.addAll([]);
    allList.addAll(defaultCheckedList);
    allList.addAll(checkedList);

    _setSdkSyncDataListener();
    _initChatConfig();
    _initPlayListener();

    imLogic.onRecvNewMessage = (Message message) {
      if (isCurrentChat(message)) {
        if (message.contentType == MessageType.typing) {
          if (message.typingElem?.msgTips == 'yes') {
            if (null == typingTimer) {
              typing.value = true;
              typingTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
                typing.value = false;
                typingTimer?.cancel();
                typingTimer = null;
              });
            }
          } else {
            typing.value = false;
            typingTimer?.cancel();
            typingTimer = null;
          }
        } else {
          if (!messageList.contains(message) &&
              !scrollingCacheMessageList.contains(message)) {
            _isReceivedMessageWhenSyncing = true;
            if (scrollController.offset != 0) {
              scrollingCacheMessageList.add(message);
            } else {
              messageList.add(message);
              scrollBottom();
            }
          }
        }
      }
    };

    imLogic.onRecvMessageRevoked = (RevokedInfo info) {
      var message = messageList
          .firstWhereOrNull((e) => e.clientMsgID == info.clientMsgID);
      message?.notificationElem = NotificationElem(detail: jsonEncode(info));
      message?.contentType = MessageType.revokeMessageNotification;

      if (null != message) {
        messageList.refresh();
      }
    };

    imLogic.onRecvC2CReadReceipt = (List<ReadReceiptInfo> list) {
      try {
        for (var readInfo in list) {
          if (readInfo.userID == userID) {
            for (var e in messageList) {
              if (readInfo.msgIDList?.contains(e.clientMsgID) == true) {
                e.isRead = true;
                e.hasReadTime = _timestamp;
              }
            }
          }
        }
        messageList.refresh();
      } catch (e) {}
    };

    imLogic.onRecvGroupReadReceipt = (List<ReadReceiptInfo> list) {
      try {} catch (e) {}
    };

    imLogic.onMsgSendProgress = (String msgId, int progress) {
      sendProgressSub.addSafely(
        MsgStreamEv<int>(id: msgId, value: progress),
      );
    };

    joinedGroupAddedSub = imLogic.joinedGroupAddedSubject.listen((event) {
      if (event.groupID == groupID) {
        isInGroup.value = true;
        _queryGroupInfo();
      }
    });

    joinedGroupDeletedSub = imLogic.joinedGroupDeletedSubject.listen((event) {
      if (event.groupID == groupID) {
        isInGroup.value = false;
        inputCtrl.clear();
      }
    });

    memberAddSub = imLogic.memberAddedSubject.listen((info) {
      var groupId = info.groupID;
      if (groupId == groupID) {
        _putMemberInfo([info]);
      }
    });

    memberDelSub = imLogic.memberDeletedSubject.listen((info) {
      if (info.groupID == groupID && info.userID == OpenIM.iMManager.userID) {
        isInGroup.value = false;
        inputCtrl.clear();
      }
    });

    memberInfoChangedSub = imLogic.memberInfoChangedSubject.listen((info) {
      if (info.groupID == groupID) {
        if (info.userID == OpenIM.iMManager.userID) {
          groupMemberRoleLevel.value = info.roleLevel ?? GroupRoleLevel.member;
        }
        _putMemberInfo([info]);
      }
    });

    groupInfoUpdatedSub = imLogic.groupInfoUpdatedSubject.listen((value) {
      if (groupID == value.groupID) {
        nickname.value = value.groupName ?? '';
        faceUrl.value = value.faceURL ?? '';
        memberCount.value = value.memberCount ?? 0;
      }
    });

    friendInfoChangedSub = imLogic.friendInfoChangedSubject.listen((value) {
      if (userID == value.userID) {
        nickname.value = value.getShowName();
        faceUrl.value = value.faceURL ?? '';
      }
    });

    inputCtrl.addListener(() {
      intervalSendTypingMsg.run(
        fuc: () => sendTypingMsg(focus: true),
        milliseconds: 2000,
      );
      clearCurAtMap();
      _updateDartText(createDraftText());
    });

    focusNode.addListener(() {
      _lastCursorIndex = inputCtrl.selection.start;
      focusNodeChanged(focusNode.hasFocus);
    });

    // 自定义消息点击事件
    clickSubject.listen((index) {
      print('index:$index');
      parseClickEvent(indexOfMessage(index, calculate: false));
    });

    super.onInit();
  }

  void updatePlayingState(String clientMsgID) {
    _playingStateController.add(clientMsgID);
    print('updatePlayingState:$clientMsgID');
  }

  void chatSetup() => isSingleChat
      ? AppNavigator.startChatSetup(conversationInfo: conversationInfo)
      : AppNavigator.startGroupChatSetup(conversationInfo: conversationInfo);

  void clearCurAtMap() {
    curMsgAtUser.removeWhere((uid) => !inputCtrl.text.contains('@$uid '));
  }

  void _putMemberInfo(List<GroupMembersInfo>? list) {
    list?.forEach((member) {
      _setAtMapping(
        userID: member.userID!,
        nickname: member.nickname!,
        faceURL: member.faceURL,
      );
      memberUpdateInfoMap[member.userID!] = member;
    });

    messageList.refresh();
    atUserNameMappingMap[OpenIM.iMManager.userID] = StrRes.you;
    atUserInfoMappingMap[OpenIM.iMManager.userID] = OpenIM.iMManager.userInfo;
  }

  void sendTextMsg() async {
    var content = IMUtils.safeTrim(inputCtrl.text);
    if (content.isEmpty) return;
    Message message;
    if (curMsgAtUser.isNotEmpty) {
      createAtInfoByID(id) => AtUserInfo(
            atUserID: id,
            groupNickname: atUserNameMappingMap[id],
          );

      message = await OpenIM.iMManager.messageManager.createTextAtMessage(
        text: content,
        atUserIDList: curMsgAtUser,
        atUserInfoList: curMsgAtUser.map(createAtInfoByID).toList(),
        quoteMessage: quoteMsg,
      );
    } else if (quoteMsg != null) {
      message = await OpenIM.iMManager.messageManager.createQuoteMessage(
        text: content,
        quoteMsg: quoteMsg!,
      );
    } else {
      message = await OpenIM.iMManager.messageManager.createTextMessage(
        text: content,
      );
    }
    _sendMessage(message);
  }

  void sendPicture({required String path}) async {
    final file = await IMUtils.compressImageAndGetFile(File(path));

    var message =
        await OpenIM.iMManager.messageManager.createImageMessageFromFullPath(
      imagePath: file!.path,
    );
    _sendMessage(message);
  }

  void sendFile({required String path}) async {
    try {
      var message =
          await OpenIM.iMManager.messageManager.createFileMessageFromFullPath(
        filePath: path,
        fileName: path.split('/').last,
      );
      _sendMessage(message);
    } catch (e) {
      LogUtil.e('Failed to send file: $e');
    }
  }

  ///  发送视频
  void sendVideo({
    required String videoPath,
    required String mimeType,
    required int duration,
    required String thumbnailPath,
  }) async {
    var d = duration > 1000.0 ? duration / 1000.0 : duration;
    var message =
        await OpenIM.iMManager.messageManager.createVideoMessageFromFullPath(
      videoPath: videoPath,
      videoType: mimeType,
      duration: d.toInt(),
      snapshotPath: thumbnailPath,
    );
    _sendMessage(message);
  }

  void sendTypingMsg({bool focus = false}) async {
    if (isSingleChat) {
      OpenIM.iMManager.messageManager.typingStatusUpdate(
        userID: userID!,
        msgTip: focus ? 'yes' : 'no',
      );
    }
  }

  void _sendMessage(
    Message message, {
    String? userId,
    String? groupId,
    bool addToUI = true,
  }) {
    log('send : ${json.encode(message)}');
    userId = IMUtils.emptyStrToNull(userId);
    groupId = IMUtils.emptyStrToNull(groupId);
    if (null == userId && null == groupId ||
        userId == userID && userId != null ||
        groupId == groupID && groupId != null) {
      if (addToUI) {
        messageList.add(message);
        scrollBottom();
      }
    }
    LoggerUtil.print('uid:$userID userId:$userId gid:$groupID groupId:$groupId');
    _reset(message);

    bool useOuterValue = null != userId || null != groupId;
    OpenIM.iMManager.messageManager
        .sendMessage(
          message: message,
          userID: useOuterValue ? userId : userID,
          groupID: useOuterValue ? groupId : groupID,
          offlinePushInfo: Config.offlinePushInfo,
        )
        .then((value) => _sendSucceeded(message, value))
        .catchError((error, _) => _senFailed(message, groupId, error, _))
        .whenComplete(() => _completed());
  }

  void _sendSucceeded(Message oldMsg, Message newMsg) {
    LoggerUtil.print('message send success----');

    oldMsg.update(newMsg);
    sendStatusSub.addSafely(MsgStreamEv<bool>(
      id: oldMsg.clientMsgID!,
      value: true,
    ));
  }

  void _senFailed(Message message, String? groupId, error, stack) async {
    LoggerUtil.print('message send failed e :$error  $stack');
    message.status = MessageStatus.failed;
    sendStatusSub.addSafely(MsgStreamEv<bool>(
      id: message.clientMsgID!,
      value: false,
    ));
    if (error is PlatformException) {
      int code = int.tryParse(error.code) ?? 0;
      if (isSingleChat) {
        int? customType;
        if (code == SDKErrorCode.hasBeenBlocked) {
          customType = CustomMessageType.blockedByFriend;
        } else if (code == SDKErrorCode.notFriend) {
          customType = CustomMessageType.deletedByFriend;
        }
        if (null != customType) {
          final hintMessage = (await OpenIM.iMManager.messageManager
              .createFailedHintMessage(type: customType))
            ..status = 2
            ..isRead = true;
          messageList.add(hintMessage);
          OpenIM.iMManager.messageManager.insertSingleMessageToLocalStorage(
            message: hintMessage,
            receiverID: userID,
            senderID: OpenIM.iMManager.userID,
          );
        }
      } else {
        if ((code == SDKErrorCode.userIsNotInGroup ||
                code == SDKErrorCode.groupDisbanded) &&
            null == groupId) {
          final status = groupInfo?.status;
          final hintMessage = (await OpenIM.iMManager.messageManager
              .createFailedHintMessage(
                  type: status == 2
                      ? CustomMessageType.groupDisbanded
                      : CustomMessageType.removedFromGroup))
            ..status = 2
            ..isRead = true;
          messageList.add(hintMessage);
          OpenIM.iMManager.messageManager.insertGroupMessageToLocalStorage(
            message: hintMessage,
            groupID: groupID,
            senderID: OpenIM.iMManager.userID,
          );
        }
      }
    }
  }

  void _reset(Message message) {
    if (message.contentType == MessageType.text ||
        message.contentType == MessageType.atText ||
        message.contentType == MessageType.quote) {
      inputCtrl.clear();
      setQuoteMsg(null);
    }
    closeMultiSelMode();
  }

  void _completed() {
    messageList.refresh();
  }

  void onTapAlbum() async {
    final List<AssetEntity>? assets = await AssetPicker.pickAssets(
      Get.context!,
    );
    if (null != assets) {
      for (var asset in assets) {
        _handleAssets(asset);
      }
    }
  }

  // void onTapFile() async {
  //   final List<AssetEntity>? assets = await AssetPicker.pickAssets(
  //     Get.context!,
  //     pickerConfig: AssetPickerConfig(
  //       maxAssets: 1,
  //       requestType: RequestType.common,
  //     ),
  //   );
  //   if (assets != null && assets.isNotEmpty) {
  //     for (var asset in assets) {
  //       _handleAssets(asset);
  //     }
  //   }
  // }

  void onTapFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.isNotEmpty) {
      PlatformFile pickedFile = result.files.first;
      File file = File(pickedFile.path!);
      sendFile(path: file.path);
    } else {
      LogUtil.d('No file selected');
    }
  }

  void onTapCamera() async {
    final AssetEntity? entity = await CameraPicker.pickFromCamera(
      Get.context!,
      locale: Get.locale,
      pickerConfig: CameraPickerConfig(
          enableAudio: true,
          enableRecording: true,
          enableScaledPreview: false,
          resolutionPreset: ResolutionPreset.medium,
          maximumRecordingDuration: 60.seconds),
    );
    _handleAssets(entity);
  }

  /// 名片
  void onTapCard() async {
    var result = await AppNavigator.startSelectContacts(
      action: SelAction.carte,
    );
    if (null != result) {
      sendCard(
        uid: result.userID,
        name: result.nickname,
        icon: result.faceURL,
      );
    }
  }

  /// 发送名片
  void sendCard({required String uid, String? name, String? icon}) async {
    var message = await OpenIM.iMManager.messageManager.createCardMessage(
      nickname: name ?? "",
      faceURL: icon,
      userID: uid,
    );
    _sendMessage(message);
  }

  /// 打开地图
  void onTapLocation() async {
    var location = await Get.to(ChatWebViewMap());
    print(location);
    sendLocation(location: location);
  }

  /// 发送位置
  void sendLocation({
    required dynamic location,
  }) async {
    var message = await OpenIM.iMManager.messageManager.createLocationMessage(
      latitude: location['latitude'],
      longitude: location['longitude'],
      description: location['description'],
    );
    _sendMessage(message);
  }

  void _handleAssets(AssetEntity? asset) async {
    if (null != asset) {
      LoggerUtil.print('--------assets type-----${asset.type}');
      var path = (await asset.file)!.path;
      LoggerUtil.print('--------assets path-----$path');
      switch (asset.type) {
        case AssetType.image:
          sendPicture(path: path);
          break;
        case AssetType.video:
          var thumbnailFile = await IMUtils.getVideoThumbnail(File(path));
          LoadingView.singleton.show();
          final file = await IMUtils.compressVideoAndGetFile(File(path));
          LoadingView.singleton.dismiss();

          sendVideo(
            videoPath: file!.path,
            mimeType: asset.mimeType ?? IMUtils.getMediaType(path) ?? '',
            duration: asset.duration,
            thumbnailPath: thumbnailFile.path,
          );

          break;
        default:
          break;
      }
    }
  }

  // void parseClickEvent(Message msg) async {
  //   log('parseClickEvent:${jsonEncode(msg)}');
  //   if (msg.contentType == MessageType.custom) {
  //     var data = msg.customElem!.data;
  //     var map = json.decode(data!);
  //     var customType = map['customType'];
  //     if (CustomMessageType.call == customType && !isInBlacklist.value) {
  //     } else if (CustomMessageType.meeting == customType) {}
  //     return;
  //   }
  //   if (msg.contentType == MessageType.voice) {
  //     return;
  //   }
  //   IMUtils.parseClickEvent(
  //     msg,
  //     messageList: messageList,
  //     onViewUserInfo: viewUserInfo,
  //   );
  // }

  void parseClickEvent(Message msg) async {
    log('parseClickEvent:${jsonEncode(msg)}');
    if (msg.contentType == MessageType.custom) {
      var data = msg.customElem?.data;
      var map = json.decode(data!);
      var customType = map['customType'];
      if (CustomMessageType.call == customType && !isInBlacklist.value) {
      } else if (CustomMessageType.meeting == customType) {}
      return;
    }
    // if (msg.contentType == MessageType.voice && msg.soundElem!.sourceUrl!=null) {
    //   var dir =await getApplicationDocumentsDirectory();
    //   var descPath = "${dir.path}/cache/sound/${msg.clientMsgID}.amr";
    //   var file = File(descPath);
    //   if (!file.existsSync()){
    //     file.createSync(recursive: true);
    //     await Dio().download(msg.soundElem!.sourceUrl!, descPath);
    //   }
    //   playSound(descPath);
    //   return;
    else if (msg.contentType == MessageType.voice) {
      _playVoiceMessage(msg);
      // 收听则为已读
      // if (isSingleChat) {
      _markC2CMessageAsRead(msg);
      // } else {
      //   // _markGroupMessageAsRead(msg);
      // }
      return;
    } else if (msg.contentType == MessageType.picture) {
      // onTapPicture(msg);
      var list = messageList
          .where((p0) => p0.contentType == MessageType.picture)
          .toList();
      var index = list.indexOf(msg);
      if (index == -1) {
        IMUtils.openPicture([msg], index: 0, tag: msg.clientMsgID);
      } else {
        IMUtils.openPicture(list, index: index, tag: msg.clientMsgID);
      }
      return;
    } else if (msg.contentType == MessageType.video) {
      IMUtils.openVideo(msg);
    } else if (msg.contentType == MessageType.file) {
      IMUtils.openFile(msg);
      return;
    } else if (msg.contentType == MessageType.card) {
      var data = msg.cardElem;
      AppNavigator.startFriendInfo(
          userInfo: UserFullInfo(
              userID: data?.userID ?? "",
              nickname: data?.nickname,
              faceURL: data?.faceURL,
              // isFriendship:
              ex: data?.ex));

      //   var info = ContactsInfo.fromJson(json.decode(msg.content!));
      //   AppNavigator.startFriendInfo(userInfo: info);
    } else if (msg.contentType == MessageType.merger) {
      Get.to(
        () => PreviewMergeMsg(
          title: msg.mergeElem!.title!,
          messageList: msg.mergeElem!.multiMessage!,
        ),
        preventDuplicates: false,
      );
    } else if (msg.contentType == MessageType.location) {
      var location = msg.locationElem;
      Map detail = json.decode(location!.description!);
      Get.to(() => MapView(
            latitude: location.latitude!,
            longitude: location.longitude!,
            address1: detail['name'],
            address2: detail['addr'],
          ));
    }

    IMUtils.parseClickEvent(
      msg,
      messageList: messageList,
      onViewUserInfo: viewUserInfo,
    );
  }

  var _mPlayerIsInited = false;
  FlutterSoundPlayer? _mPlayer = FlutterSoundPlayer();

  playSound(String path) async {
    log("playSoundplaySoundplaySound:${path}");
    await _mPlayer!.startPlayer(
      fromURI: path,
      codec: Codec.amrNB,
      whenFinished: () {
        print("Voice message play finished");
      },
    );
  }

  /// 点击引用消息
  void onTapQuoteMsg(Message message) {
    if (message.contentType == MessageType.quote) {
      parseClickEvent(message.quoteElem!.quoteMessage!);
    } else if (message.contentType == MessageType.atText) {
      parseClickEvent(message.atTextElem!.quoteMessage!);
    }
  }

  void onLongPressLeftAvatar(Message message) {}

  void onTapLeftAvatar(Message message) {
    viewUserInfo(UserInfo()
      ..userID = message.sendID
      ..nickname = message.senderNickname
      ..faceURL = message.senderFaceUrl);
  }

  void onTapRightAvatar() {
    viewUserInfo(OpenIM.iMManager.userInfo);
  }

  void clickAtText(id) async {
    var tag = await OpenIM.iMManager.conversationManager.getAtAllTag();
    if (id == tag) return;
    if (null != atUserInfoMappingMap[id]) {
      viewUserInfo(atUserInfoMappingMap[id]!);
      // AppNavigator.startFriendInfo(
      //   userInfo: atUserInfoMappingMap[id]!,
      //   showMuteFunction: havePermissionMute,
      //   groupID: gid!,
      // );
    } else {
      viewUserInfo(UserInfo(userID: id));
    }
  }

  void viewUserInfo(UserInfo userInfo) {
    AppNavigator.startUserProfilePane(
      userID: userInfo.userID ?? "",
      nickname: userInfo.nickname,
      faceURL: userInfo.faceURL,
      groupID: groupID,
      offAllWhenDelFriend: isSingleChat,
    );
  }

  void clickLinkText(url, type) async {
    print('--------link  type:$type-------url: $url---');
    if (type == PatternType.at) {
      clickAtText(url);
      return;
    }
    if (await canLaunch(url)) {
      await launch(url);
    }
    // await canLaunch(url) ? await launch(url) : throw 'Could not launch $url';
  }

  // String createDraftText() {
  //   return json.encode({});
  // }

  /// 读取草稿
  void readDraftText() {
    var draftText = Get.arguments['draftText'];
    print('readDraftText:$draftText');
    if (null != draftText && "" != draftText) {
      var map = json.decode(draftText!);
      String text = map['text'];
      // String? quoteMsgId = map['quoteMsgId'];
      Map<String, dynamic> atMap = map['at'];
      print('text:$text  atMap:$atMap');
      atMap.forEach((key, value) {
        if (!curMsgAtUser.contains(key)) curMsgAtUser.add(key);
        atUserNameMappingMap.putIfAbsent(key, () => value);
      });
      inputCtrl.text = text;
      inputCtrl.selection = TextSelection.fromPosition(TextPosition(
        offset: text.length,
      ));
      // if (null != quoteMsgId) {
      //   var index = messageList.indexOf(Message()..clientMsgID = quoteMsgId);
      //   print('quoteMsgId index:$index  length:${messageList.length}');
      //   setQuoteMsg(index);
      //   print('quoteMsgId index:$index  length:${messageList.length}');
      // }
      if (text.isNotEmpty) {
        focusNode.requestFocus();
      }
    }
  }

  /// 生成草稿draftText
  String createDraftText() {
    var atMap = <String, dynamic>{};
    curMsgAtUser.forEach((uid) {
      atMap[uid] = atUserNameMappingMap[uid];
    });
    if (inputCtrl.text.isEmpty) {
      return "";
    }
    return json.encode({
      'text': inputCtrl.text,
      'at': atMap,
      // 'quoteMsgId': quoteMsg?.clientMsgID,
    });
  }



  exit() async {
    // Get.back(result: createDraftText());
    if (multiSelMode.value) {
      closeMultiSelMode();
      return false;
    }
    if (isShowPopMenu.value) {
      forceCloseMenuSub.add(true);
      return false;
    }
    Get.back(result: createDraftText());
    return true;
  }

  void _updateDartText(String text) {
    conversationLogic.updateDartText(
      text: text,
      conversationID: conversationInfo.conversationID,
    );
  }

  void focusNodeChanged(bool hasFocus) {
    sendTypingMsg(focus: hasFocus);
    if (hasFocus) {
      LoggerUtil.print('focus:$hasFocus');
      scrollBottom();
    }
  }

  void copy(Message message) {
    IMUtils.copy(text: message.textElem!.content!);
  }

  void playSpeaker(Message message) {
    _playVoiceMessage(message, useSpeaker: true);
  }

  void speaker2Speed(Message message) {
    _playVoiceMessage(message, speed: 2.0);
  }

  Message indexOfMessage(int index, {bool calculate = true}) =>
      IMUtils.calChatTimeInterval(
        messageList,
        calculate: calculate,
      ).reversed.elementAt(index);

  ValueKey itemKey(Message message) => ValueKey(message.clientMsgID!);

  @override
  void onClose() {
    _audioPlayer.dispose();
    inputCtrl.dispose();
    focusNode.dispose();
    _playingStateController.close();
    forceCloseToolbox.close();
    sendStatusSub.close();
    sendProgressSub.close();
    downloadProgressSub.close();
    memberAddSub.cancel();
    memberDelSub.cancel();
    memberInfoChangedSub.cancel();
    groupInfoUpdatedSub.cancel();
    friendInfoChangedSub.cancel();

    forceCloseMenuSub.close();
    joinedGroupAddedSub.cancel();
    joinedGroupDeletedSub.cancel();
    connectionSub.cancel();

    super.onClose();
  }

  String? getShowTime(Message message) {
    if (message.exMap['showTime'] == true) {
      return IMUtils.getChatTimeline(message.sendTime!);
    }
    return null;
  }

  void clearAllMessage() {
    messageList.clear();
  }

  String? get subTile => typing.value ? StrRes.typing : null;

  String get title => isSingleChat
      ? nickname.value
      : (memberCount.value > 0
          ? '${nickname.value}(${memberCount.value})'
          : nickname.value);

  void failedResend(Message message) {
    sendStatusSub.addSafely(MsgStreamEv<bool>(
      id: message.clientMsgID!,
      value: true,
    ));
    _sendMessage(message..status = MessageStatus.sending, addToUI: false);
  }

  static int get _timestamp => DateTime.now().millisecondsSinceEpoch;

  void _queryMyGroupMemberInfo() async {
    if (isGroupChat) {
      var list = await OpenIM.iMManager.groupManager.getGroupMembersInfo(
        groupID: groupID!,
        userIDList: [OpenIM.iMManager.userID],
      );
      groupMembersInfo = list.firstOrNull;
      groupMemberRoleLevel.value =
          groupMembersInfo?.roleLevel ?? GroupRoleLevel.member;
      if (null != groupMembersInfo) {
        memberUpdateInfoMap[OpenIM.iMManager.userID] = groupMembersInfo!;
      }
    }
  }

  void _isJoinedGroup() async {
    if (isGroupChat) {
      isInGroup.value = await OpenIM.iMManager.groupManager.isJoinedGroup(
        groupID: groupID!,
      );
      if (isInGroup.value) _queryGroupInfo();
    }
  }

  void _queryGroupInfo() async {
    if (isGroupChat) {
      var list = await OpenIM.iMManager.groupManager.getGroupsInfo(
        groupIDList: [groupID!],
      );
      groupInfo = list.firstOrNull;
      groupOwnerID = groupInfo?.ownerUserID;
      memberCount.value = groupInfo?.memberCount ?? 0;
      _queryMyGroupMemberInfo();
    }
  }

  bool get havePermissionMute =>
      isGroupChat && (groupInfo?.ownerUserID == OpenIM.iMManager.userID);

  bool isNotificationType(Message message) => message.contentType! >= 1000;

  Map<String, String> getAtMapping(Message message) {
    return {};
  }

  void lockMessageLocation(Message message) {}

  void _checkInBlacklist() async {
    if (userID != null) {
      var list = await OpenIM.iMManager.friendshipManager.getBlacklist();
      var user = list.firstWhereOrNull((e) => e.userID == userID);
      isInBlacklist.value = user != null;
    }
  }

  void _setAtMapping({
    required String userID,
    required String nickname,
    String? faceURL,
  }) {
    atUserNameMappingMap[userID] = nickname;
    atUserInfoMappingMap[userID] = UserInfo(
      userID: userID,
      nickname: nickname,
      faceURL: faceURL,
    );
  }

  bool isExceed24H(Message message) {
    int milliseconds = message.sendTime!;
    return !DateUtil.isToday(milliseconds);
  }

  String? getNewestNickname(Message message) {
    if (isSingleChat) null;
    return memberUpdateInfoMap[message.sendID]?.nickname;
  }

  String? getNewestFaceURL(Message message) {
    if (isSingleChat) return faceUrl.value;
    return memberUpdateInfoMap[message.sendID]?.faceURL;
  }

  bool get isInvalidGroup => !isInGroup.value && isGroupChat;

  bool isNoticeMessage(Message message) => message.contentType! > 1000;

  void joinGroupCalling() async {}

  void call() {
    if (rtcIsBusy) {
      IMViews.showToast(StrRes.callingBusy);
      return;
    }

    IMViews.openIMCallSheet(nickname.value, (index) {
      imLogic.call(
        callObj: CallObj.single,
        callType: index == 0 ? CallType.audio : CallType.video,
        inviteeUserIDList: [if (isSingleChat) userID!],
      );
    });
  }

  void onScrollToTop() {
    if (scrollingCacheMessageList.isNotEmpty) {
      messageList.addAll(scrollingCacheMessageList);
      scrollingCacheMessageList.clear();
    }
  }

  String get markText {
    String? phoneNumber = imLogic.userInfo.value.phoneNumber;
    if (phoneNumber != null) {
      int start = phoneNumber.length > 4 ? phoneNumber.length - 4 : 0;
      final sub = phoneNumber.substring(start);
      return "${OpenIM.iMManager.userInfo.nickname!}$sub";
    }
    return OpenIM.iMManager.userInfo.nickname ?? '';
  }

  bool isFailedHintMessage(Message message) {
    if (message.contentType == MessageType.custom) {
      var data = message.customElem!.data;
      var map = json.decode(data!);
      var customType = map['customType'];
      return customType == CustomMessageType.deletedByFriend ||
          customType == CustomMessageType.blockedByFriend;
    }
    return false;
  }

  void sendFriendVerification() =>
      AppNavigator.startSendVerificationApplication(userID: userID);

  void _setSdkSyncDataListener() {
    connectionSub = imLogic.imSdkStatusSubject.listen((value) {
      syncStatus.value = value;

      if (value == IMSdkStatus.syncStart) {
        _isStartSyncing = true;
      } else if (value == IMSdkStatus.syncEnded) {
        if (_isStartSyncing) {
          _isReceivedMessageWhenSyncing = false;
          _isStartSyncing = false;
          _isFirstLoad = true;
          onScrollToBottomLoad();
        }
      } else if (value == IMSdkStatus.syncFailed) {
        _isReceivedMessageWhenSyncing = false;
        _isStartSyncing = false;
      }
    });
  }

  bool get isSyncFailed => syncStatus.value == IMSdkStatus.syncFailed;

  String? get syncStatusStr {
    switch (syncStatus.value) {
      case IMSdkStatus.syncStart:
      case IMSdkStatus.synchronizing:
        return StrRes.synchronizing;
      case IMSdkStatus.syncFailed:
        return StrRes.syncFailed;
      default:
        return null;
    }
  }

  bool showBubbleBg(Message message) {
    return !isNotificationType(message) && !isFailedHintMessage(message);
  }

  Future<AdvancedMessage> _requestHistoryMessage() =>
      OpenIM.iMManager.messageManager.getAdvancedHistoryMessageList(
        conversationID: conversationInfo.conversationID,
        count: 20,
        startMsg: _isFirstLoad ? null : messageList.firstOrNull,
        lastMinSeq: _isFirstLoad ? null : lastMinSeq,
      );

  Future<bool> onScrollToBottomLoad() async {
    late List<Message> list;
    final result = await _requestHistoryMessage();
    if (result.messageList == null || result.messageList!.isEmpty) return false;
    list = result.messageList!;
    lastMinSeq = result.lastMinSeq;
    if (_isFirstLoad) {
      _isFirstLoad = false;
      messageList.assignAll(list);
      scrollBottom();
    } else {
      removeCallingCustomMessage(list);

      if (list.isNotEmpty && list.length < 20) {
        final result = await _requestHistoryMessage();
        if (result.messageList?.isNotEmpty == true) {
          list = result.messageList!;
          lastMinSeq = result.lastMinSeq;
        }
        removeCallingCustomMessage(list);
      }
      messageList.insertAll(0, list);
    }
    return list.length >= 20;
  }

  void removeCallingCustomMessage(List<Message> list) {
    list.removeWhere((element) {
      if (element.isCustomType) {
        if (element.customElem?.data != null) {
          var map = json.decode(element.customElem!.data!);
          var customType = map['customType'];

          final result = customType == CustomMessageType.callingInvite ||
              customType == CustomMessageType.callingAccept ||
              customType == CustomMessageType.callingReject ||
              customType == CustomMessageType.callingHungup ||
              customType == CustomMessageType.callingCancel;

          return result;
        }
      }

      return false;
    });
  }

  /// 是否显示撤回消息菜单
  bool showRevokeMenu(Message message) {
    if (isNoticeMessage(message) ||
        isCallMessage(message) ||
        isExceed24H(message) && isSingleChat) {
      return false;
    }
    if (isGroupChat) {
      return true;
    }
    return message.sendID == OpenIM.iMManager.userID;
  }

  /// 添加表情菜单
  bool showAddEmojiMenu(Message message) {
    if (isPrivateChat(message)) {
      return false;
    }
    return message.contentType == MessageType.picture ||
        message.contentType == MessageType.customFace;
  }

  /// 复制菜单
  bool showCopyMenu(Message message) {
    return message.contentType == MessageType.text;
  }

  bool showSpeakerMenu(Message message) {
    return message.contentType == MessageType.voice;
  }

  bool showSpeaker2SpeedMenu(Message message) {
    return message.contentType == MessageType.voice;
  }

  /// 删除菜单
  bool showDelMenu(Message message) {
    if (isPrivateChat(message)) {
      return false;
    }
    return true;
  }

  /// 转发菜单
  bool showForwardMenu(Message message) {
    if (isNoticeMessage(message) ||
        isPrivateChat(message) ||
        isCallMessage(message) ||
        message.contentType == MessageType.voice) {
      return false;
    }
    return true;
  }

  /// 多选菜单
  bool showMultiMenu(Message message) {
    if (isNoticeMessage(message) ||
        isPrivateChat(message) ||
        isCallMessage(message)) {
      return false;
    }
    return true;
  }

  /// 回复菜单
  bool showReplyMenu(Message message) {
    // if (isNoticeMessage(message) ||
    //     isPrivateChat(message) ||
    //     isCallMessage(message)) {
    //   return false;
    // }
    return message.contentType == MessageType.text ||
        message.contentType == MessageType.video ||
        message.contentType == MessageType.picture ||
        message.contentType == MessageType.location ||
        message.contentType == MessageType.quote;
  }

  /// 是否是阅后即焚消息
  bool isPrivateChat(Message message) {
    return message.attachedInfoElem?.isPrivateChat ?? false;
  }

  bool isCallMessage(Message message) {
    switch (message.contentType) {
      case MessageType.custom:
        {
          var data = message.customElem!.data;
          var map = json.decode(data!);
          var customType = map['customType'];
          switch (customType) {
            case CustomMessageType.call:
              return true;
          }
        }
    }
    return false;
  }

  bool showCheckbox(Message message) {
    if (isNoticeMessage(message) ||
        isPrivateChat(message) ||
        isCallMessage(message)) {
      return false;
    }
    return multiSelMode.value;
  }

  /// 语音视频通话信息不显示读状态
  bool enabledReadStatus(Message message) {
    try {
      // 通知类消息不显示
      if (message.contentType! > 1000 || message.contentType == 118) {
        return false;
      }
      switch (message.contentType) {
        case MessageType.custom:
          {
            var data = message.customElem!.data;
            var map = json.decode(data!);
            switch (map['customType']) {
              case CustomMessageType.call:
                return false;
            }
          }
      }
    } catch (e) {}
    return true;
  }

  int readTime(Message message) {
    var isPrivate = message.attachedInfoElem?.isPrivateChat ?? false;
    var burnDuration = message.attachedInfoElem?.burnDuration ?? 30;
    if (isPrivate) {
      privateMessageList.addIf(
          () => !privateMessageList.contains(message), message);
      // var hasReadTime = message.attachedInfoElem!.hasReadTime ?? 0;
      var hasReadTime = message.hasReadTime ?? 0;
      if (hasReadTime > 0) {
        var end = hasReadTime + (burnDuration * 1000);

        var diff = (end - _timestamp) ~/ 1000;
        return diff < 0 ? 0 : diff;
      }
    }
    return 0;
  }

  /// 删除消息
  void deleteMsg(Message message) async {
    _deleteMessage(message);
  }

  /// 批量删除
  void _deleteMultiMsg() {
    multiSelList.forEach((e) {
      _deleteMessage(e);
    });
    closeMultiSelMode();
  }

  _deleteMessage(Message message) async {
    try {
      await OpenIM.iMManager.messageManager
          .deleteMessageFromLocalAndSvr(
              conversationID: conversationInfo.conversationID,
              clientMsgID: message.clientMsgID ?? "")
          .then((value) => privateMessageList.remove(message))
          .then((value) => messageList.remove(message));
    } catch (e) {
      await OpenIM.iMManager.messageManager
          .deleteMessageFromLocalStorage(
            conversationID: conversationInfo.conversationID,
            clientMsgID: message.clientMsgID ?? "",
          )
          .then((value) => privateMessageList.remove(message))
          .then((value) => messageList.remove(message));
    }
  }

  // void deleteMessageFromLocal(Message message) async {
  //   await OpenIM.iMManager.messageManager.deleteMessageFromLocalStorage(
  //     conversationID: conversationInfo.conversationID,
  //     clientMsgID: message.clientMsgID!,
  //   );
  //   messageList.remove(message);
  //   messageList.refresh();
  //   IMViews.showToast("删除成功");
  // }



  /// 群消息已读预览
  void viewGroupMessageReadStatus(Message message) {
    AppNavigator.startGroupHaveReadList(
      message: message,
    );
  }

  void multiSelMsg(Message message, bool checked) {
    if (checked) {
      // 合并最多五条限制
      if (multiSelList.length >= 20) {
        Get.dialog(CustomDialog(
          title: '当前仅支持转发最多二十条消息~',
        ));
      } else {
        multiSelList.add(message);
        multiSelList.sort((a, b) {
          if (a.createTime! > b.createTime!) {
            return 1;
          } else if (a.createTime! < b.createTime!) {
            return -1;
          } else {
            return 0;
          }
        });
      }
    } else {
      multiSelList.remove(message);
    }
  }

  void openMultiSelMode(Message message) {
    multiSelMode.value = true;
    multiSelMsg(message, true);
  }

  void closeMultiSelMode() {
    multiSelMode.value = false;
    multiSelList.clear();
  }

  // void forward(Message message) async {
  //   var result = await AppNavigator.startSelectContacts(
  //     action: SelAction.forward,
  //   );
  //   if (null != result) {
  //     sendForwardMsg(
  //       message,
  //       userId: result['userID'],
  //       groupId: result['groupID'],
  //     );
  //   }
  // }

  /// 转发
  void forward(Message message) async {
    final result = await AppNavigator.startSelectContacts(
      action: SelAction.forward,
      checkedList: checkedList,
      defaultCheckedIDList: defaultCheckedList.map((e) => e.userID!).toList(),
    );

    final listRes = result["checkedList"];

    for (ConversationInfo recipient in listRes) {
      // 获取原始消息
      // 转发消息
      var createNewForwordmsg = await OpenIM.iMManager.messageManager
          .createForwardMessage(message: message);
      _sendMessage(createNewForwordmsg,
          userId: recipient.userID, groupId: recipient.groupID);
    }
  }

  void onTapPicture(Message message) {
    print("123123message");
    print(message.pictureElem?.bigPicture?.url ?? "");
    AppNavigator.startCheckHighImage(
        imageUrl: message.pictureElem?.bigPicture?.url.toString() ?? "");
  }

  /// 转发
  void sendForwardMsg(
    Message originalMessage, {
    String? userId,
    String? groupId,
  }) async {
    var message = await OpenIM.iMManager.messageManager.createForwardMessage(
      message: originalMessage,
    );
    _sendMessage(message, userId: userId, groupId: groupId);
  }

  /// 设置被回复的消息体
  void setQuoteMsg(Message? message) {
    if (message == null) {
      quoteMsg = null;
      quoteContent.value = '';
    } else {
      quoteMsg = message;
      var name = quoteMsg!.senderNickname;
      quoteContent.value = "$name：${IMUtils.parseMsg(quoteMsg!)}";
      focusNode.requestFocus();
    }
  }

  void revokeMessage(Message message) async {
    await OpenIM.iMManager.messageManager.revokeMessage(
      conversationID: conversationInfo.conversationID,
      clientMsgID: message.clientMsgID!,
    );
    // IMViews.showToast("已撤销");
  }

  // /// 消息撤回（新版本）
  // void revokeMsgV2(Message message) async {
  //   late bool canRevoke;
  //   if (isGroupChat) {
  //     // 撤回自己的消息
  //     if (message.sendID == OpenIM.iMManager.userID) {
  //       canRevoke = true;
  //     } else {
  //       // 群组或管理员撤回群成员的消息
  //       var list = await LoadingView.singleton.wrap(
  //           asyncFunction: () =>
  //               OpenIM.iMManager.groupManager.getGroupOwnerAndAdmin(
  //                 groupID: message.groupID!,
  //               ));
  //       var sender = list.firstWhereOrNull((e) => e.userID == message.sendID);
  //       var revoker =
  //           list.firstWhereOrNull((e) => e.userID == OpenIM.iMManager.userID);
  //
  //       if (revoker != null && sender == null) {
  //         // 撤回者是管理员或群主 可以撤回
  //         canRevoke = true;
  //       } else if (revoker == null && sender != null) {
  //         // 撤回者是普通成员，但发送者是管理员或群主 不可撤回
  //         canRevoke = false;
  //       } else if (revoker != null && sender != null) {
  //         if (revoker.roleLevel == sender.roleLevel) {
  //           // 同级别 不可撤回
  //           canRevoke = false;
  //         } else if (revoker.roleLevel == GroupRoleLevel.owner) {
  //           // 撤回者是群主  可撤回
  //           canRevoke = true;
  //         } else {
  //           // 不可撤回
  //           canRevoke = false;
  //         }
  //       } else {
  //         // 都是成员 不可撤回
  //         canRevoke = false;
  //       }
  //     }
  //   } else {
  //     // 撤回自己的消息
  //     if (message.sendID == OpenIM.iMManager.userID) {
  //       canRevoke = true;
  //     }
  //   }
  //   if (canRevoke) {
  //     await OpenIM.iMManager.messageManager.revokeMessage(
  //         clientMsgID: message.clientMsgID ?? "",
  //         conversationID: conversationInfo.conversationID);
  //     // message.contentType = MessageType.advancedRevoke;
  //     message.contentType = 118;
  //     message.content = jsonEncode(_buildRevokeInfo(message));
  //     messageList.refresh();
  //   } else {
  //     IMViews.showToast('你没有撤回消息的权限!');
  //   }
  // }

  RevokedInfo _buildRevokeInfo(Message message) {
    return RevokedInfo.fromJson({
      'revokerID': OpenIM.iMManager.userID,
      'revokerRole': 0,
      'revokerNickname': OpenIM.iMManager.userInfo.nickname,
      'clientMsgID': message.clientMsgID,
      'revokeTime': 0,
      'sourceMessageSendTime': 0,
      'sourceMessageSendID': message.sendID,
      'sourceMessageSenderNickname': message.senderNickname,
      'sessionType': message.sessionType,
    });
  }

  void addEmoji(Message message) {
    if (message.contentType == MessageType.picture) {
      var url = message.pictureElem?.sourcePicture?.url;
      var width = message.pictureElem?.sourcePicture?.width;
      var height = message.pictureElem?.sourcePicture?.height;
      cacheLogic.addFavoriteFromUrl(url, width, height);
      IMViews.showToast(StrRes.addSuccessfully);
    } else if (message.contentType == MessageType.customFace) {
      var index = message.faceElem?.index;
      var data = message.faceElem?.data;
      if (-1 != index) {
      } else if (null != data) {
        var map = json.decode(data);
        var url = map['url'];
        var width = map['width'];
        var height = map['height'];
        cacheLogic.addFavoriteFromUrl(url, width, height);
        IMViews.showToast(StrRes.addSuccessfully);
      }
    }
  }

  bool isPlaySound(Message message) {
    return _currentPlayClientMsgID.value == message.clientMsgID!;
  }

  void _initPlayListener() {
    _audioPlayer.playerStateStream.listen((state) {
      switch (state.processingState) {
        case ProcessingState.idle:
        case ProcessingState.loading:
        case ProcessingState.buffering:
        case ProcessingState.ready:
          break;
        case ProcessingState.completed:
          _currentPlayClientMsgID.value = "";
          updatePlayingState("");
          break;
      }
    });
  }

  Future<void> _configureAudioSessionForSpeaker() async {
    final session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
      avAudioSessionCategoryOptions:
          AVAudioSessionCategoryOptions.defaultToSpeaker,
      androidAudioAttributes: const AndroidAudioAttributes(
        contentType: AndroidAudioContentType.speech,
        usage: AndroidAudioUsage.voiceCommunication,
      ),
    ));
  }

  /// 播放语音消息
  void _playVoiceMessage(Message message,
      {bool useSpeaker = false, double speed = 1.0}) async {
    if (useSpeaker) {
      await _configureAudioSessionForSpeaker();
    } else {
      // 如果不使用扬声器，可以配置默认的音频会话
      final session = await AudioSession.instance;
      await session.configure(AudioSessionConfiguration.speech());
    }

    var isClickSame = _currentPlayClientMsgID.value == message.clientMsgID;
    if (_audioPlayer.playerState.playing) {
      _currentPlayClientMsgID.value = "";
      _audioPlayer.stop();
      updatePlayingState("");
    }
    if (!isClickSame) {
      bool isValid = await _initVoiceSource(message);
      if (isValid) {
        _audioPlayer.setSpeed(speed);
        _audioPlayer.seek(Duration.zero);
        _audioPlayer.play();
        _currentPlayClientMsgID.value = message.clientMsgID!;
        updatePlayingState(message.clientMsgID!);
      }
    }
  }

  /// 语音消息资源处理
  Future<bool> _initVoiceSource(Message message) async {
    bool isReceived = message.sendID != OpenIM.iMManager.userID;
    String? path = message.soundElem?.soundPath;
    String? url = message.soundElem?.sourceUrl;
    bool isExistSource = false;
    if (isReceived) {
      if (null != url && url.trim().isNotEmpty) {
        isExistSource = true;
        _audioPlayer.setUrl(url);
      }
    } else {
      var _existFile = false;
      if (path != null && path.trim().isNotEmpty) {
        var file = File(path);
        _existFile = await file.exists();
      }
      if (_existFile) {
        isExistSource = true;
        _audioPlayer.setFilePath(path!);
      } else if (null != url && url.trim().isNotEmpty) {
        isExistSource = true;
        _audioPlayer.setUrl(url);
      }
    }
    return isExistSource;
  }

  /// 标记消息为已读
  _markC2CMessageAsRead(Message message) async {
    if (!message.isRead! && message.sendID != OpenIM.iMManager.userID) {
      print('mark as read：${message.clientMsgID!} ${message.isRead}');
      // 多端同步问题
      try {
        await OpenIM.iMManager.messageManager.markMessagesAsReadByMsgID(
          conversationID: conversationInfo.conversationID,
          // userID: uid!,
          messageIDList: [message.clientMsgID!],
        );
      } catch (_) {}
      message.isRead = true;
      message.hasReadTime = _timestamp;
      messageList.refresh();
      // message.attachedInfoElem!.hasReadTime = _timestamp;
    }
  }

  /// 标记消息为已读
// _markGroupMessageAsRead(Message message) async {
//   if (!message.isRead! && message.sendID != OpenIM.iMManager.userID) {
//     print('mark as read：${message.clientMsgID!} ${message.isRead}');
//     // 多端同步问题
//     try {
//       await OpenIM.iMManager.messageManager.markMessagesAsReadByMsgID(
//         groupID: gid!,
//         messageIDList: [message.clientMsgID!],
//       );
//     } catch (_) {}
//     message.isRead = true;
//     message.hasReadTime = _timestamp;
//     messageList.refresh();
//     // message.attachedInfoElem!.hasReadTime = _timestamp;
//   }
// }

  void emojiManage() {
    // AppNavigator.startEmojiManage();
  }

  /// 添加表情
  void onAddEmoji(String emoji) {
    var input = inputCtrl.text;
    if (_lastCursorIndex != -1 && input.isNotEmpty) {
      var part1 = input.substring(0, _lastCursorIndex);
      var part2 = input.substring(_lastCursorIndex);
      inputCtrl.text = '$part1$emoji$part2';
      _lastCursorIndex = _lastCursorIndex + emoji.length;
    } else {
      inputCtrl.text = '$input$emoji';
      _lastCursorIndex = emoji.length;
    }
    inputCtrl.selection = TextSelection.fromPosition(TextPosition(
      offset: _lastCursorIndex,
    ));
  }

  /// 删除表情
  void onDeleteEmoji() {
    final input = inputCtrl.text;
    final regexEmoji = emojiFaces.keys
        .toList()
        .join('|')
        .replaceAll('[', '\\[')
        .replaceAll(']', '\\]');
    final list = [regexAt, regexEmoji];
    final pattern = '(${list.toList().join('|')})';
    final atReg = RegExp(regexAt);
    final emojiReg = RegExp(regexEmoji);
    var reg = RegExp(pattern);
    var cursor = _lastCursorIndex;
    if (cursor == 0) return;
    Match? match;
    if (reg.hasMatch(input)) {
      for (var m in reg.allMatches(input)) {
        var matchText = m.group(0)!;
        var start = m.start;
        var end = start + matchText.length;
        if (end == cursor) {
          match = m;
          break;
        }
      }
    }
    var matchText = match?.group(0);
    if (matchText != null) {
      var start = match!.start;
      var end = start + matchText.length;
      if (atReg.hasMatch(matchText)) {
        String id = matchText.replaceFirst("@", "").trim();
        if (curMsgAtUser.remove(id)) {
          inputCtrl.text = input.replaceRange(start, end, '');
          cursor = start;
        } else {
          inputCtrl.text = input.replaceRange(cursor - 1, cursor, '');
          --cursor;
        }
      } else if (emojiReg.hasMatch(matchText)) {
        inputCtrl.text = input.replaceRange(start, end, "");
        cursor = start;
      } else {
        inputCtrl.text = input.replaceRange(cursor - 1, cursor, '');
        --cursor;
      }
    } else {
      inputCtrl.text = input.replaceRange(cursor - 1, cursor, '');
      --cursor;
    }
    _lastCursorIndex = cursor;
  }

  WillPopCallback? willPop() {
    return multiSelMode.value || isShowPopMenu.value
        ? () async => exit()
        : null;
  }

  /// 发送语音
  void sendVoice({required int duration, required String path}) async {
    var message =
        await OpenIM.iMManager.messageManager.createSoundMessageFromFullPath(
      soundPath: path,
      duration: duration,
    );
    _sendMessage(message);
  }

  void onStartVoiceInput() {
    SpeechToTextUtil.instance.startListening((String result) {
      return inputCtrl.text = result;
    });
  }

  void onStopVoiceInput() {
    SpeechToTextUtil.instance.stopListening();
  }

  var scaleFactor = Config.textScaleFactor.obs;
  var background = "".obs;

  void _initChatConfig() async {
    scaleFactor.value = DataSp.getChatFontSizeFactor();
    var path = DataSp.getChatBackground() ?? '';
    if (path.isNotEmpty && (await File(path).exists())) {
      background.value = path;
    }
  }

  /// 修改聊天字体
  changeFontSize(double factor) async {
    await DataSp.putChatFontSizeFactor(factor);
    scaleFactor.value = factor;
    IMViews.showToast(StrRes.setSuccessfully);
  }

  /// 修改聊天背景
  changeBackground(String path) async {
    await DataSp.putChatBackground(path);
    background.value = path;
    IMViews.showToast(StrRes.setSuccessfully);
  }

  /// 清除聊天背景
  clearBackground() async {
    await DataSp.clearChatBackground();
    background.value = '';
    IMViews.showToast(StrRes.setSuccessfully);
  }

  void queryUserOnlineStatus() {
    if (isSingleChat) {
      Apis.queryUserOnlineStatus(
        uidList: [userID!],
        onlineStatusCallback: (map) {
          onlineStatus.value = map[userID]!;
        },
        onlineStatusDescCallback: (map) {
          onlineStatusDesc.value = map[userID]!;
        },
      );
    }
  }

  /// 清除所有强提醒
  void _resetGroupAtType() {
    // 删除所有@标识/公告标识
    if (conversationInfo.groupAtType != GroupAtType.atNormal) {
      OpenIM.iMManager.conversationManager.resetConversationGroupAtType(
        conversationID: conversationInfo.conversationID,
      );
    }
  }

  /// 多选删除
  void mergeDelete() {
    Get.bottomSheet(
      BottomSheetView(items: [
        SheetItem(
          label: StrRes.delete,
          borderRadius: _borderRadius,
          onTap: _deleteMultiMsg,
        ),
      ]),
      barrierColor: Colors.transparent,
    );
  }

  /// 合并转发
  void mergeForward() {
    // IMWidget.showToast('调试中，敬请期待!');
    Get.bottomSheet(
      BottomSheetView(
        items: [
          SheetItem(
            label: StrRes.mergeForward,
            borderRadius: _borderRadius,
            onTap: () async {
              var result = await AppNavigator.startSelectContacts(
                action: SelAction.forward,
              );
              if (null != result) {
                sendMergeMsg(
                  userId: result['userID'],
                  groupId: result['groupID'],
                );
              }
            },
          ),
        ],
      ),
      barrierColor: Colors.transparent,
    );
  }

  /// 合并转发
  void sendMergeMsg({
    String? userId,
    String? groupId,
  }) async {
    var summaryList = <String>[];
    var title;
    for (var msg in multiSelList) {
      summaryList.add('${msg.senderNickname}：${IMUtils.parseMsg(msg, replaceIdToNickname: true)}');
      if (summaryList.length >= 2) break;
    }
    if (isGroupChat) {
      title = "群聊${StrRes.chatRecord}";
    } else {
      var partner1 = OpenIM.iMManager.userInfo.getShowName();
      var partner2 = nickname.value;
      title = "$partner1和$partner2${StrRes.chatRecord}";
    }
    var message = await OpenIM.iMManager.messageManager.createMergerMessage(
      messageList: multiSelList,
      title: title,
      summaryList: summaryList,
    );
    _sendMessage(message, userId: userId, groupId: groupId);
  }



  /// 处理输入框输入@字符
  String? openAtList() {
    if (groupID != null && groupID!.isNotEmpty) {
      var cursor = inputCtrl.selection.baseOffset;
      AppNavigator.startGroupMemberList(
        groupInfo: GroupInfo(groupID: groupID!),
        opType: GroupMemberOpType.at,
      )?.then((memberList) {
        if (memberList is List<GroupMembersInfo>) {
          var buffer = StringBuffer();
          memberList.forEach((e) {
            _setAtMapping(
              userID: e.userID!,
              nickname: e.nickname ?? '',
              faceURL: e.faceURL,
            );
            if (!curMsgAtUser.contains(e.userID)) {
              curMsgAtUser.add(e.userID!);
              buffer.write(' @${e.userID} ');
            }
          });
          // for (var uid in uidList) {
          //   if (curMsgAtUser.contains(uid)) continue;
          //   curMsgAtUser.add(uid);
          //   buffer.write(' @$uid ');
          // }
          if (cursor < 0) cursor = 0;
          // 光标前面的内容
          var start = inputCtrl.text.substring(0, cursor);
          // 光标后面的内容
          var end = inputCtrl.text.substring(cursor + 1);
          inputCtrl.text = '$start$buffer$end';
          inputCtrl.selection = TextSelection.fromPosition(TextPosition(
            offset: '$start$buffer'.length,
          ));
          _lastCursorIndex = inputCtrl.selection.start;
        } else {}
      });
      return "@";
    }
    return null;
  }

  /// 触摸其他地方强制关闭工具箱
  void closeToolbox() {
    forceCloseToolbox.addSafely(true);
  }

}
