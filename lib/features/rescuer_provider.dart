import 'dart:async';
import 'dart:convert';
import 'package:cc206_bahanap/features/lora_provider.dart';
import 'package:cc206_bahanap/features/user_service.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:network_info_plus/network_info_plus.dart';
import 'package:provider/provider.dart';

class RescueModeProvider extends ChangeNotifier {
  // 🟢 STATE VARIABLES
  bool _isRescueModeOn = false;
  bool _isPausedForConfirmation = false; // 🟢 Safety Flag
  StreamSubscription<Position>? _locationStream;
  DateTime? _lastSentTime; 
  
  // 🟢 CONFIGURATION
  // Throttle: Only send data every 15 seconds to keep bandwidth open
  final Duration _throttleDuration = const Duration(seconds: 8);

  bool get isRescueModeOn => _isRescueModeOn;
  String get currentRescuer => UserService().username ?? "";

  // ---------------- ENABLE / DISABLE TOGGLE -----------------
  void toggleRescueMode(BuildContext context) {
    _isRescueModeOn = !_isRescueModeOn;

    if (_isRescueModeOn) {
      _startLocationUpdates(context);
    } else {
      _stopLocationUpdates();
    }
    notifyListeners();
  }

  void stopRescueMode() {
    _isRescueModeOn = false;
    _stopLocationUpdates();
    notifyListeners();
  }

  // ------------------- STOP LOGIC ----------------------
  void _stopLocationUpdates() {
    _locationStream?.cancel();
    _locationStream = null;
    print("Rescue Mode: Stopped.");
  }

  // ------------------- PAUSE LOGIC (Called by LoRaProvider) ----------------------
  void pauseUpdatesForConfirmation() {
    _isPausedForConfirmation = true;
    print("Rescue Mode: Pausing updates for 10s to allow Confirmation...");
    
    Future.delayed(const Duration(seconds: 10), () {
      _isPausedForConfirmation = false;
      print("Rescue Mode: Resuming updates.");
    });
  }

  // ------------------ START STREAMING ----------------------
  Future<void> _startLocationUpdates(BuildContext context) async {
    print("Rescue Mode: Starting...");
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied) return;
    }

   _locationStream?.cancel();

    _locationStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((Position pos) {
      
      // 🟢 1. GET TRAFFIC LIGHT STATUS
      // We look up the LoRaProvider to see if it's busy fetching
      // listen: false because we just want to check the value, not rebuild UI
      final isLoRaBusy = Provider.of<LoRaProvider>(context, listen: false).isRadioBusy;

      if (isLoRaBusy) {
        print("Rescue Mode: Radio is busy fetching assignment. Skipping upload.");
        return; // 🛑 STOP. Do not interrupt the fetch.
      }

      // 🟢 2. CHECK 8-SECOND INTERVAL
      final now = DateTime.now();
      if (_lastSentTime == null || now.difference(_lastSentTime!) > _throttleDuration) {
        _lastSentTime = now;
        _sendRescuerLocation(pos);
      } 
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
      if (wifiName.contains("Bahanap_Node_A")) esp32IP = "192.168.4.1";
      if (wifiName.contains("Bahanap_Node_B")) esp32IP = "192.168.4.2";
      
      if (esp32IP == null) return;

      final payload = {
        "type": "RESCUER_LOCATION",
        "latitude": pos.latitude,
        "longitude": pos.longitude,
        "timestamp": DateTime.now().toUtc().toIso8601String(),
        "uid": currentRescuer
      };

      // 🟢 SHORT TIMEOUT
      // If ESP32 is busy receiving assignments, drop this packet immediately
      final response = await http.post(
        Uri.parse("http://$esp32IP/message"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 2));

      print("Rescue mode sent => ${response.statusCode}");
    } catch (e) {
      print("Rescue mode error (Packet Dropped): $e");
    }
  }

  @override
  void dispose() {
    _stopLocationUpdates();
    super.dispose();
  }
}