import 'dart:async';

import 'package:flutter/material.dart';
import 'package:znjjwyz/config/config.dart';
import 'package:znjjwyz/util/Toast.dart';
import 'package:znjjwyz/util/local_storage.dart';
import 'index.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class Login extends StatefulWidget {
  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  bool _login = true;
  bool _forgetPassword = false;
  String _loginTitle = '登 陆';
  TextEditingController _phonecontroller = new TextEditingController();
  TextEditingController _passwordcontroller = new TextEditingController();
  TextEditingController _passwordcontrollerRegister =
      new TextEditingController();
  TextEditingController _codecontrollerRegister = new TextEditingController();
  TextEditingController _passwordcontrollerForgetPassword =
      new TextEditingController();
  TextEditingController _codecontrollerForgetPassword =
      new TextEditingController();
  String _sc = '发 送';
  int t = 60;
  Timer _ct;

  void _tgo() {
    setState(() {
      _sc = t.toString() + "秒";
      _ct = Timer.periodic(new Duration(seconds: 1), (timer) {
        setState(() {
          if (t > 0) {
            t--;
            _sc = t.toString() + "秒";
          } else {
            _sc = '发 送';
            t = 60;
            _ct.cancel();
            _ct = null;
          }
        });
      });
    });
  }

  _sendCodeRegister() async {
    if (_sc == '发 送') {
      String phone = _phonecontroller.text;
      if (phone != null && phone.length == 11) {
        String url = Config().host + "/user/sendCode?type=r&phone=" + phone;
        final http.Response response = await http.get(url);
        var data = json.decode(response.body);
        print(data);
        var result = data['code'];
        if (result == 0) {
          Toast.toast(context, '验证码发送成功！注意查收！');
          _tgo();
        } else {
          Toast.toast(context, data['msg']);
        }
      } else {
        Toast.toast(context, '请输入11位手机号！');
      }
    }
  }

  _registerAction() async {
    String phone = _phonecontroller.text;
    String password = _passwordcontrollerRegister.text;
    String code = _codecontrollerRegister.text;
    if (_checkPhone(phone) && _checkPassword(password) && _checkCode(code)) {
      String url = Config().host + "/user";
      String datax =
          json.encode({'phone': phone, 'password': password, 'salt': code});
      print(datax);
      final http.Response response = await http.post(url, body: datax);
      var data = json.decode(response.body);
      print(data);
      var result = data['code'];
      if (result == 0) {
        await LocalStorage().set("token", data['data']['token']);
        await LocalStorage().set("userId", data['data']['id'].toString());
        await LocalStorage().set("phoneLogin", _phonecontroller.text);
        Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => Index()),
            (route) => route == null);
      } else {
        Toast.toast(context, data['msg']);
      }
    }
  }

  _sendCodeForgetPassword() async {
    if (_sc == '发 送') {
      String phone = _phonecontroller.text;
      if (phone != null && phone.length == 11) {
        String url =
            Config().host + "/user/sendCode?type=f&phone=" + phone;
        final http.Response response = await http.get(url);
        var data = json.decode(response.body);
        print(data);
        var result = data['code'];
        if (result == 0) {
          Toast.toast(context, '验证码发送成功！注意查收！');
          _tgo();
        } else {
          Toast.toast(context, data['msg']);
        }
      } else {
        Toast.toast(context, '请输入11位手机号！');
      }
    }
  }

  _forgetPasswordAction() async {
    String phone = _phonecontroller.text;
    String password = _passwordcontrollerForgetPassword.text;
    String code = _codecontrollerForgetPassword.text;
    if (_checkPhone(phone) && _checkPassword(password) && _checkCode(code)) {
      String url = Config().host + "/user/changePasswordCode";
      String datax = json.encode({
        'phone': _phonecontroller.text,
        'password': _passwordcontrollerForgetPassword.text,
        'code': _codecontrollerForgetPassword.text
      });
      print(datax);
      final http.Response response = await http.post(url, body: datax);
      var data = json.decode(response.body);
      print(data);
      var result = data['code'];
      if (result == 0) {
        Toast.toast(context, '密码已重置！请用新密码登陆');
        setState(() {
          _forgetPassword = false;
          _loginTitle = '登 陆';
          _login = true;
        });
      } else {
        Toast.toast(context, data['msg']);
      }
    }
  }

  @override
  void dispose() {
    _ct?.cancel();
    _ct = null;
    super.dispose();
  }

  _loginAction() async {
    String phone = _phonecontroller.text;
    String password = _passwordcontroller.text;
    if (_checkPhone(phone) && _checkPassword(password)) {
      String url = Config().host + "/user/login";
      String datax = json.encode({'phone': phone, 'password': password});
      print(datax);
      final http.Response response = await http.post(url, body: datax);
      var data = json.decode(response.body);
      print(data['msg']);
      var result = data['code'];
      if (result == 0) {
        await LocalStorage().set("token", data['data']['token']);
        await LocalStorage().set("userId", data['data']['id'].toString());
        await LocalStorage().set("phoneLogin", _phonecontroller.text);
        Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => Index()),
            (route) => route == null);
      } else {
        Toast.toast(context, data['msg']);
      }
    }
  }

  bool _checkCode(String code) {
    if (code != null && code.length == 4) {
      return true;
    }
    Toast.toast(context, '请输入4位数字验证码');
    return false;
  }

  bool _checkPassword(String password) {
    if (password != null && password.length > 5) {
      return true;
    }
    Toast.toast(context, '请输入6位及以上密码');
    return false;
  }

  bool _checkPhone(String phone) {
    if (phone != null && phone.length == 11) {
      return true;
    }
    Toast.toast(context, '请输入11位正确的手机号');
    return false;
  }

  Widget _loginW() {
    return Column(
      children: <Widget>[
        Container(
          padding: EdgeInsets.only(top: 80, bottom: 80),
          width: 50,
          child: Image.asset('img/h.png'),
        ),
        Container(
          padding: EdgeInsets.only(left: 20, right: 20, bottom: 30),
          child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(30.0)),
                boxShadow: <BoxShadow>[
                  new BoxShadow(
                    color: Colors.black45,
                    blurRadius: 2.0,
                    offset: Offset(1.0, 3.0),
                  ),
                ],
              ),
              child: Container(
                padding: EdgeInsets.only(left: 25, right: 25),
                child: TextField(
                  controller: _phonecontroller,
                  keyboardType: TextInputType.phone,
                  decoration: new InputDecoration(
                      hintText: '请输入手机号', border: InputBorder.none),
                ),
              )),
        ),
        Container(
          padding: EdgeInsets.only(left: 20, right: 20, bottom: 50),
          child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(30.0)),
                boxShadow: <BoxShadow>[
                  new BoxShadow(
                    color: Colors.black45,
                    blurRadius: 2.0,
                    offset: Offset(1.0, 3.0),
                  ),
                ],
              ),
              child: Container(
                padding: EdgeInsets.only(left: 25, right: 25),
                child: TextField(
                  controller: _passwordcontroller,
                  keyboardType: TextInputType.visiblePassword,
                  obscureText: true,
                  decoration: new InputDecoration(
                      hintText: '请输入密码', border: InputBorder.none),
                ),
              )),
        ),
        Container(
          padding: EdgeInsets.only(left: 20, right: 20, bottom: 30),
          child: Container(
            decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [
                  Color.fromARGB(255, 16 + 14, 16 * 6 + 15, 250),
                  Color.fromARGB(255, 16 * 4 + 2, 16 * 10 + 1, 250),
                ]),
                borderRadius: BorderRadius.all(Radius.circular(30.0)),
                boxShadow: <BoxShadow>[
                  new BoxShadow(
                    color: Colors.black45,
                    blurRadius: 2.0,
                    offset: Offset(1.0, 3.0),
                  ),
                ]),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                _loginAction();
              },
              child: Container(
                width: double.infinity,
                height: 45,
                child: Center(
                  child: Text(
                    '登 陆',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.only(right: 30),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  setState(() {
                    _loginTitle = '找回密码';
                    _forgetPassword = true;
                  });
                },
                child: Container(
                  child: Text(
                    '忘记密码?',
                    style: TextStyle(color: Colors.blueAccent, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _registerW() {
    return Column(
      children: <Widget>[
        Container(
          padding: EdgeInsets.only(top: 60, bottom: 60),
          width: 50,
          child: Image.asset('img/h.png'),
        ),
        Container(
          padding: EdgeInsets.only(left: 20, right: 20, bottom: 30),
          child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(30.0)),
                boxShadow: <BoxShadow>[
                  new BoxShadow(
                    color: Colors.black45,
                    blurRadius: 2.0,
                    offset: Offset(1.0, 3.0),
                  ),
                ],
              ),
              child: Container(
                padding: EdgeInsets.only(left: 25, right: 25),
                child: TextField(
                  controller: _phonecontroller,
                  keyboardType: TextInputType.phone,
                  decoration: new InputDecoration(
                      hintText: '请输入手机号', border: InputBorder.none),
                ),
              )),
        ),
        Container(
          padding: EdgeInsets.only(left: 20, right: 20, bottom: 30),
          child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(30.0)),
                boxShadow: <BoxShadow>[
                  new BoxShadow(
                    color: Colors.black45,
                    blurRadius: 2.0,
                    offset: Offset(1.0, 3.0),
                  ),
                ],
              ),
              child: Container(
                padding: EdgeInsets.only(left: 25, right: 25),
                child: TextField(
                  controller: _passwordcontrollerRegister,
                  keyboardType: TextInputType.visiblePassword,
                  obscureText: true,
                  decoration: new InputDecoration(
                      hintText: '请输入密码', border: InputBorder.none),
                ),
              )),
        ),
        Container(
          padding: EdgeInsets.only(left: 20, right: 20, bottom: 50),
          child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(30.0)),
                boxShadow: <BoxShadow>[
                  new BoxShadow(
                    color: Colors.black45,
                    blurRadius: 2.0,
                    offset: Offset(1.0, 3.0),
                  ),
                ],
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.only(left: 25, right: 25),
                      child: TextField(
                        controller: _codecontrollerRegister,
                        keyboardType: TextInputType.number,
                        decoration: new InputDecoration(
                            hintText: '请输入验证码', border: InputBorder.none),
                      ),
                    ),
                  ),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      _sendCodeRegister();
                    },
                    child: Container(
                      height: 40,
                      margin: EdgeInsets.only(right: 3),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [
                          Color.fromARGB(255, 16 + 14, 16 * 6 + 15, 250),
                          Color.fromARGB(255, 16 * 4 + 2, 16 * 10 + 1, 250),
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
                      width: 120,
                      child: Center(
                        child: Text(
                          _sc,
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              )),
        ),
        Container(
          padding: EdgeInsets.only(left: 20, right: 20, bottom: 30),
          child: Container(
            decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [
                  Color.fromARGB(255, 16 + 14, 16 * 6 + 15, 250),
                  Color.fromARGB(255, 16 * 4 + 2, 16 * 10 + 1, 250),
                ]),
                borderRadius: BorderRadius.all(Radius.circular(30.0)),
                boxShadow: <BoxShadow>[
                  new BoxShadow(
                    color: Colors.black45,
                    blurRadius: 2.0,
                    offset: Offset(1.0, 3.0),
                  ),
                ]),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                _registerAction();
              },
              child: Container(
                width: double.infinity,
                height: 45,
                child: Center(
                  child: Text(
                    '注 册',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _forgetPasswordW() {
    return Column(
      children: <Widget>[
        Container(
          padding: EdgeInsets.only(top: 60, bottom: 60),
          width: 50,
          child: Image.asset('img/h.png'),
        ),
        Container(
          padding: EdgeInsets.only(left: 20, right: 20, bottom: 30),
          child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(30.0)),
                boxShadow: <BoxShadow>[
                  new BoxShadow(
                    color: Colors.black45,
                    blurRadius: 2.0,
                    offset: Offset(1.0, 3.0),
                  ),
                ],
              ),
              child: Container(
                padding: EdgeInsets.only(left: 25, right: 25),
                child: TextField(
                  controller: _phonecontroller,
                  keyboardType: TextInputType.phone,
                  decoration: new InputDecoration(
                      hintText: '请输入手机号', border: InputBorder.none),
                ),
              )),
        ),
        Container(
          padding: EdgeInsets.only(left: 20, right: 20, bottom: 30),
          child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(30.0)),
                boxShadow: <BoxShadow>[
                  new BoxShadow(
                    color: Colors.black45,
                    blurRadius: 2.0,
                    offset: Offset(1.0, 3.0),
                  ),
                ],
              ),
              child: Container(
                padding: EdgeInsets.only(left: 25, right: 25),
                child: TextField(
                  controller: _passwordcontrollerForgetPassword,
                  keyboardType: TextInputType.visiblePassword,
                  obscureText: true,
                  decoration: new InputDecoration(
                      hintText: '请输入新密码', border: InputBorder.none),
                ),
              )),
        ),
        Container(
          padding: EdgeInsets.only(left: 20, right: 20, bottom: 50),
          child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(30.0)),
                boxShadow: <BoxShadow>[
                  new BoxShadow(
                    color: Colors.black45,
                    blurRadius: 2.0,
                    offset: Offset(1.0, 3.0),
                  ),
                ],
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.only(left: 25, right: 25),
                      child: TextField(
                        controller: _codecontrollerForgetPassword,
                        keyboardType: TextInputType.number,
                        decoration: new InputDecoration(
                            hintText: '请输入验证码', border: InputBorder.none),
                      ),
                    ),
                  ),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      _sendCodeForgetPassword();
                    },
                    child: Container(
                      height: 40,
                      margin: EdgeInsets.only(right: 3),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [
                          Color.fromARGB(255, 16 + 14, 16 * 6 + 15, 250),
                          Color.fromARGB(255, 16 * 4 + 2, 16 * 10 + 1, 250),
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
                      width: 120,
                      child: Center(
                        child: Text(
                          _sc,
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              )),
        ),
        Container(
          padding: EdgeInsets.only(left: 20, right: 20, bottom: 30),
          child: Container(
            decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [
                  Color.fromARGB(255, 16 + 14, 16 * 6 + 15, 250),
                  Color.fromARGB(255, 16 * 4 + 2, 16 * 10 + 1, 250),
                ]),
                borderRadius: BorderRadius.all(Radius.circular(30.0)),
                boxShadow: <BoxShadow>[
                  new BoxShadow(
                    color: Colors.black45,
                    blurRadius: 2.0,
                    offset: Offset(1.0, 3.0),
                  ),
                ]),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                _forgetPasswordAction();
              },
              child: Container(
                width: double.infinity,
                height: 45,
                child: Center(
                  child: Text(
                    '提 交',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.only(right: 30),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  setState(() {
                    _loginTitle = '登 陆';
                    _forgetPassword = false;
                    _login = true;
                  });
                },
                child: Container(
                  child: Text(
                    '返回登陆',
                    style: TextStyle(color: Colors.blueAccent, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Container(
      child: Column(
        children: <Widget>[
          Container(
            color: Colors.white,
            padding: EdgeInsets.only(top: 40),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    setState(() {
                      _forgetPassword = false;
                      _login = true;
                      _loginTitle = '登 陆';
                    });
                  },
                  child: Container(
                    child: Column(
                      children: <Widget>[
                        Container(
                          padding: EdgeInsets.only(bottom: 10),
                          child: Text(
                            _loginTitle,
                            style: TextStyle(
                                fontSize: 20,
                                color: _login
                                    ? Colors.blueAccent
                                    : Colors.black45),
                          ),
                        ),
                        Container(
                          height: 4,
                          width: 25,
                          decoration: new BoxDecoration(
                            color: _login ? Colors.blueAccent : Colors.black12,
                            borderRadius:
                                BorderRadius.all(Radius.circular(10.0)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    setState(() {
                      _forgetPassword = false;
                      _login = false;
                      _loginTitle = '登 陆';
                    });
                  },
                  child: Container(
                    child: Column(
                      children: <Widget>[
                        Container(
                          padding: EdgeInsets.only(bottom: 10),
                          child: Text(
                            '注 册',
                            style: TextStyle(
                                fontSize: 20,
                                color: !_login
                                    ? Colors.blueAccent
                                    : Colors.black45),
                          ),
                        ),
                        Container(
                          height: 4,
                          width: 25,
                          decoration: new BoxDecoration(
                            color: !_login ? Colors.blueAccent : Colors.black12,
                            borderRadius:
                                BorderRadius.all(Radius.circular(10.0)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
              child: new ListView(children: <Widget>[
            Container(
              width: double.infinity,
              color: Color.fromARGB(255, 250, 250, 250),
              child: _forgetPassword
                  ? _forgetPasswordW()
                  : _login ? _loginW() : _registerW(),
            ),
          ])),
        ],
      ),
    ));
  }
}
