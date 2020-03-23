import 'package:amap_location/amap_location.dart';
import 'package:flutter/material.dart';
import 'package:znjjwyz/pages/login.dart';
import 'package:znjjwyz/pages/version.dart';

//void main() => runApp(MyApp());

void main(){
  AMapLocationClient.setApiKey("ce9a29f515e246bc93fca7295bda2dcd");
  runApp(new MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Version(),
//      home: Login(),
    );
  }
}
