import 'dart:math';

import 'package:chat_demo/Model/chatModel.dart';
import 'package:chat_demo/Model/chatRecordModel.dart';
import 'package:chat_demo/Model/sqliteModel/tchatlog.dart';
import 'package:chat_demo/Model/sqliteModel/tuser.dart';
import 'package:chat_demo/Pages/MapPage/gaodeMapPage.dart';
import 'package:chat_demo/Provider/XFVoiceProvider.dart';
import 'package:chat_demo/Provider/bottomRowAnimProvider.dart';
import 'package:chat_demo/Provider/chatListProvider.dart';
import 'package:chat_demo/Provider/chatRecordsProvider.dart';
import 'package:chat_demo/Provider/contentEditingProvider.dart';
import 'package:chat_demo/Provider/gaodeMapProvider.dart';
import 'package:chat_demo/Provider/globalDataProvider.dart';
import 'package:chat_demo/Provider/goSocketProvider.dart';
import 'package:chat_demo/Provider/signalRProvider.dart';
import 'package:chat_demo/Provider/voiceRecordProvider.dart';
import 'package:chat_demo/Provider/webRTCProvider.dart';
import 'package:chat_demo/Tools/StaticMembers.dart';
import 'package:chat_demo/Tools/sqliteHelper.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'chatBottomRow.dart';
import 'chatDetailList.dart';

class DetailPage extends StatelessWidget {
  const DetailPage(
      {Key key,
      @required this.webRTCProvider,
      @required this.goSocketProvider,
      @required this.otherId,
      @required this.chatListProvider})
      : super(key: key);
  final WebRTCProvider webRTCProvider;
  final GoSocketProvider goSocketProvider;
  final String otherId;
  final ChatListProvider chatListProvider;
  @override
  Widget build(BuildContext context) {
    // GoSocketProvider provider = Provider.of<GoSocketProvider>(context);
    VoiceRecordProvider voiceRecordProvider =
        Provider.of<VoiceRecordProvider>(context);
    ContentEditingProvider contentEditingProvider =
        Provider.of<ContentEditingProvider>(context);
    XFVoiceProvider xfVoiceProvider = Provider.of<XFVoiceProvider>(context);
    BottomRowAnimProvider bottomRowAnimProvider =
        Provider.of<BottomRowAnimProvider>(context);
    GlobalDataProvider globalDataProvider =
        Provider.of<GlobalDataProvider>(context);
    ChatRecordsProvider chatRecordsProvider =
        Provider.of<ChatRecordsProvider>(context);
    goSocketProvider.updateChatDetail(chatRecordsProvider); //!
    // goSocketProvider.updateChatListProvider(chatListProvider);
    // if (provider == null || provider.conn == null || provider.connId == null) {
    //   return Center(
    //     child: CircularProgressIndicator(),
    //   );
    // }
    bool ifVoiceRecord = voiceRecordProvider.ifVoiceRecord;
    TextEditingController txtController = contentEditingProvider.txtController;
    double toBottom = MediaQuery.of(context).viewInsets.bottom;
    double rpx = MediaQuery.of(context).size.width / 750;
    txtController.addListener(() {
      contentEditingProvider.updateEditStatus(txtController.text);
    });
    return Scaffold(
        backgroundColor: Color.fromARGB(255, 231, 231, 231),
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          title: Text("AAA"),
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.more_horiz),
              onPressed: () async {
                final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => MultiProvider(providers: [
                              ChangeNotifierProvider(
                                builder: (_) => GaodeMapProvider(context),
                              ),
                            ], child: GaodeMapMain())));
                if (result != null) {
                  TChatLog chatRecord = TChatLog(
                    locaddress: result["address"],
                    title: result["title"],
                    locationImg: result["filePath"],
                    contentType: CHATTYPE.LOCATION,
                  );
                  ChatModel model = ChatModel();
                  // TChatLog newChat=TChatLog();
                  Tuser user = await SqliteHelper()
                      .getUserInfo(globalDataProvider.userId);
                  model.contentModel = chatRecord;
                  model.user = user;
                  chatRecordsProvider.updateChatRecordsInChat(model);
                }
              },
            )
          ],
        ),
        body: GestureDetector(
            onTap: () {
              bottomRowAnimProvider.reverseAnim();
            },
            child: ChatDetailList(
              chatProvider: goSocketProvider,
            )),
        bottomNavigationBar:
            // RecordVoiceRow()
            ChatBottomRow(
          otherId: otherId,
          webRTCProvider: webRTCProvider,
          provider: goSocketProvider,
          voiceRecordProvider: voiceRecordProvider,
          xfVoiceProvider: xfVoiceProvider,
          txtController: txtController,
          rpx: rpx,
          toBottom: toBottom,
        ));
  }
}

class TestFold extends StatefulWidget {
  TestFold({Key key}) : super(key: key);

  @override
  _TestFoldState createState() => _TestFoldState();
}

class _TestFoldState extends State<TestFold> {
  bool ifshow = true;

  hideOrShowList() {
    setState(() {
      ifshow = !ifshow;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ifshow
        ? Container(
            child: ListView.builder(
              itemCount: 1,
              itemBuilder: (BuildContext context, int index) {
                return FlatButton(
                  child: Text("click to hide"),
                  onPressed: () {
                    hideOrShowList();
                  },
                );
              },
            ),
          )
        : Container();
  }
}

class ChatBoxPainter extends CustomPainter {
  ChatBoxPainter(
      {@required this.width, @required this.height, @required this.color});
  final double width;
  final double height;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    Path path = Path()
      ..moveTo(0, height / 2)
      ..lineTo(width, height)
      ..lineTo(width, 0)
      ..lineTo(0, height / 2);

    Paint paint = Paint()
      ..style = PaintingStyle.fill
      ..color = color
      ..strokeWidth = 1;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(ChatBoxPainter oldDelegate) => false;

  @override
  bool shouldRebuildSemantics(ChatBoxPainter oldDelegate) => false;
}
