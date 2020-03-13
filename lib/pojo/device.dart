class Device {
  int id;

  String sn;

  String type;

  int lastHbAt;

  String userId;

  String remark;

  String wd;

  String sd;

  String power;

  Device() {}

  Device.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    sn = json['sn'];
    type = json['type'];
    userId = json['userId'];
    remark = json['remark'];
  }
}
