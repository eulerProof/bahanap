import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  String? username;

  Future<String> fetchUsername() async {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    return "No user found";
  }

  try {
    final snapshot = await FirebaseFirestore.instance
        .collection('profiles')
        .doc(user.uid)
        .get();

    username = snapshot.data()?['Name'];
    return username ?? "No user found";
  } catch (e) {
    print("Failed to fetch username: $e");
    return "No user found";
  }
}
}