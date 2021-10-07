import 'dart:io';

// import 'package:amap/amap.dart';
import 'package:chat_demo/Model/userLoginModel.dart';
import 'package:chat_demo/Pages/Friends/friendsMain.dart';
import 'package:chat_demo/Provider/chatListProvider.dart';
import 'package:chat_demo/Provider/friendsProvider.dart';
import 'package:chat_demo/Provider/globalDataProvider.dart';
import 'package:chat_demo/Provider/goSocketProvider.dart';
import 'package:chat_demo/Provider/jPushProvider.dart';
import 'package:chat_demo/Provider/loginProvider.dart';
import 'package:chat_demo/Provider/signalRProvider.dart';
import 'package:chat_demo/Provider/themeProvider.dart';
import 'package:chat_demo/Provider/webRTCProvider.dart';
import 'package:chat_demo/Tools/StaticMembers.dart';
import 'package:chat_demo/Tools/dioHelper.dart';
import 'package:chat_demo/Tools/nativeTool.dart';
import 'package:chat_demo/Tools/sqliteHelper.dart';
import 'package:device_info/device_info.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:websocket_manager/websocket_manager.dart';
import 'Pages/Login/loginMain.dart';
import 'Pages/MainPage/chatList.dart';

getImei() async {
  String imeiT;
  if (Platform.isIOS) {
    var iosInfo = await DeviceInfoPlugin().iosInfo;
    imeiT = iosInfo.identifierForVendor;
  } else if (Platform.isAndroid) {
    var andInfo = await DeviceInfoPlugin().androidInfo;
    imeiT = andInfo.androidId;
  }
  return imeiT;
}

void normalLogin(String userId) {
  runApp(MaterialApp(
      theme: ThemeData(
          splashColor: Colors.transparent, highlightColor: Colors.transparent),
      home: MultiProvider(providers: [
        ChangeNotifierProvider(
          builder: (_) => LoginProvider(),
        ),
        ChangeNotifierProvider(
          builder: (_) => GlobalDataProvider(userId),
        ),
        ChangeNotifierProvider(
          builder: (_) => FriendsProvider(),
        )
      ], child: LoginMain())));
}

void passLogin(SharedPreferences prefs, String userId) {
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(
        builder: (_) => GoSocketProvider(userId),
      ),
      ChangeNotifierProvider(
        builder: (_) => ThemeProvider(prefs),
      ),
      ChangeNotifierProvider(
        builder: (_) => GlobalDataProvider(userId),
      ),
      ChangeNotifierProvider(
        builder: (_) => FriendsProvider(),
      )
    ],
    child: MyApp(
      prefs: prefs,
    ),
  ));
}

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  // var result=await Amap().initAmap();
  SharedPreferences prefs = await SharedPreferences.getInstance();

  // if (!prefs.containsKey('token')) {
  //   var token = await NativeTool.getTokenForNotify();
  //   await prefs.setString('token', token);
  //   print("token is : $token");
  // }

  SqliteHelper sqliteHelper = SqliteHelper();
  UserLoginModel loginModel = await sqliteHelper.findCurLoginRecord();

  if (loginModel.loginId != "" && loginModel.loginId != null) {
    if (DateTime.now().difference(loginModel.loginDate).inDays <= 5) {
      var dio = DioHelper().dio;
      var result = await dio.get("/user/ifSameIMEI", queryParameters: {
        "loginId": loginModel.loginId,
        "IMEI": await getImei(),
        "pushId": "pushId"
      });
      if (result.data['ifSame'] == true) {
        passLogin(prefs, loginModel.loginId);
      } else {
        normalLogin(loginModel.loginId);
      }
    } else {
      normalLogin(loginModel.loginId);
    }
  } else {
    normalLogin("");
  }
}

class MyApp extends StatelessWidget with WidgetsBindingObserver {
  const MyApp({Key key, this.prefs}) : super(key: key);
  final SharedPreferences prefs;
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      print('resumed');
    }
    super.didChangeAppLifecycleState(state);
  }

  @override
  Widget build(BuildContext context) {
    // GlobalDataProvider globalDataProvider=Provider.of<GlobalDataProvider>(context);
    ThemeProvider themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: '简单聊天',
      theme: ThemeData(
        primaryColor: themeProvider.themeColor,
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
      ),
      darkTheme: ThemeData.dark(),
      themeMode:
          themeProvider.lightMode == 0 ? ThemeMode.light : ThemeMode.dark,
      home: MultiProvider(providers: [
        ChangeNotifierProvider(
          builder: (_) => WebRTCProvider(context),
        )
      ], child: MainPage()),
    );
  }
}

