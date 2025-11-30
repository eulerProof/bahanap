import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  String? username;
  String? rescuerId;
  Future<String> fetchUsername() async {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    return "Victim";
  }

  try {
    final snapshot = await FirebaseFirestore.instance
        .collection('profiles')
        .doc(user.uid)
        .get();

    username = snapshot.data()?['Name'];
    rescuerId = snapshot.data()?['rescuerId'];
    return username ?? "No user found";
  } catch (e) {
    print("Failed to fetch username: $e");
    return "No user found";
  }
}

void clear() {
    username = null;  // <-- CLEAR during logout
  }
}