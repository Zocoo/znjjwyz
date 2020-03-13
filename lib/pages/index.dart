import 'dart:async';

import 'package:amap_location/amap_location.dart';
import 'package:flutter/material.dart';
import 'package:simple_permissions/simple_permissions.dart';
import 'package:znjjwyz/config/config.dart';
import 'package:znjjwyz/pages/wifi/connwifi.dart';
import 'package:znjjwyz/pojo/device.dart';
import 'package:znjjwyz/pojo/room_type.dart';
import 'package:znjjwyz/util/Toast.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:znjjwyz/util/local_storage.dart';

class Index extends StatefulWidget {
  @override
  _IndexState createState() => _IndexState();
}

class _IndexState extends State<Index> {
  double _lat = 0;
  double _long = 0;
  String _wetherIcon = 'img/w/dy.png';
  int _wd = 0;
  int _hwd = 0;
  int _lwd = 0;
  String _rq = '获取中';
  String _tq = '获取中';
  int _roomTypeId = 0;
  String _wdj = "未知";
  int _firstId = 0;
  String _sdj = "未知";
  List<RoomType> _roomList = [];
  List<Device> _deviceList = [];
  Timer _ct;
  int _tmp = 0;

  void _tgo() {
    _ct = Timer.periodic(new Duration(seconds: 5), (timer) {
      if (_tmp < 10) {
        _tmp++;
        if (_rq == '获取中')
          _getLocation();
//          _checkPersmission();
        else
          _ct.cancel();
      } else {
        if (_ct != null) _ct.cancel();
      }
    });
  }

  _IndexState() {
    _getLocation();
    _initRoomType();
    _tgo();
  }

  @override
  void dispose() {
    AMapLocationClient.shutdown();
    if (_ct != null) _ct.cancel();
    super.dispose();
  }

  _getPower(int i) async {
    if (_deviceList.length > i) {
      if (_deviceList[i].remark.contains('在线')) {
        String token = await LocalStorage().get("token");
        String url = Config().host +
            "/device/readPower?cid=" +
            _deviceList[i].sn +
            "&pin=4" +
            "&token=" +
            token;
        final http.Response response = await http.get(url);
        Utf8Decoder utf8decoder = new Utf8Decoder();
        Map data = json.decode(utf8decoder.convert(response.bodyBytes));
        print(data);
        var result = data['code'];
        if (result == 0) {
          setState(() {
            if (_deviceList.length > i) _deviceList[i].power = data['data'];
          });
        }
      }
    }
  }

  _setPower(int i) async {
    if (_deviceList.length > i) {
      if (_deviceList[i].remark.contains('在线')) {
        String token = await LocalStorage().get("token");
        int f = 0;
        if (_deviceList[i].power == 'OFF') {
          f = 1;
          setState() {
            _deviceList[i].power = 'ON';
          }
        } else {
          setState(() {
            _deviceList[i].power = 'OFF';
          });
        }
        ;
        String url = Config().host +
            "/device/setPower?cid=" +
            _deviceList[i].sn +
            "&pin=4" +
            "&token=" +
            token +
            "&fun=" +
            f.toString();
        final http.Response response = await http.get(url);
        Utf8Decoder utf8decoder = new Utf8Decoder();
        Map data = json.decode(utf8decoder.convert(response.bodyBytes));
        print(data);
        var result = data['code'];
        if (result == 0) {
          _getPower(i);
        } else {
          Toast.toast(context, data['msg']);
        }
      }
    }
  }

  _readTH(int i) async {
    if (_deviceList.length > i) {
      if (_deviceList[i].remark.contains('在线')) {
        setState(() {
          _deviceList[i].wd = '';
          _deviceList[i].sd = '';
        });
        String token = await LocalStorage().get("token");
        String url = Config().host +
            "/device/readTH?cid=" +
            _deviceList[i].sn +
            "&token=" +
            token;
        final http.Response response = await http.get(url);
        Utf8Decoder utf8decoder = new Utf8Decoder();
        Map data = json.decode(utf8decoder.convert(response.bodyBytes));
        print(data);
        var result = data['code'];
        if (result == 0) {
          Map<String, String> md = new Map();
          double dt = double.parse(data['data']['data']['t'].toString());
          double dh = double.parse(data['data']['data']['h'].toString());
          print(dt);
          print(dh);
          if (dt > -100) {
            String wd = dt.toString();
            wd = wd.replaceAll(".0", '');
            setState(() {
              if (_deviceList.length > i) {
                if (_deviceList[i].id == _firstId) _wdj = wd;
                _deviceList[i].wd = wd;
              }
            });
          }
          if (dh > -100) {
            String sd = dh.toString();
            sd = sd.replaceAll(".0", '');
            setState(() {
              if (_deviceList.length > i) {
                if (_deviceList[i].id == _firstId) _sdj = sd;
                _deviceList[i].sd = sd;
              }
            });
          }
        }
      }
    }
  }

