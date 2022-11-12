import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speedtest/connection/db_connection.dart';
import 'package:flutter_speedtest/model/dataspeedModel.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:speed_test_dart/classes/classes.dart';
import 'package:speed_test_dart/speed_test_dart.dart';
import 'package:lottie/lottie.dart';

class mainScreen extends StatefulWidget {
  const mainScreen({super.key});

  @override
  State<mainScreen> createState() => _mainScreenState();
}

class _mainScreenState extends State<mainScreen> {
  SpeedTestDart tester = SpeedTestDart();
  List<Server> bestServersList = [];

  // All Variable
  double downloadRate = 0;
  double uploadRate = 0;
  bool readyToTest = false;
  bool loadingDownload = false;
  bool loadingUpload = false;
  String googleApikey = "AIzaSyBvJaPeqmGdxeJlxfDwDyNmjj1h1ZD9_bg";
  double latitude = -7.285081;
  double longitude = 112.781237;
  String address = "";


  Future<void> setBestServers() async {
    final settings = await tester.getSettings();
    final servers = settings.servers;

    final _bestServersList = await tester.getBestServers(
      servers: servers,
    );

    setState(() {
      bestServersList = _bestServersList;
      readyToTest = true;
    });
  }

  Future<void> _testDownloadSpeed() async {
    setState(() {
      loadingDownload = true;
    });
    final _downloadRate =
        await tester.testDownloadSpeed(servers: bestServersList);
    setState(() {
      downloadRate = _downloadRate;

      loadingDownload = false;
    });
  }

  Future<void> _testUploadSpeed() async {
    setState(() {
      loadingUpload = true;
    });

    final _uploadRate = await tester.testUploadSpeed(servers: bestServersList);

    setState(() {
      uploadRate = _uploadRate;
      loadingUpload = false;
    });
  }

  Future<void> _insertData(String downloadRate, String uploadRate) async {
    var _id = mongo.ObjectId();
    DateTime timestamp = DateTime.now();
    timestamp.millisecondsSinceEpoch;
    final data = DataspeedModel(
        id: _id,
        timestamp: timestamp,
        downloadRate: downloadRate,
        uploadRate: uploadRate);
    var result = await MongoDatabase.insert(data);
  }


  convertToAddress(double lat, double long, String apikey) async {
    Dio dio = Dio(); //initilize dio package
    String apiurl =
        "https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$long&key=$apikey";

    Response response = await dio.get(apiurl); //send get request to API URL

    if (response.statusCode == 200) {
      //if connection is successful
      Map data = response.data; //get response data
      if (data["status"] == "OK") {
        //if status is "OK" returned from REST API
        if (data["results"].length > 0) {
          //if there is atleast one address
          Map firstresult = data["results"][0]; //select the first address

          address = firstresult["formatted_address"]; //get the address

          //you can use the JSON data to get address in your own format

          setState(() {
            //refresh UI
          });
        }
      } else {
        print(data["error_message"]);
      }
    } else {
      print("error while fetching geoconding data");
    }
  }

    @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setBestServers();
    });
    convertToAddress(latitude, longitude, googleApikey);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Speed Test App'),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Download Test:',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              if (loadingDownload)
                Column(
                  children: [
                    Lottie.asset(
                      'asset/126511-speed-blue-braga.json',
                      repeat: true,
                      animate: true,
                      width: 200,
                      height: 200,
                    ),
                    const Text('Testing download speed...'),
                  ],
                )
              // Column(
              //   children: const [
              //     CircularProgressIndicator(),
              //     SizedBox(
              //       height: 10,
              //     ),
              //     Text('Testing download speed...'),
              //   ],
              // )
              else
                Text('Download rate  ${downloadRate.toStringAsFixed(2)} Mb/s'),
              const SizedBox(height: 20),
              // ElevatedButton(
              //   style: ElevatedButton.styleFrom(
              //     backgroundColor: readyToTest && !loadingDownload
              //         ? Colors.blue
              //         : Colors.grey,
              //   ),
              //   onPressed: loadingDownload
              //       ? null
              //       : () async {
              //           if (!readyToTest || bestServersList.isEmpty) return;
              //           await _testDownloadSpeed();
              //         },
              //   child: const Text('Start'),
              // ),
              const Text(
                'Upload Test:',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              if (loadingUpload)
                Column(
                  children: [
                    Lottie.asset(
                      'asset/126532-speed-green-braga.json',
                      repeat: true,
                      animate: true,
                      width: 200,
                      height: 200,
                    ),
                    const Text('Testing upload speed...'),
                  ],
                )
              // Column(
              //   children: const [
              //     CircularProgressIndicator(),
              //     SizedBox(height: 10),
              //     Text('Testing upload speed...'),
              //   ],
              // )
              else
                Text('Upload rate ${uploadRate.toStringAsFixed(2)} Mb/s'),
              const SizedBox(
                height: 30,
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: readyToTest ? Colors.blue : Colors.grey,
                ),
                onPressed: loadingDownload && loadingUpload
                    ? null
                    : () async {
                        if (!readyToTest || bestServersList.isEmpty) return;
                        await _testDownloadSpeed();
                        await _testUploadSpeed();
                        _insertData(
                            downloadRate.toString(), uploadRate.toString());
                      },
                child: const Text('Start'),
              ),

              // Location UI
              const Text(
                'Latitude',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text("$latitude"),
              const Text(
                'Longitude',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text("$longitude"),
              const Text(
                'Address',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text("$address", ),

            ],
          ),
        ),
      ),
    );
  }
}
