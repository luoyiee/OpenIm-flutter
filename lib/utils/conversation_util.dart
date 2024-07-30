import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';

import 'account_util.dart';

class ConversationUtil extends GetxController {
  final accountUtil = Get.find<AccountUtil>();

  String get accountKey => DataSp.getCurAccountLoginInfoKey();

  String getKey(String conversationID) => accountKey + "__" + conversationID;

  updateStore(String conversationID, {int? waitingST = -1}) {
    final key = getKey(conversationID);
    DataSp.putConversationStore({
      key: ConversationConfig.fromJson({
        "key": key,
        "conversationID": conversationID,
        "waitingST": waitingST
      })
    });
  }

  getConversationStoreById(String conversationID) {
    return DataSp.getConversationStore()?[getKey(conversationID)];
  }

  resetAllWaitingST() {
    final store = DataSp.getConversationStore();
    if (null != store) {
      store.forEach((key, value) {
        updateStore(value.conversationID, waitingST: -1);
      });
    }
  }
}
