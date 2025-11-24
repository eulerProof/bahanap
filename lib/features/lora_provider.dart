import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:http/http.dart' as http;
import 'user_service.dart'; 
class LoRaProvider extends ChangeNotifier {
  final List<Map<String, dynamic>> _messages = [];
  Map<String, dynamic>? _lastRawMessage;
  Timer? _pollingTimer;

  List<Map<String, dynamic>> get messages => List.unmodifiable(_messages);
  String get currentRescuer => UserService().username ?? ""; // <--- store the user's username

  /// Adds a new message safely
  bool _isFetching = false;

void startPolling({int seconds = 3}) {
  _pollingTimer?.cancel();
  _pollingTimer = Timer.periodic(Duration(seconds: seconds), (_) async {
    if (!_isFetching) {
      _isFetching = true;
      await fetchLocationFromModule();
      _isFetching = false;
    }
  });
}

void addMessage(Map<String, dynamic> message) {
  // Only accept messages for this rescuer
  if (message["rescuer"] != currentRescuer) {
    return; 
  }
  // Prevent duplicates
  if (_lastRawMessage != null &&
      _lastRawMessage!["id"] == message["id"] &&
      (_lastRawMessage!["lat"] - message["lat"]).abs() < 0.00001 &&
      (_lastRawMessage!["lon"] - message["lon"]).abs() < 0.00001 &&
      _lastRawMessage!["rescuer"] == message["rescuer"]) {
    return;
  }

  _lastRawMessage = message;

  _messages.add(message);
  notifyListeners();
}
  void clear() {
    _messages.clear();
    _lastRawMessage = null;
    notifyListeners();
  }

  /// ------------------- 🟢 Polling logic -------------------
  

  void stopPolling() {
    _pollingTimer?.cancel();
  }

  Future<void> fetchLocationFromModule() async {
    try {
      final wifiName = await NetworkInfo().getWifiName();

      if (wifiName == null ||
          (!wifiName.contains("Bahanap_Node_A") &&
              !wifiName.contains("Bahanap_Node_B"))) {
        return;
      }

      String? esp32IP;
      if (wifiName.contains("Bahanap_Node_A")) {
        esp32IP = "192.168.4.1";
      } else if (wifiName.contains("Bahanap_Node_B")) {
        esp32IP = "192.168.4.2";
      }

      final response = await http.get(Uri.parse('http://$esp32IP/lastmessage'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Convert to normalized structure
        addMessage({
          "id": data["uid"] ?? "unknown",
          "rescuer": data["rescuer"] ?? "unknown",
          "lat": data["lat"]?.toDouble() ?? 0.0,
          "lon": data["lon"]?.toDouble() ?? 0.0,
          "timestamp": DateTime.now().toIso8601String(),
        });
      }
    } on SocketException catch (_) {
      // Handle no connection silently or log
    } catch (e) {
      print("Error fetching LoRa module: $e");
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }
}