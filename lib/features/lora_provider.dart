import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cc206_bahanap/features/rescuer_provider.dart';
import 'package:cc206_bahanap/features/user_role.dart';
import 'package:flutter/material.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'user_service.dart'; 
class LoRaProvider extends ChangeNotifier {
  final List<Map<String, dynamic>> _messages = [];
  Map<String, dynamic>? _lastRawMessage;
  Timer? _pollingTimer;
  
  final List<Map<String, dynamic>> _finishedOperations = [];
  List<Map<String, dynamic>> get finishedOperations => List.unmodifiable(_finishedOperations);
  List<Map<String, dynamic>> get messages => List.unmodifiable(_messages);
  String get currentRescuer => UserService().username ?? ""; // <--- store the user's username
  String get currentRescuerId => UserService().rescuerId ?? "";
  /// Adds a new message safely
  bool _isFetching = false;
  
void startPolling({int seconds = 3}) {
  _pollingTimer?.cancel();
  _pollingTimer = Timer.periodic(Duration(seconds: seconds), (_) async {
    if (!_isFetching) {
      _isFetching = true;
      await _fetchAssignment();
      _isFetching = false;
    }
  });
}

Future<bool> sendConfirmation(Map<String, dynamic> message, RescueModeProvider rescueProvider) async {
  rescueProvider.pauseUpdatesForConfirmation();
  try {
    final wifiName = await NetworkInfo().getWifiName();

    if (wifiName == null ||
        (!wifiName.contains("Bahanap_Node_A") &&
         !wifiName.contains("Bahanap_Node_B"))) {
      print("Not connected to any LoRa AP");
      return false;
    }

    String? esp32IP;
    if (wifiName.contains("Bahanap_Node_A")) esp32IP = "192.168.4.1";
    if (wifiName.contains("Bahanap_Node_B")) esp32IP = "192.168.4.2";

    final body = jsonEncode({
      "id": message["id"],
      "rescuer": currentRescuer,
      "timestamp": DateTime.now().toIso8601String(),
    });

    final response = await http.post(
      Uri.parse("http://$esp32IP/confirm"),
      headers: {"Content-Type": "application/json"},
      body: body,
    );

    if (response.statusCode == 200) {
      // Store in finished operations
      _finishedOperations.add(message);

      // Remove from messages list
      _messages.removeWhere((m) => m["id"] == message["id"]);
      notifyListeners();

      return true;
    }

    print("Failed confirmation: ${response.statusCode}");
    return false;
  } catch (e) {
    print("Error confirming: $e");
    return false;
  }
}
void addMessage(Map<String, dynamic> message) {
  // Only accept messages for this rescuer
  if (message["rescuer"] != currentRescuerId) {
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

  Future<void> _fetchAssignment() async {
  final esp32IP = await _getConnectedNodeIP();
  if (esp32IP == null) return;

  try {
    final response = await http.get(Uri.parse("http://$esp32IP/lastassign"));
    if (response.statusCode != 200) return;

    final data = jsonDecode(response.body);

    if (data["type"] == "ASSIGN") {
      addMessage({
        "id": data["uid"],
        "rescuer": data["rescuer"],
        "lat": data["lat"]?.toDouble() ?? 0.0,
        "lon": data["lon"]?.toDouble() ?? 0.0,
        "timestamp": data["timestamp"] ?? DateTime.now().toIso8601String(),
      });
    }
  } catch (_) {}
}
Future<String?> _getConnectedNodeIP() async {
  final wifiName = await NetworkInfo().getWifiName();
  if (wifiName == null) return null;

  if (wifiName.contains("Bahanap_Node_A")) return "192.168.4.1";
  if (wifiName.contains("Bahanap_Node_B")) return "192.168.4.2";

  return null;
}
  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }
}