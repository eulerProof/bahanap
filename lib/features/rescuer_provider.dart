import 'dart:async';
import 'dart:convert';
import 'package:cc206_bahanap/features/user_service.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:network_info_plus/network_info_plus.dart';

class RescueModeProvider extends ChangeNotifier {
  bool _isRescueModeOn = false;

  bool _isPausedForConfirmation = false;
  String get currentRescuer => UserService().username ?? "";
  bool get isRescueModeOn => _isRescueModeOn;
  StreamSubscription<Position>? _locationStream;

  // ---------------- ENABLE / DISABLE RESCUE MODE -----------------
  void toggleRescueMode() {
    _isRescueModeOn = !_isRescueModeOn;

    if (_isRescueModeOn) {
      _startLocationUpdates();
    } else {
      _stopLocationUpdates();
    }

    notifyListeners();
  }

  // ------------------- STOP LOCATION STREAM ----------------------
  void _stopLocationUpdates() {
    _locationStream?.cancel();
    _locationStream = null;
  }
  void pauseUpdatesForConfirmation() {
    _isPausedForConfirmation = true;
    print("Rescue Mode: Pausing location updates for 10 seconds...");
    
    // Resume after 10 seconds (gives Admin 10 polling cycles to catch the message)
    Future.delayed(const Duration(seconds: 10), () {
      _isPausedForConfirmation = false;
      print("Rescue Mode: Resuming location updates.");
    });
  }
  // ------------------ START LOCATION STREAM ----------------------
  Future<void> _startLocationUpdates() async {
    LocationPermission perm = await Geolocator.requestPermission();
    if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
      print("Rescue mode: Location permission denied.");
      return;
    }

    _locationStream?.cancel();

    _locationStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((Position pos) {
      // 🟢 GUARD CLAUSE: If paused, do not send to ESP32
      if (_isPausedForConfirmation) {
        print("Rescue Mode: Location update skipped (Priority Message sending)");
        return; 
      }
      
      _sendRescuerLocation(pos);
    });
  }

  // -------------------- SEND TO ESP32 ----------------------------
  Future<void> _sendRescuerLocation(Position pos) async {
    try {
      final wifiName = await NetworkInfo().getWifiName();

      if (wifiName == null) {
        print("Rescue mode: Not connected to WiFi");
        return;
      }

      String? esp32IP;

      if (wifiName.contains("Bahanap_Node_A")) {
        esp32IP = "192.168.4.1";
      } else if (wifiName.contains("Bahanap_Node_B")) {
        esp32IP = "192.168.4.2";
      } else {
        print("Rescue mode: not connected to a LoRa node");
        return;
      }

      

      final payload = {
        "type": "RESCUER_LOCATION",
        "latitude": pos.latitude,      // CHANGED
        "longitude": pos.longitude,     // CHANGED
        "timestamp": DateTime.now().toUtc().toIso8601String(),
        "uid": currentRescuer
      };

      final response = await http.post(
        Uri.parse("http://$esp32IP/message"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      print("Rescue mode sent => ${response.statusCode}");
    } catch (e) {
      print("Rescue mode error: $e");
    }
  }

  @override
  void dispose() {
    _stopLocationUpdates();
    super.dispose();
  }
}