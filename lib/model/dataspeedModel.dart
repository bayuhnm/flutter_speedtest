import 'package:meta/meta.dart';
import 'dart:convert';

import 'package:mongo_dart/mongo_dart.dart';

DataspeedModel dataspeedModelFromJson(String str) => DataspeedModel.fromJson(json.decode(str));

String dataspeedModelToJson(DataspeedModel data) => json.encode(data.toJson());

class DataspeedModel {
    DataspeedModel({
        required this.id,
        required this.timestamp,
        required this.downloadRate,
        required this.uploadRate,
        required this.latitude,
        required this.longitude,
        required this.address,
        required this.place,
        required this.venue,
        required this.device,
    });

    ObjectId id;
    DateTime timestamp;
    String downloadRate;
    String uploadRate;
    String latitude;
    String longitude;
    String address;
    String place;
    String venue;
    String device;

    factory DataspeedModel.fromJson(Map<String, dynamic> json) => DataspeedModel(
        id: json["_id"],
        timestamp: DateTime.parse(json["timestamp"]),
        downloadRate: json["downloadRate"],
        uploadRate: json["uploadRate"],
        latitude: json["latitude"],
        longitude: json["longitude"],
        address: json["address"],
        place: json["place"],
        venue: json["venue"],
        device: json["device"],
    );

    Map<String, dynamic> toJson() => {
        "_id": id,
        "timestamp": timestamp.toIso8601String(),
        "downloadRate": downloadRate,
        "uploadRate": uploadRate,
        "latitude": latitude,
        "longitude": longitude,
        "address": address,
        "place": place,
        "venue": venue,
        "device": device,
    };
}
