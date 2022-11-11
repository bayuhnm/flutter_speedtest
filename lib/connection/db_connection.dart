import 'dart:developer';

import 'package:flutter_speedtest/model/dataspeedModel.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:flutter_speedtest/connection/constant.dart';


class MongoDatabase {
  static var db, userCollection;
  static connect() async{
    db = await Db.create(MONGO_CONN_URL);
    await db.open();
    inspect(db);
    userCollection = db.collection(USER_COLLECTION);
  }

  static Future<String> insert(DataspeedModel data) async {
    try{
      var result = await userCollection.insertOne(data.toJson());
      if (result.isSuccess) {
        return "Data berhasil terupload";
      } else {
        return "Gagal insert data";
      }
    } catch(e) {
      print(e.toString());
      return e.toString();
    }
  } 
}