import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:cc206_bahanap/features/user_service.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:network_info_plus/network_info_plus.dart';


class SosPage extends StatefulWidget {
  const SosPage({super.key});

  @override
  State<SosPage> createState() => _SosPageState();
}

class _SosPageState extends State<SosPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Timer? _timer;
  late Animation<double> _opacity;
  StreamSubscription<Position>? _positionStreamSubscription;
  String _status = "Connecting...";
  String _username = "";
  String _coordinates = "";
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.2, end: 1.0).animate(_controller);
    _initializeSOS();
  }

  @override
  void dispose() {
    _controller.dispose();
    _positionStreamSubscription?.cancel();
    _timer?.cancel();
    super.dispose();
  }
  
  Future<void> _getUsername() async {
    final username = await UserService().fetchUsername();
    setState(() {
      _username = username;
    });
  }
  Future<void> _initializeSOS() async {
    await _getUsername();
    _startLocationUpdates();
  }
  Future<bool> requestLocationPermission() async {
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      print("Debug: Location permission denied.");
      return false;
    }
    return true;
  }
  // void _startSendingLocation() {
  //   _startLocationUpdates(); // Fetch once immediately
  //   _timer = Timer.periodic(const Duration(seconds: 5), (_) => _startLocationUpdates());
  // }
  Future<String> _getDeviceId() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    String deviceId;

    if (Theme.of(context).platform == TargetPlatform.android) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      deviceId = androidInfo.id;
    } else {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      deviceId = iosInfo.identifierForVendor!;
    }

    return deviceId;
  }

  void _startLocationUpdates() async {
    bool hasPermission = await requestLocationPermission();

    if (hasPermission) {
      await _positionStreamSubscription?.cancel();

      _positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).listen((Position position) async {
        try {
          setState(() {
            _coordinates = "${position.latitude}, ${position.longitude}";
          });
          String deviceId = await _getDeviceId();
          
          String? uid = FirebaseAuth.instance.currentUser?.uid;
          
          //Disabling Firestore for now to focus on module testing
          if (uid == null) {
            print("User  is not logged in. Sending to 'rescuees'.");
            // await _sendCoordinatesToFirestore(deviceId, position, "rescuees");
            _sendPostRequest(position, _username);
          } else {
            print(
                "User  is logged in. Sending to 'profiles' collection. UID: $uid");
            // await _sendCoordinatesToFirestore(uid, position, "profiles");
            _sendPostRequest(position, _username);
          }
        } catch (e) {
          print("Error sending coordinates: $e");
        }
      });
    } else {
      print("Location permission denied");
    }
  }

  Future<void> _sendCoordinatesToFirestore(
      String uid, Position position, String collection) async {
    try {
      String formattedLocation =
          "Lat: ${position.latitude}, Lon: ${position.longitude}";

      String docId = uid;

      await FirebaseFirestore.instance.collection(collection).doc(docId).set({
        "LiveCoordinates": formattedLocation,
        "timestamp": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print("Location sent to Firestore with docId: $docId");
    } catch (e) {
      print("Error updating location in Firestore: $e");
    }
  }
  Future<String> generateSosMid() async {
  // Get unique device ID
  DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  String deviceId;

  if (Theme.of(context).platform == TargetPlatform.android) {
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    deviceId = androidInfo.id;
  } else {
    IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
    deviceId = iosInfo.identifierForVendor!;
  }

  // Combine with current timestamp in milliseconds
  String mid = "${deviceId}_${DateTime.now().microsecondsSinceEpoch}";

  return mid;
}
  Future<void> _sendPostRequest(Position position, String id) async {
    try {
      final wifiName = await NetworkInfo().getWifiName();

      if (wifiName == null) {
        setState(() {
          _status = "Not connected to any WiFi network.";
        });
        return;
      }

      String? esp32IP;
      if (wifiName.contains("Bahanap_Node_A")) {
        esp32IP = "192.168.4.1";
      } else if (wifiName.contains("Bahanap_Node_B")) {
        esp32IP = "192.168.4.2";
      } else {
        setState(() {
          _status = "Not connected to a valid ESP32 node WiFi.";
        });
        return;
      }
      // Build JSON payload
    final sosMid = await generateSosMid();
    final payload = {
      "latitude": position.latitude,
      "longitude": position.longitude,
      "timestamp": DateTime.now().toUtc().toIso8601String(),
      "uid": id,
      "mid": sosMid
    };

    // Send JSON to ESP32
    final response = await http
        .post(
          Uri.parse('http://$esp32IP/message'),
          headers: {
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 8)); // Add timeout for safety
    
    // Update UI status
    setState(() {
      if (response.statusCode == 200) {
        _status = 'SOS Alert sent!';
      } else {
        _status = 'SOS Alert failed to send. Please try again.';
      }

      // After sending SOS
      Timer.periodic(Duration(seconds: 1), (timer) async {
        final ackResponse = await http.get(Uri.parse('http://$esp32IP/lastmessage'));
        if (ackResponse.statusCode == 200) {
          final data = jsonDecode(ackResponse.body);
          if (data['type'] == 'ACK' && data['mid'] == sosMid) {
            // ACK received
            setState(() {
              _status = 'SOS Alert received by base station!';
            });
            timer.cancel(); // stop polling
          }
        }
      });
    });
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xff1a4bff),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Center(
                child: Text(
                  'Emergency SOS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'SfPro',
                  ),
                ),
              ),
              Image.asset('assets/radar.gif'),
              AnimatedBuilder(
                animation: _opacity,
                builder: (context, child) {
                  return Opacity(
                    opacity: _opacity.value,
                    child: Text(
                      _status,
                      style: const TextStyle(
                        color: Color(0xff32ade6),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Gilroy',
                      ),
                    ),
                  );
                },
              ),
              AnimatedBuilder(
                animation: _opacity,
                builder: (context, child) {
                  return Opacity(
                    opacity: _opacity.value,
                    child: Text(
                      "Coordinates: $_coordinates",
                      style: const TextStyle(
                        color: Color(0xff32ade6),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Gilroy',
                      ),
                    ),
                  );
                },
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text(
                  'End',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'SfPro',
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