  _setRoomType(int id, int roomTypeId, context) async {
    _firstId = 0;
    var url = Config().host +
        "/device/setRoomType?token=" +
        await LocalStorage().get("token") +
        "&deviceId=" +
        id.toString() +
        "&roomTypeId=" +
        roomTypeId.toString();
    final http.Response response = await http.get(url);
    var data = json.decode(response.body);
    var result = data['code'];
    if (result == 0) {
      Navigator.pop(context);
      Toast.toast(context, '设置成功！');
      _getDevice();
    }
  }

  _getDevice() async {
    setState(() {
      _deviceList = [];
    });
    _firstId = 0;
    var url = Config().host +
        "/device/queryByUserId?token=" +
        await LocalStorage().get("token") +
        "&userId=" +
        await LocalStorage().get('userId') +
        "&roomTypeId=" +
        _roomTypeId.toString();
    final http.Response response = await http.get(url);
    var data = json.decode(response.body);
    var result = data['code'];
    if (result == 0) {
      List<Device> list = _deviceList;
      List<dynamic> datas = data['data'];
      if (datas != null)
        for (int i = 0; i < datas.length; i++) {
          list.add(Device.fromJson(datas[i]));
        }
      else
        list = [];
      setState(() {
        _deviceList = list;
        print("ssssss" + _deviceList.length.toString());
        for (int i = 0; i < _deviceList.length; i++) {
          if (_deviceList[i].type == 'hj') {
            if (_firstId == 0) _firstId = _deviceList[i].id;
            _readTH(i);
          } else {
            _getPower(i);
          }
        }
      });
    }
  }

  _initRoomType() async {
    var url = Config().host +
        "/roomType/queryAll?token=" +
        await LocalStorage().get("token");
    final http.Response response = await http.get(url);
    var data = json.decode(response.body);
    var result = data['code'];
    if (result == 0) {
      RoomType r = new RoomType();
      r.id = 0;
      r.name = '全 部';
      r.createAt = 0;
      List<RoomType> list = _roomList;
      list.add(r);
      List<dynamic> datas = data['data'];
      for (int i = 0; i < datas.length; i++) {
        list.add(RoomType.fromJson(datas[i]));
      }
      setState(() {
        _roomList = list;
        _getDevice();
      });
    }
  }

  Future<Null> _flush() async {
    setState(() {
      _deviceList = [];
    });
    _getDevice();
    return;
  }

  _getWeather(String ll) async {
    String result1 = null;
    result1 = await LocalStorage().get('tqsj');
    double n = new DateTime.now().millisecondsSinceEpoch / 1000;
    int t = 0;
    String ccs = await LocalStorage().get('tqtime');
    if (ccs == null || ccs.length < 1) ccs = "0.01";
    double cc = double.parse(ccs);
    if (result1 != null &&
        result1.length > 0 &&
        cc != null &&
        (n - cc) < 3600) {
    } else {
      String url =
          "https://api.jisuapi.com/weather/query?appkey=ee33a933b039f5ef&location=" +
              ll;
      final http.Response response = await http.get(url);
      result1 = response.body;
      t = 1;
    }
    var data = json.decode(result1);
    var result = data['status'];
    if (result == 0) {
      if (t == 1) {
        await LocalStorage().set("tqsj", result1);
        await LocalStorage().set("tqtime",
            (new DateTime.now().millisecondsSinceEpoch / 1000).toString());
      }
      setState(() {
        _rq = data['result']['date'];
        _wd = int.parse(data['result']['temp']);
        _hwd = int.parse(data['result']['temphigh']);
        _lwd = int.parse(data['result']['templow']);
        _tq = data['result']['weather'];
        if (_tq == '晴') {
          _wetherIcon = 'img/w/q.png';
        } else if (_tq == '多云') {
          _wetherIcon = 'img/w/dy.png';
        } else if (_tq == '雪') {
          _wetherIcon = 'img/w/zx.png';
        } else if (_tq == '雨') {
          _wetherIcon = 'img/w/zy.png';
        } else if (_tq.contains('晴') &&
            _tq.contains('阴') &&
            _tq.contains('云')) {
          _wetherIcon = 'img/w/qzyzy.png';
        } else if (_tq.contains('晴') && _tq.contains('云')) {
          _wetherIcon = 'img/w/qzdy.png';
        } else if (_tq.contains("小雨")) {
          _wetherIcon = 'img/w/xy.png';
        } else if (_tq.contains("中雨")) {
          _wetherIcon = 'img/w/zy.png';
        } else if (_tq.contains("大雨")) {
          _wetherIcon = 'img/w/xdy.png';
        } else if (_tq.contains("大雪")) {
          _wetherIcon = 'img/w/dx.png';
        } else if (_tq.contains("中雪")) {
          _wetherIcon = 'img/w/zx.png';
        } else if (_tq.contains("小雪")) {
          _wetherIcon = 'img/w/xx.png';
        } else if (_tq.contains("雷") && _tq.contains("雨")) {
          _wetherIcon = 'img/w/ly.png';
        } else if (_tq.contains('雷')) {
          _wetherIcon = 'img/w/l.png';
        }
      });
    }
  }

