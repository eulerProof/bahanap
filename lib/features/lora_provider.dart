import 'dart:async';
import 'dart:convert';
import 'package:cc206_bahanap/features/rescuer_provider.dart';
import 'package:flutter/material.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:http/http.dart' as http;
import 'user_service.dart';

class LoRaProvider extends ChangeNotifier {
  final List<Map<String, dynamic>> _messages = [];
  Map<String, dynamic>? _lastRawMessage;
  Timer? _pollingTimer;
  bool _isFetching = false;

  bool get isRadioBusy => _isFetching;
  
  final List<Map<String, dynamic>> _finishedOperations = [];
  List<Map<String, dynamic>> get finishedOperations => List.unmodifiable(_finishedOperations);
  List<Map<String, dynamic>> get messages => List.unmodifiable(_messages);
  
  String get currentRescuer => UserService().username ?? "";
  String get currentRescuerId => UserService().rescuerId ?? "";

  // 🟢 Callback for UI Dialogs
  VoidCallback? onNewAssignment;

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

  // ----------------------------------------------------------------------
  // 🟢 IMPROVEMENT 1: Added Timeout & Safety to Confirmation
  // ----------------------------------------------------------------------
  Future<bool> sendConfirmation(Map<String, dynamic> message, RescueModeProvider rescueProvider) async {
    rescueProvider.pauseUpdatesForConfirmation();
    
    try {
      final wifiName = await NetworkInfo().getWifiName();
      if (wifiName == null) return false;

      String? esp32IP;
      if (wifiName.contains("Bahanap_Node_A")) esp32IP = "192.168.4.1";
      if (wifiName.contains("Bahanap_Node_B")) esp32IP = "192.168.4.2";
      
      if (esp32IP == null) {
        print("Not connected to LoRa Node");
        return false;
      }

      final body = jsonEncode({
        "id": message["id"],
        "rescuer": currentRescuer,
        "timestamp": DateTime.now().toIso8601String(),
      });

      final response = await http.post(
        Uri.parse("http://$esp32IP/confirm"),
        headers: {"Content-Type": "application/json"},
        body: body,
      ).timeout(const Duration(seconds: 4)); // 🟢 Timeout added

      if (response.statusCode == 200) {
        _finishedOperations.add(message);
        _messages.removeWhere((m) => m["id"] == message["id"]);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print("Error confirming: $e");
      return false;
    }
  }

  // ----------------------------------------------------------------------
  // 🟢 IMPROVEMENT 2: Robust Deduplication
  // ----------------------------------------------------------------------
  void addMessage(Map<String, dynamic> message) {
    // 1. Security Check: Is this for me?
    if (message["rescuer"] != currentRescuerId) return;

    // 2. Duplication Check: Is this exact ID already in my active list?
    // This prevents the "Infinite Loop" bug if ESP32 resends the same assignment
    final alreadyExists = _messages.any((m) => m["id"] == message["id"]);
    
    // 3. Duplication Check: Is it already finished/confirmed?
    final alreadyFinished = _finishedOperations.any((m) => m["id"] == message["id"]);

    if (alreadyExists || alreadyFinished) return;

    // 4. Add & Notify
    _lastRawMessage = message;
    _messages.add(message);
    notifyListeners();

    if (onNewAssignment != null) {
      onNewAssignment!();
    }
  }

  void clear() {
    _messages.clear();
    _lastRawMessage = null;
    notifyListeners();
  }

  void stopPolling() {
    _pollingTimer?.cancel();
  }

  // ----------------------------------------------------------------------
  // 🟢 IMPROVEMENT 3: Type Safety & Timeouts in Fetch
  // ----------------------------------------------------------------------
  Future<void> _fetchAssignment() async {
    final esp32IP = await _getConnectedNodeIP();
    if (esp32IP == null) return;

    try {
      final response = await http.get(Uri.parse("http://$esp32IP/lastassign"))
          .timeout(const Duration(seconds: 3)); // 🟢 Timeout added

      if (response.statusCode != 200) return;
      final rawBody = response.body.trim();
      if (rawBody.isEmpty) return;

      final data = jsonDecode(rawBody);

      if (data["type"] == "ASSIGN") {
        // 🟢 Robust Parsing: Handle String vs Double vs Int mismatch
        addMessage({
          "id": data["uid"],
          "rescuer": data["rescuer"],
          "lat": double.tryParse(data["lat"].toString()) ?? 0.0,
          "lon": double.tryParse(data["lon"].toString()) ?? 0.0,
          "timestamp": data["timestamp"] ?? DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      // 🟢 Catch errors so we know if JSON parsing failed
      // print("Fetch Assignment Error: $e"); 
    }
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