import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  String? username;

  Future<void> fetchUsername() async {
    // Only fetch if not already fetched
    

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('profiles')
            .doc(user.uid)
            .get();

        username = snapshot.data()?['Name']; // Or 'username'
      } catch (e) {
        print("Failed to fetch username: $e");
      }
    }
  }
}