class MainPage extends StatefulWidget {
  MainPage({Key key, this.prefs}) : super(key: key);
  final SharedPreferences prefs;
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with WidgetsBindingObserver {
  // SignalRProvider provider;
  SharedPreferences prefs;
  String chatId;
  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {}
  }

  List<PopupMenuEntry> addMenuItem(
      SharedPreferences prefs, List<PopupMenuEntry> menus) {
    menus.add(PopupMenuItem(
      value: THEMECOLORMAPPING.BLUEGREY,
      child: Text("BlueGrey"),
    ));
    menus.add(PopupMenuDivider(
      height: 1,
    ));
    menus.add(PopupMenuItem(
      value: THEMECOLORMAPPING.RED,
      child: Text("Red"),
    ));
    menus.add(PopupMenuDivider(
      height: 1,
    ));
    menus.add(PopupMenuItem(
      value: THEMECOLORMAPPING.PURPLE,
      child: Text("Purple"),
    ));
    menus.add(PopupMenuDivider(
      height: 1,
    ));
    menus.add(PopupMenuItem(
      value: THEMECOLORMAPPING.YELLOW,
      child: Text("Yellow"),
    ));
    menus.add(PopupMenuDivider(
      height: 1,
    ));
    return menus;
  }

  @override
  Widget build(BuildContext context) {
    List<PopupMenuEntry> menus = List<PopupMenuEntry>();
    ThemeProvider themeProvider = Provider.of<ThemeProvider>(context);
    GlobalDataProvider globalDataProvider =
        Provider.of<GlobalDataProvider>(context);
    GoSocketProvider goSocketProvider =
        Provider.of<GoSocketProvider>(context); //!
    WebRTCProvider webRTCProvider = Provider.of<WebRTCProvider>(context);
    FriendsProvider friendsProvider = Provider.of<FriendsProvider>(context);

    prefs = themeProvider.sharedPreferences;
    return Scaffold(
      appBar: AppBar(
        title: Text("简单聊天"),
        actions: <Widget>[
          IconButton(
            icon: themeProvider.lightMode == THEMEMODE.DARK
                ? Icon(Icons.brightness_7)
                : Icon(Icons.brightness_2),
            onPressed: () {
              themeProvider.changeThemeMode();
            },
          ),
          PopupMenuButton(
            icon: Icon(Icons.more_vert),
            itemBuilder: (_) {
              return addMenuItem(prefs, menus);
            },
            onSelected: (value) {
              themeProvider.changeSelColor(value);
            },
          ),
        ],
      ),
      body: MultiProvider(providers: [
        ChangeNotifierProvider(
          builder: (_) => ChatListProvider(globalDataProvider.userId),
        ),
        ChangeNotifierProvider(
          builder: (_) => WebRTCProvider(context),
        ),
      ], child: ChatList()),
      bottomNavigationBar: BottomNavigationBar(
        onTap: (index) async {
          if (index == 1) {
            await friendsProvider.getAllUsers();
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => FriendsMain(
                          goSocketProvider: goSocketProvider,
                          webRTCProvider: webRTCProvider,
                          globalDataProvider: globalDataProvider,
                        )));
          }
        },
        items: [
          BottomNavigationBarItem(
              icon: Icon(
                Icons.chat_bubble_outline,
                color: Colors.black,
              ),
              activeIcon: Icon(
                Icons.chat_bubble,
                color:
                    // Colors.blue
                    Theme.of(context).primaryColor,
              ),
              title: Text("聊天")),
          BottomNavigationBarItem(
              icon: Icon(
                Icons.perm_identity,
                color: Colors.black,
              ),
              activeIcon: Icon(
                Icons.chat_bubble,
                color: Colors.greenAccent,
              ),
              title: Text("好友"))
        ],
      ),
    );
  }
}
