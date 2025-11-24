import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class UserRoleProvider extends ChangeNotifier {
  String _role = "";
  String get role => _role;

  Future<void> loadUserRole() async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? "";
    if (uid.isEmpty) return;

    final doc = await FirebaseFirestore.instance
        .collection("profiles")
        .doc(uid)
        .get();

    if (doc.exists) {
      _role = doc["role"];
      notifyListeners();
    }
  }
}