// ignore_for_file: import_of_legacy_library_into_null_safe

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speedtest/connection/db_connection.dart';
import 'package:flutter_speedtest/model/dataspeedModel.dart';
import 'package:geocoding/geocoding.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:speed_test_dart/classes/classes.dart';
import 'package:speed_test_dart/speed_test_dart.dart';
import 'package:lottie/lottie.dart';
import 'package:geolocator/geolocator.dart';

class mainScreen extends StatefulWidget {
  const mainScreen({super.key});

  @override
  State<mainScreen> createState() => _mainScreenState();
}

class _mainScreenState extends State<mainScreen> {
  SpeedTestDart tester = SpeedTestDart();
  List<Server> bestServersList = [];

  // All Variable
  final formGlobalKey = GlobalKey<FormState>();
  double downloadRate = 0;
  double uploadRate = 0;
  bool readyToTest = false;
  bool loadingDownload = false;
  bool loadingUpload = false;
  bool loadingLocation = false;
  String googleApikey = "";
  double latitude = 0;
  double longitude = 0;
  String address = "";
  String? _currentAddress;
  Position? _currentPosition;
  TextEditingController placeController = TextEditingController();
  TextEditingController venueController = TextEditingController();
  TextEditingController deviceController = TextEditingController();

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

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Location services are disabled. Please enable the services')));
      return false;
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied')));
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Location permissions are permanently denied, we cannot request permissions.')));
      return false;
    }
    return true;
  }

  Future<void> _getCurrentPosition() async {
    setState(() {
      loadingLocation = true;
    });
    final hasPermission = await _handleLocationPermission();
    if (!hasPermission) return;
    await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
        .then((Position position) {
      setState(
        () => _currentPosition = position,
      );
      debugPrint('latlong = $position');
      _getAddressFromLatLng(_currentPosition!);
    }).catchError((e) {
      debugPrint(e);
    });
  }

  Future<void> _getAddressFromLatLng(Position position) async {
    await placemarkFromCoordinates(
            _currentPosition!.latitude, _currentPosition!.longitude)
        .then((List<Placemark> placemarks) {
      Placemark place = placemarks[0];
      setState(() {
        _currentAddress =
            '${place.street}, ${place.subLocality}, ${place.subAdministrativeArea}, ${place.postalCode}';
        latitude = position.latitude;
        longitude = position.longitude;
      });
      debugPrint('address = $_currentAddress');

      setState(() {
        loadingLocation = false;
      });
    }).catchError((e) {
      debugPrint(e);
    });
  }

  Future<void> _convertToAddress(String lat, String long, String apikey) async {
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

  Future<void> _insertData(
      String downloadRate,
      String uploadRate,
      String latitude,
      String longitude,
      String currentAddress,
      String place,
      String venue,
      String device) async {
    var _id = mongo.ObjectId();
    DateTime timestamp = DateTime.now();
    timestamp.millisecondsSinceEpoch;
    final data = DataspeedModel(
      id: _id,
      timestamp: timestamp,
      downloadRate: downloadRate,
      uploadRate: uploadRate,
      latitude: latitude,
      longitude: longitude,
      address: currentAddress,
      place: placeController.text,
      venue: venueController.text,
      device: deviceController.text,
    );
    debugPrint('Input data to MongoDB');
    var result = await MongoDatabase.insert(data);
  }

  String? get _errorText {
    final textPlace = placeController.value.text;
    final textVenue = venueController.value.text;
    final textDevice = placeController.value.text;

    if (textPlace.isEmpty) {
      return 'Form Place tidak boleh kosong';
    }
    if (textVenue.isEmpty) {
      return 'Form Venue tidak boleh kosong';
    }
    if (textDevice.isEmpty) {
      return 'Form Device tidak boleh kosong';
    }
    if (textPlace.isEmpty && textVenue.isEmpty && textDevice.isEmpty) {
      return 'Isi semua form';
    }
    return null;
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setBestServers();
    });
    // _convertToAddress(latitude, longitude, googleApikey);
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
        body: SingleChildScrollView(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  height: 20,
                ),
                SizedBox(
                  width: 300,
                  height: 50,
                  child: TextFormField(
                    controller: placeController,
                    decoration: InputDecoration(
                      labelText: "Place",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                SizedBox(
                  width: 300,
                  height: 50,
                  child: TextFormField(
                    controller: venueController,
                    decoration: InputDecoration(
                        labelText: "Venue", border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                SizedBox(
                  width: 300,
                  height: 50,
                  child: TextFormField(
                    controller: deviceController,
                    decoration: InputDecoration(
                        labelText: "Device", border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                const Text(
                    'Your Location:',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                if (loadingLocation)
                  Column(
                    children: const [
                      CircularProgressIndicator(),
                      SizedBox(height: 30),
                      Text('Getting location'),
                    ],
                  )
                else
                  // Location UI
                  
                const SizedBox(
                  height: 10,
                ),
                Center(
                  child: Column(
                    children: [
                      Text('LAT: ${_currentPosition?.latitude ?? ""}'),
                      Text('LNG: ${_currentPosition?.longitude ?? ""}'),
                      Text('ADDRESS: ${_currentAddress ?? ""}'),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
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
                else
                  Text(
                      'Download rate  ${downloadRate.toStringAsFixed(2)} Mb/s'),
                const SizedBox(height: 20),
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
                          await _getCurrentPosition();
                          await _testDownloadSpeed();
                          await _testUploadSpeed();
                          _insertData(
                            downloadRate.toString(),
                            uploadRate.toString(),
                            latitude.toString(),
                            longitude.toString(),
                            _currentAddress.toString(),
                            placeController.toString(),
                            venueController.toString(),
                            deviceController.toString(),
                          );
                        },
                  child: const Text('Start'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
