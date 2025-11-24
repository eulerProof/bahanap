import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:http/http.dart' as http;

class LoRaProvider extends ChangeNotifier {
  final List<Map<String, dynamic>> _messages = [];
  Map<String, dynamic>? _lastRawMessage;
  Timer? _pollingTimer;

  List<Map<String, dynamic>> get messages => List.unmodifiable(_messages);

  /// Adds a new message safely
  void addMessage(Map<String, dynamic> message) {
    final newMessageJson = jsonEncode(message);

    if (_lastRawMessage != null &&
        jsonEncode(_lastRawMessage) == newMessageJson) return;

    _lastRawMessage = message;

    final msgId = message["id"];
    message["id"] = msgId;

    final index = _messages.indexWhere((m) => m["id"] == msgId);
    if (index == -1) {
      _messages.add(message);
    } else {
      _messages[index] = message;
    }

    notifyListeners();
  }

  void clear() {
    _messages.clear();
    _lastRawMessage = null;
    notifyListeners();
  }

  /// ------------------- 🟢 Polling logic -------------------
  void startPolling({int seconds = 3}) {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(Duration(seconds: seconds), (_) {
      fetchLocationFromModule();
    });
  }

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