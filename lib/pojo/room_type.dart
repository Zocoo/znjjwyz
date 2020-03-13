class RoomType{

  int id;

  String name;

  int createAt;

  RoomType(){

  }

  RoomType.fromJson(Map<String,dynamic> json){
    id = json['id'];
    name = json['name'];
    createAt = json['createAt'];
  }

}
