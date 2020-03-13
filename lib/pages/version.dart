import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:znjjwyz/config/config.dart';
import 'dart:convert';
import 'package:simple_permissions/simple_permissions.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:znjjwyz/util/local_storage.dart';

import 'index.dart';
import 'login.dart';

class Version extends StatefulWidget {
  @override
  _VersionState createState() => _VersionState();
}

class _VersionState extends State<Version> {
  String _url = "";
  static String _fileName = "znjj.apk";
  Timer _ctXl;
  Directory directory;

  static String _d = "";

  _VersionState() {
    _ctXlGx();
  }

  @override
  void dispose() {
    if (null != _ctXl) _ctXl.cancel();
    super.dispose();
  }

  _ctXlGx() async {
    checkVersion();
    _ctXl = Timer.periodic(new Duration(milliseconds: 3000), (timer) {
      checkVersion();
    });
  }

  _checkLoginStatus() async {
//    await LocalStorage().set("token", "0-0");
    String token = await LocalStorage().get("token");
    _checkToken(token);
  }

  _checkToken(String token) async {
    String url = Config().host + "/user/flushToken?token=" + token;
    final http.Response response = await http.get(url);
    var data = json.decode(response.body);
    var result = data['code'];
    if (result == 0) {
      await LocalStorage().set("token", data['data']['token']);
      await LocalStorage().set("userId", data['data']['id'].toString());
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => Index()),
          (route) => route == null);
    } else {
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => Login()),
          (route) => route == null);
    }
    print(result);
  }

  checkVersion() async {
    var url = Config().host + "/apkVersion/queryLastVersion";
    var downloadUrl = "";
    var fileName = "";
    String result;
    try {
      final http.Response response = await http.get(url);
      var data = json.decode(response.body);
      print(data);
      if (_ctXl != null) _ctXl.cancel();
      int version = data['data']['num'];
      if (version > Config().version) {
        downloadUrl = data['data']['url'];
        print(downloadUrl);
        if (downloadUrl.length > 10) {
          List<String> list = downloadUrl.split("/");
          fileName = list[list.length - 1];
        }
        _fileName = fileName;
        setState(() {
          _url = downloadUrl;
        });
      } else {
        _checkLoginStatus();
      }
    } catch (exception) {
      result = 'Failed getting IP address';
    }
    if (!mounted) return;
  }

  nowUpdate() async {
//    Navigator.of(context).pop();
    bool res = await SimplePermissions.checkPermission(
        Permission.WriteExternalStorage);
    print(res);
    if (!res) {
      await SimplePermissions.requestPermission(
          Permission.WriteExternalStorage);
      print("xxxxx");
      res = await SimplePermissions.checkPermission(
          Permission.WriteExternalStorage);
      print(res);
    }
    if (res) {
      var directory = await getExternalStorageDirectory();
      print(directory.path);
      FlutterDownloader.initialize();
      choiceUpdate(context);
      FlutterDownloader.registerCallback((id, status, progress) {
        print(
            'Download task ($id) is in status ($status) and process ($progress)');
        if (status == DownloadTaskStatus.complete) {
          print(directory.path);
          print(_fileName);
          OpenFile.open(directory.path + "/" + _fileName);
          FlutterDownloader.open(taskId: id);
        }
      });
      String url = _url;
      if (url.contains('http://')) {
        url = url.replaceAll('http://', 'https://');
      }
      final taskId = await FlutterDownloader.enqueue(
//          url: "https://assets-store-cdn.48lu.cn/assets-store/c3ba1aa37bdbb78386416c703ee7eb14.apk",
//          url: "https://assets-store-cdn.48lu.cn/assets-store/395845999373aa6588c7659d54a92b0c.pdf",
//          url: "https://assets-store-cdn.48lu.cn/assets-store/6845eee23f7ec0036eed7935f827f9e5.jpg",
        url: url,
        savedDir: directory.path,
        fileName: _fileName,
        showNotification: true,
        // show download progress in status bar (for Android)
        openFileFromNotification:
            true, // click on notification to open downloaded file (for Android)
      );
    } else {}
  }

  Widget choiceUpdate(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return new AlertDialog(
            content: StatefulBuilder(builder: (context, StateSetter setState) {
          return Container(
            height: 50,
            child: Column(
              children: <Widget>[
                Container(
                  padding: EdgeInsets.only(bottom: 15),
                  child: Text('下载中'),
                ),
                new LinearProgressIndicator(
                  backgroundColor: Colors.blue,
                  valueColor: new AlwaysStoppedAnimation<Color>(Colors.red),
                ),
//                new Container(padding: const EdgeInsets.all(20.0)),
              ],
            ),
          );
        }));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: !(_url != null && _url.length > 0)
          ? Center(
              child: Image.asset("img/loading.gif"),
            )
          : Container(
              width: double.infinity,
              height: double.infinity,
              decoration: new BoxDecoration(
                gradient: const LinearGradient(colors: [
                  Color.fromARGB(255, 16 + 14, 16 * 6 + 15, 250),
                  Color.fromARGB(255, 16 * 4 + 2, 16 * 10 + 1, 250),
                ]),
              ),
              child: Column(
                children: <Widget>[
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.only(top: 60, left: 50),
                    child: Text(
                      '发现新版本',
                      style: TextStyle(color: Colors.white, fontSize: 28),
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.only(top: 8, left: 58),
                    child: Text(
                      'Welcome home',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ),
                  Container(
                    child: Image.asset('img/xg.png'),
                  ),
                  Container(
                    child: Image.asset('img/xg1.png'),
                  ),
                  Container(
                    padding: EdgeInsets.only(top: 25),
                    child: Text(
                      '智 能 管 家',
                      style: TextStyle(color: Colors.white, fontSize: 24),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.only(top: 5),
                    child: Text(
                      '智能家居 开启生活',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                  Container(
                    width: 300,
                    height: 50,
                  ),
                  GestureDetector(
                    onTap: () {
//                      choiceUpdate(context);
                      nowUpdate();
                    },
                    child: Container(
                      width: 300,
                      height: 45,
                      decoration: new BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.all(Radius.circular(10.0)),
                      ),
                      child: Center(
                        child: Text(
                          '立 即 更 新',
                          style:
                              TextStyle(color: Colors.blueAccent, fontSize: 20),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
