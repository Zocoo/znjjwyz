import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:connectivity/connectivity.dart';
import 'package:smartconfig/smartconfig.dart';
import 'package:znjjwyz/config/config.dart';
import 'package:znjjwyz/util/local_storage.dart';

class Connwifi extends StatefulWidget {
  @override
  _ConnwifiState createState() => _ConnwifiState();
}

class _ConnwifiState extends State<Connwifi> {
  String _bssid = '';
  String _key = '';
  String _keys = '';
  String _ssid = '';
  String _msg = '初始化中';
  TextEditingController _phonecontroller = new TextEditingController();
  Timer _ct;
  int _tmp = 0;

  void _tgo() {
    _ct = Timer.periodic(new Duration(seconds: 5), (timer) {
      if (_tmp < 36) {
        _tmp++;
        _querySetNetWork();
      } else {
        setState(() {
          _msg = '配网失败，请检测智能设备是否处于配网模式，Wi-Fi密码是否输入正确。';
        });
        if (_ct != null) _ct.cancel();
      }
    });
  }

  _ConnwifiState() {
    _initWifi();
  }

  @override
  void dispose() {
    if (_ct != null) _ct.cancel();
    super.dispose();
  }

  _querySetNetWork()async{
    String token = await LocalStorage().get("token");
    String url = Config().host +
        "/device/querySetNetWork?key=" +
        _keys +
        "&token=" +
        token;
    final http.Response response = await http.get(url);
    Utf8Decoder utf8decoder = new Utf8Decoder();
    Map data = json.decode(utf8decoder.convert(response.bodyBytes));
    print(data);
    var result = data['code'];
    if (result == 0) {
      if (_ct != null) _ct.cancel();
      setState(() {
        _msg = '配网成功';
      });
    }
  }

  _initWifi() async {
    String bssid = await (Connectivity().getWifiBSSID());
    String ip = await (Connectivity().getWifiIP());
    String ssid = await (Connectivity().getWifiName());
//    print(bssid + "||" + ip + "||" + ssid);
    _bssid = bssid;
    _key = new DateTime.now().millisecondsSinceEpoch.toString();
    _keys = _key;
    _key = _key + "-" +await LocalStorage().get("userId");
    print(_key);
    _ssid = ssid;
    if (_ssid == null ||
        _bssid == null ||
        _ssid.length < 1 ||
        _bssid.length < 1) {
      setState(() {
        _msg = '请确认您手机已经连接到可用Wi-Fi，连接好后点击下方重试按钮。';
      });
    } else {
      setState(() {
        _msg =
            '请确认您的智能设备处于配网状态，然后在下方输入框中输入<' + _ssid + '>Wi-Fi对应的密码后，点击下方的开始配网按钮';
      });
    }
//    _smartConfig(ssid, bssid, '88889999');
  }

  _smartConfig(String ssid, String bssid, String password) async {
    print("start Config ...");
    String password1 = password + "-w-y-z-" + _key;
    Smartconfig.start(ssid, bssid, password1).then((onValue) {
      print("sm version $onValue");
      _smartConfig(ssid, bssid, password);
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 26, 16 * 8 + 4, 13 * 16 + 10),
      body: Column(
        children: <Widget>[
          Expanded(
            child: Container(
//              color: Colors.red,
              child: (_msg == null || _msg.length < 1)
                  ? Image.asset('img/sm.gif')
                  : Center(
                      child: Container(
                        padding: EdgeInsets.all(50),
                        child: Text(
                          _msg,
                          style: TextStyle(color: Colors.white, fontSize: 24),
                        ),
                      ),
                    ),
            ),
          ),
          (_msg == null || _msg.length < 1)
              ? Container()
              : Container(
                  width: double.infinity,
                  height: 180,
                  child: Center(
                    child: (_ssid == null ||
                            _bssid == null ||
                            _ssid.length < 1 ||
                            _bssid.length < 1)
                        ? MaterialButton(
                            color: Colors.white,
                            height: 45,
                            minWidth: 220,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            onPressed: () {
                              _initWifi();
                            },
                            child: Text(
                              '重 试',
                              style: TextStyle(
                                  color: Colors.blueAccent, fontSize: 20),
                            ),
                          )
                        : (_msg != null && _msg == '配网成功')
                            ? Container(
                                child: MaterialButton(
                                  color: Colors.white,
                                  height: 45,
                                  minWidth: width - 100,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: Text(
                                    '返 回',
                                    style: TextStyle(
                                        color: Colors.blueAccent, fontSize: 20),
                                  ),
                                ),
                              )
                            : Container(
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: <Widget>[
                                    Container(
                                        width: width - 100,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(30.0)),
                                          boxShadow: <BoxShadow>[
                                            new BoxShadow(
                                              color: Colors.black45,
                                              blurRadius: 2.0,
                                              offset: Offset(1.0, 3.0),
                                            ),
                                          ],
                                        ),
                                        child: Container(
                                          padding: EdgeInsets.only(
                                              left: 25, right: 25),
                                          child: TextField(
                                            controller: _phonecontroller,
                                            keyboardType: TextInputType.phone,
                                            decoration: new InputDecoration(
                                                hintText: '请输入Wi-Fi密码',
                                                border: InputBorder.none),
                                          ),
                                        )),
                                    MaterialButton(
                                      color: Colors.white,
                                      height: 45,
                                      minWidth: width - 100,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(25),
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          if (_phonecontroller.text == null ||
                                              _phonecontroller.text.length <
                                                  8) {
                                            _msg = '请先输入8位及以上Wi-Fi密码！';
                                          } else {
                                            _msg = '';
                                            _tgo();
                                            _smartConfig(_ssid, _bssid,
                                                _phonecontroller.text);
                                          }
                                        });
                                      },
                                      child: Text(
                                        '开 始 配 网',
                                        style: TextStyle(
                                            color: Colors.blueAccent,
                                            fontSize: 20),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                  ),
                ),
        ],
      ),
    );
  }
}
