import 'package:chat_demo/Model/chatModel.dart';
import 'package:chat_demo/Tools/sqliteHelper.dart';
import 'package:flutter/material.dart';

///!
class ChatRecordsProvider with ChangeNotifier {
  List<ChatModel> chats = <ChatModel>[]; //所有chatMdel
  String loginId;
  String otherId;
  bool ifDisposed = false; //是否dispose
  int offset = 0; //chats count rendered
  ChatRecordsProvider(String loginUser, String toUser) {
    loginId = loginUser;
    otherId = toUser;
    getChatRecordsByUserId(); //!
  }

  //通过id获取每页30条聊天记录,返回的是<chatModel>[]
  getChatRecordsByUserId() async {
    List<ChatModel> chatsNewAdd =
        await SqliteHelper().getChatRecordsByUserId(loginId, otherId, offset);
    chats.addAll(chatsNewAdd); //!chatsNewAdd添加到chats,下面还有单个插入
    notifyListeners();
  }

  //添加一个新的chatModel到chats
  updateChatRecordsInChat(ChatModel chat) {
    chats.insert(0, chat);
    notifyListeners();
  }

  @override
  void dispose() {
    ifDisposed = true; //是否销毁
    super.dispose();
  }
}
