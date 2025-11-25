import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class UserRoleProvider extends ChangeNotifier {
  String _role = "";
  String get role => _role;
  String _id = "";
  String get id => _id;
  Future<void> loadUserRole() async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? "";
    if (uid.isEmpty) return;

    final doc = await FirebaseFirestore.instance
        .collection("profiles")
        .doc(uid)
        .get();

    if (doc.exists) {
      _role = doc["role"];
      if (_role == "Rescuer") {
        _id = doc["rescuerId"];
      } else {
        _id = doc["uid"];
      }
      notifyListeners();
    }
  }
}