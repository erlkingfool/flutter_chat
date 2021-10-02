import 'package:chat_demo/Model/chatModel.dart';
import 'package:chat_demo/Tools/sqliteHelper.dart';
import 'package:flutter/material.dart';

class ChatRecordsProvider with ChangeNotifier {
  List<ChatModel> chats = <ChatModel>[];
  String loginId;
  String otherId;
  bool ifDisposed = false; //是否dispose
  int offset = 0; //chats count rendered
  ChatRecordsProvider(String loginUser, String toUser) {
    loginId = loginUser;
    otherId = toUser;
    getChatRecordsByUserId();
  }
  getChatRecordsByUserId() async {
    List<ChatModel> chatsNewAdd = await SqliteHelper().getChatRecordsByUserId(
        loginId, otherId, offset); //通过id获取所有聊天记录,返回的是<chatModel>[]
    chats.addAll(chatsNewAdd); //!添加到chats,其实就是chatsNewAdd,未来可以优化
    notifyListeners();
  }

  //添加一个chatModel
  updateChatRecordsInChat(ChatModel chat) {
    chats.insert(0, chat);
    notifyListeners();
  }

  @override
  void dispose() {
    ifDisposed = true;
    super.dispose();
  }
}