  _getLocation() async {
    String jwd = await LocalStorage().get('jwd');
    String jwdsj = await LocalStorage().get('jwdsj');
    if (jwdsj == null || jwdsj.length < 1) jwdsj = '0.01';
    double n = new DateTime.now().millisecondsSinceEpoch / 1000;
    if (jwd != null &&
        jwd.length > 0 &&
        (n - double.parse(jwdsj)) < 3600 &&
        !jwd.contains("null")) {
      _getWeather(jwd);
    } else {
      print('xxxxxxxxx');
      _checkPersmission();
      await AMapLocationClient.startup(new AMapLocationOption(
          desiredAccuracy:
              CLLocationAccuracy.kCLLocationAccuracyHundredMeters));
      AMapLocation a = await AMapLocationClient.getLocation(true);
      await LocalStorage()
          .set('jwd', a.latitude.toString() + "," + a.longitude.toString());
      await LocalStorage().set("jwdsj",
          (new DateTime.now().millisecondsSinceEpoch / 1000).toString());
      _getWeather(a.latitude.toString() + "," + a.longitude.toString());
    }
  }

  void _checkPersmission() async {
    bool hasPermission =
        await SimplePermissions.checkPermission(Permission.WhenInUseLocation);
    if (!hasPermission) {
      PermissionStatus p = await SimplePermissions.requestPermission(
          Permission.WhenInUseLocation);
      if (p != PermissionStatus.authorized) {
        Toast.toast(context, "申请定位权限失败");
        return;
      }
    }
  }

