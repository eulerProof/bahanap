import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:device_info_plus/device_info_plus.dart';

class SosPage extends StatefulWidget {
  const SosPage({super.key});

  @override
  State<SosPage> createState() => _SosPageState();
}

class _SosPageState extends State<SosPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  StreamSubscription<Position>? _positionStreamSubscription;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.2, end: 1.0).animate(_controller);

    _startLocationUpdates();
  }

  @override
  void dispose() {
    _controller.dispose();
    _positionStreamSubscription?.cancel();
    super.dispose();
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
      StreamSubscription<Position>? positionStreamSubscription;

      positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).listen((Position position) async {
        try {
          String deviceId = await _getDeviceId();

          String? uid = FirebaseAuth.instance.currentUser?.uid;

          if (uid == null) {
            print("User  is not logged in. Sending to 'rescuees'.");
            await _sendCoordinatesToFirestore(deviceId, position, "rescuees");
          } else {
            print(
                "User  is logged in. Sending to 'profiles' collection. UID: $uid");
            await _sendCoordinatesToFirestore(uid, position, "profiles");
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
                    child: const Text(
                      'CONNECTING',
                      style: TextStyle(
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