  List<Widget> _getRoomTypes() {
    List<Widget> list = [];
    for (int i = 0; i < _roomList.length; i++) {
      list.add(
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            setState(() {
              _roomTypeId = _roomList[i].id;
              _getDevice();
            });
          },
          child: Container(
            width: 120,
            height: 80,
            child: Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  Text(
                    _roomList[i].name,
                    style: TextStyle(
                        color: _roomTypeId == _roomList[i].id
                            ? Colors.blueAccent
                            : Colors.black38,
                        fontSize: _roomList[i].id == _roomTypeId ? 22 : 18,
                        fontWeight: FontWeight.w600),
                  ),
                  Container(
                    width: 40,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _roomTypeId == _roomList[i].id
                          ? Colors.blueAccent
                          : Color.fromARGB(255, 238, 238, 238),
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return list;
  }

  _longPressDevice(int id, double w) {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return StatefulBuilder(builder: (context, state) {
            return new AlertDialog(
              title: Text("设置房间"),
              content: Container(
                height: 200,
                child: SingleChildScrollView(
                  child: Column(children: _getRoomTypesChoice(id, w, context)),
                ),
              ),
              actions: <Widget>[
                FlatButton(
                  child: Text('退出'),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            );
          });
        });
  }

  List<Widget> _getRoomTypesChoice(int id, double w, context) {
    List<Widget> list = [];
    for (int i = 0; i < _roomList.length; i++) {
      print("xxxxxxx" + i.toString());
      if (_roomList[i].id != 0)
        list.add(GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            _setRoomType(id, _roomList[i].id, context);
          },
          child: Container(
            height: 45,
            margin: EdgeInsets.only(top: 4),
            width: w - 100,
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
            child: Center(
              child: Text(_roomList[i].name,
                  style: TextStyle(color: Colors.white)),
            ),
          ),
        ));
    }
    return list;
  }

  List<Widget> _getDeviceUi(double w) {
    List<Widget> list = [];
    if (_deviceList == null || _deviceList.length < 1) {
      list.add(Container(
        padding: EdgeInsets.all(50),
        child: Center(
          child: Text(
            '暂无设备',
            style: TextStyle(fontSize: 22, color: Colors.black54),
          ),
        ),
      ));
    } else {
      double ww = (w - 50) / 2;
      if (_deviceList.length % 2 != 0) {
        Device d = new Device();
        d.type = 'none';
        d.remark = '1&&1&&1';
        _deviceList.add(d);
      }
      for (int i = 0; i < _deviceList.length; i++) {
        if (i % 2 != 0) {
          print(_deviceList[i].remark);
          List<String> _c1 = _deviceList[i - 1].remark.split("&&");
          print(_c1);
          String url1 = _c1[2];
          String status1 = _c1[0];
          String name1 = _c1[1];
          List<String> _c2 = _deviceList[i].remark.split("&&");
          print(_c2);
          String url2 = _c2[2];
          String status2 = _c2[0];
          String name2 = _c2[1];
          list.add(Container(
              padding: EdgeInsets.only(top: 15, bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onLongPress: () {
                      print(_deviceList[i - 1].id);
                      _longPressDevice(_deviceList[i - 1].id, w);
                    },
                    onTap: () {
                      if (_deviceList[i - 1].type == 'hj' &&
                          _deviceList[i - 1].remark.contains('在线')) {
                        _readTH(i - 1);
                      }
                    },
                    child: Container(
                      width: ww,
                      height: ww,
                      decoration: BoxDecoration(
                        gradient: i == 1
                            ? const LinearGradient(colors: [
                                Color.fromARGB(255, 16 + 14, 16 * 6 + 15, 250),
                                Color.fromARGB(
                                    255, 16 * 4 + 2, 16 * 10 + 1, 250),
                              ])
                            : const LinearGradient(colors: [
                                Color.fromARGB(255, 255, 255, 255),
                                Color.fromARGB(255, 255, 255, 255),
                              ]),
                        borderRadius: BorderRadius.all(Radius.circular(30.0)),
                        boxShadow: <BoxShadow>[
                          new BoxShadow(
                            color: Colors.black45,
                            blurRadius: 2.0,
                            offset: Offset(1.0, 3.0),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: <Widget>[
                          Container(
                            padding: EdgeInsets.only(left: 25, right: 25),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                _deviceList[i - 1].type == 'hj'
                                    ? i == 1
                                        ? Image.asset(
                                            'img/wdjb.png',
                                            height: 32,
                                            width: 32,
                                          )
                                        : Image.asset(
                                            'img/wdjl.png',
                                            height: 32,
                                            width: 32,
                                          )
                                    : i == 1
                                        ? name1 == '智能插座'
                                            ? Image.asset(
                                                'img/czb.png',
                                                height: 32,
                                                width: 32,
                                              )
                                            : Image.asset(
                                                'img/db.png',
                                                height: 32,
                                                width: 32,
                                              )
                                        : name1 == '智能插座'
                                            ? Image.asset(
                                                'img/czl.png',
                                                height: 32,
                                                width: 32,
                                              )
                                            : Image.asset(
                                                'img/dl.png',
                                                height: 32,
                                                width: 32,
                                              ),
                                status1 != '在线'
                                    ? Container(
                                        width: 20,
                                        height: 20,
                                        decoration: BoxDecoration(
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(30.0)),
                                            color: Colors.deepOrangeAccent),
                                      )
                                    : Container(
                                        width: 20,
                                        height: 20,
                                        decoration: BoxDecoration(
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(30.0)),
                                            color: Color.fromARGB(255, 16 + 10,
                                                14 * 15 + 10, 2 * 16 + 9)),
                                      ),
                              ],
                            ),
                          ),
                          Container(
                            width: ww - 50,
                            child: Text(
                              name1,
                              style: TextStyle(
                                  color:
                                      i == 1 ? Colors.white : Colors.blueAccent,
                                  fontSize: 18),
                            ),
                          ),
                          _deviceList[i - 1].type == 'hj'
                              ? Container(
                                  padding: EdgeInsets.only(top: 0),
                                  child: (_deviceList[i - 1].wd != null &&
                                          _deviceList[i - 1].wd.length > 0 &&
                                          _deviceList[i - 1].sd != null &&
                                          _deviceList[i - 1].sd.length > 0)
                                      ? Container(
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceEvenly,
                                            children: <Widget>[
                                              Text(
                                                _deviceList[i - 1].wd + "℃",
                                                style: TextStyle(
                                                    fontSize: 18,
                                                    color: i == 1
                                                        ? Colors.white
                                                        : Colors.blueAccent),
                                              ),
                                              Text(
                                                _deviceList[i - 1].sd + "%",
                                                style: TextStyle(
                                                    fontSize: 18,
                                                    color: i == 1
                                                        ? Colors.white
                                                        : Colors.blueAccent),
                                              )
                                            ],
                                          ),
                                        )
                                      : Container())
                              : Container(
                                  child: Row(
                                    children: <Widget>[
                                      GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onTap: () {
                                          _setPower(i - 1);
                                        },
                                        child: (_deviceList[i - 1].power !=
                                                    null &&
                                                _deviceList[i - 1]
                                                        .power
                                                        .length >
                                                    0)
                                            ? Container(
                                                padding: EdgeInsets.only(
                                                    top: 0, left: 25),
                                                child: Image.asset(
                                                  _deviceList[i - 1].power ==
                                                          'OFF'
                                                      ? 'img/kgon.png'
                                                      : 'img/kgoff.png',
                                                  height: 50,
                                                  width: 50,
                                                ),
                                              )
                                            : Container(),
                                      ),
                                    ],
                                  ),
                                ),
                        ],
                      ),
                    ),
                  ),
                  _deviceList[i].type != 'none'
                      ? GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onLongPress: () {
                            print(_deviceList[i].id);
                            _longPressDevice(_deviceList[i].id, w);
                          },
                          onTap: () {
                            if (_deviceList[i].type == 'hj' &&
                                _deviceList[i].remark.contains('在线')) {
                              _readTH(i);
                            }
                          },
                          child: Container(
                            width: ww,
                            height: ww,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius:
                                  BorderRadius.all(Radius.circular(30.0)),
                              boxShadow: <BoxShadow>[
                                new BoxShadow(
                                  color: Colors.black45,
                                  blurRadius: 2.0,
                                  offset: Offset(1.0, 3.0),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: <Widget>[
                                Container(
                                  padding: EdgeInsets.only(left: 25, right: 25),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: <Widget>[
                                      _deviceList[i].type == 'hj'
                                          ? Image.asset(
                                              'img/wdjl.png',
                                              height: 32,
                                              width: 32,
                                            )
                                          : name2 == '智能插座'
                                              ? Image.asset(
                                                  'img/czl.png',
                                                  height: 32,
                                                  width: 32,
                                                )
                                              : Image.asset(
                                                  'img/dl.png',
                                                  height: 32,
                                                  width: 32,
                                                ),
                                      status2 != '在线'
                                          ? Container(
                                              width: 20,
                                              height: 20,
                                              decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.all(
                                                          Radius.circular(
                                                              30.0)),
                                                  color:
                                                      Colors.deepOrangeAccent),
                                            )
                                          : Container(
                                              width: 20,
                                              height: 20,
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.all(
                                                    Radius.circular(30.0)),
                                                color: Color.fromARGB(
                                                    255,
                                                    16 + 10,
                                                    14 * 15 + 10,
                                                    2 * 16 + 9),
                                              ),
                                            ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: ww - 50,
                                  child: Text(
                                    name2,
                                    style: TextStyle(
                                        color: i == 0
                                            ? Colors.white
                                            : Colors.blueAccent,
                                        fontSize: 18),
                                  ),
                                ),
                                _deviceList[i].type == 'hj'
                                    ? Container(
                                        padding: EdgeInsets.only(top: 0),
                                        child: (_deviceList[i].wd != null &&
                                                _deviceList[i].wd.length > 0 &&
                                                _deviceList[i].sd != null &&
                                                _deviceList[i].sd.length > 0)
                                            ? Container(
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceEvenly,
                                                  children: <Widget>[
                                                    Text(
                                                      _deviceList[i].wd + "℃",
                                                      style: TextStyle(
                                                          fontSize: 18,
                                                          color: i == 0
                                                              ? Colors.white
                                                              : Colors
                                                                  .blueAccent),
                                                    ),
                                                    Text(
                                                      _deviceList[i].sd + "%",
                                                      style: TextStyle(
                                                          fontSize: 18,
                                                          color: i == 0
                                                              ? Colors.white
                                                              : Colors
                                                                  .blueAccent),
                                                    )
                                                  ],
                                                ),
                                              )
                                            : Container())
                                    : Container(
                                        child: Row(
                                          children: <Widget>[
                                            GestureDetector(
                                              behavior: HitTestBehavior.opaque,
                                              onTap: () {
                                                _setPower(i);
                                              },
                                              child: (_deviceList[i].power !=
                                                          null &&
                                                      _deviceList[i]
                                                              .power
                                                              .length >
                                                          0)
                                                  ? Container(
                                                      padding: EdgeInsets.only(
                                                          top: 0, left: 25),
                                                      child: Image.asset(
                                                        _deviceList[i].power ==
                                                                'OFF'
                                                            ? 'img/kgon.png'
                                                            : 'img/kgoff.png',
                                                        height: 50,
                                                        width: 50,
                                                      ),
                                                    )
                                                  : Container(),
                                            ),
                                          ],
                                        ),
                                      ),
                              ],
                            ),
                          ),
                        )
                      : Container(
                          width: ww,
                          height: ww,
                        ),
                ],
              )));
        }
      }
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 238, 238, 238),
      body: Column(
        children: <Widget>[
          Container(
            height: 25,
            width: double.infinity,
            color: Colors.white,
          ),
          Container(
            color: Colors.white,
            height: 150,
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Container(
                    color: Colors.white,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        Container(
                          height: 70,
                          padding: EdgeInsets.only(left: 0),
                          width: 110,
                          child: Image.asset(_wetherIcon),
                        ),
                        Container(
                          padding: EdgeInsets.only(top: 50, left: 0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Container(
                                width: (width - 110 - 100),
                                child: Text(
                                  _tq +
                                      "(" +
                                      _lwd.toString() +
                                      "~" +
                                      _hwd.toString() +
                                      ")℃",
                                  softWrap: true,
                                  overflow: TextOverflow.fade,
                                  style: TextStyle(
                                      color: Colors.black87, fontSize: 16),
                                ),
                              ),
                              Text(
                                _rq,
                                style: TextStyle(
                                    color: Colors.black38, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  width: 100,
                  height: 100,
                  padding: EdgeInsets.only(right: 20, top: 10),
                  child: Image.asset('img/tt.png'),
                ),
              ],
            ),
          ),
          Container(
            height: 70,
            decoration: new BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30.0),
                  bottomRight: Radius.circular(30.0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                Column(
                  children: <Widget>[
                    Text(
                      _wdj + '℃',
                      style: TextStyle(
                          color: Colors.black54,
                          fontSize: 22,
                          fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '室内温度',
                      style: TextStyle(color: Colors.black38, fontSize: 14),
                    ),
                  ],
                ),
                Column(
                  children: <Widget>[
                    Text(
                      _wd.toString() + '℃',
                      style: TextStyle(
                          color: Colors.black54,
                          fontSize: 22,
                          fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '室外温度',
                      style: TextStyle(color: Colors.black38, fontSize: 14),
                    ),
                  ],
                ),
                Column(
                  children: <Widget>[
                    Text(
                      _sdj + '%',
                      style: TextStyle(
                          color: Colors.black54,
                          fontSize: 22,
                          fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '室内湿度',
                      style: TextStyle(color: Colors.black38, fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            margin: EdgeInsets.only(top: 20),
            width: double.infinity,
            height: 60,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _getRoomTypes(),
            ),
          ),
          Expanded(
            child: Container(
              child: RefreshIndicator(
                child: ListView(
                  children: _getDeviceUi(width),
                ),
                onRefresh: _flush,
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        isExtended: true,
        onPressed: () {
          Navigator.push(context,
              new MaterialPageRoute(builder: (BuildContext context) {
            return Connwifi();
          })).then((result) {
            print("xxxx");
          });
        },
      ),
    );
  }
}
