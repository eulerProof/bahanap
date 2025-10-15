import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

final TextEditingController _emailController = TextEditingController();
final TextEditingController _nameController = TextEditingController();
final TextEditingController _phoneController = TextEditingController();
final String uid = FirebaseAuth.instance.currentUser!.uid;

Future<void> uploadProfile() async {
  final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  if (uid.isEmpty) {
    print("Error: User not logged in.");
    return;
  }

  final Map<String, dynamic> updatedData = {};

  if (_nameController.text.trim().isNotEmpty) {
    updatedData["Name"] = _nameController.text.trim();
  }
  if (_emailController.text.trim().isNotEmpty) {
    updatedData["email"] = _emailController.text.trim();
  }
  if (_phoneController.text.trim().isNotEmpty) {
    updatedData["PhoneNumber"] = _phoneController.text.trim();
  }

  if (updatedData.isEmpty) {
    print("No changes to update.");
    return;
  }

  try {
    await FirebaseFirestore.instance.collection("profiles").doc(uid).set(
          updatedData,
          SetOptions(merge: true),
        );
    _nameController.clear();
    _emailController.clear();
    _phoneController.clear();
    print("Profile updated successfully");
  } catch (e) {
    print("Error updating profile: $e");
  }
}

class _EditProfilePageState extends State<EditProfilePage> {
  String? selectedRole;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            fontSize: 26,
            fontFamily: 'SfPro',
            color: Colors.black,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: CircleAvatar(
                  radius: 70,
                  backgroundImage: AssetImage('assets/images/dgfdfdsdsf2.jpg'),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 15),
                child: TextFormField(
                  controller: _nameController,
                  maxLength: 20,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: const BorderSide(color: Color(0xFFDEDEDE)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: const BorderSide(color: Colors.blue),
                    ),
                    labelText: 'Name',
                    labelStyle: const TextStyle(
                      color: Color(0xFFAFAFAF),
                      fontSize: 15,
                    ),
                    counterText: '',
                  ),
                ),
              ),
              // Padding(
              //   padding: const EdgeInsets.only(top: 15),
              //   child: DropdownButtonFormField<String>(
              //     decoration: InputDecoration(
              //       border: OutlineInputBorder(
              //         borderRadius: BorderRadius.circular(15),
              //       ),
              //       enabledBorder: OutlineInputBorder(
              //         borderRadius: BorderRadius.circular(15),
              //         borderSide: const BorderSide(color: Color(0xFFDEDEDE)),
              //       ),
              //       focusedBorder: OutlineInputBorder(
              //         borderRadius: BorderRadius.circular(15),
              //         borderSide: const BorderSide(color: Colors.blue),
              //       ),
              //       labelText: 'Role',
              //       labelStyle: const TextStyle(
              //         color: Color(0xFFAFAFAF),
              //         fontSize: 15,
              //       ),
              //     ),
              //     value: selectedRole,
              //     items: const [
              //       DropdownMenuItem(
              //           value: 'rescuer',
              //           child: Text(
              //             'Rescuer',
              //             style: TextStyle(
              //                 color: Color.fromARGB(255, 34, 34, 34),
              //                 fontSize: 15,
              //                 fontFamily: 'SfPro'),
              //           )),
              //       DropdownMenuItem(
              //           value: 'user',
              //           child: Text(
              //             'User',
              //             style: TextStyle(
              //                 color: Color.fromARGB(255, 34, 34, 34),
              //                 fontSize: 15,
              //                 fontFamily: 'SfPro'),
              //           )),
              //     ],
              //     onChanged: (value) {
              //       setState(() {
              //         selectedRole = value;
              //       });
              //     },
              //   ),
              // ),
              Padding(
                padding: EdgeInsets.only(top: 15),
                child: TextFormField(
                  maxLength: 45,
                  controller: _emailController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: const BorderSide(color: Color(0xFFDEDEDE)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: const BorderSide(color: Colors.blue),
                    ),
                    labelText: 'Alt Email',
                    labelStyle: const TextStyle(
                      color: Color(0xFFAFAFAF),
                      fontSize: 15,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your contact email';
                    }
                    final emailRegex =
                        RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                    if (!emailRegex.hasMatch(value)) {
                      return 'Enter a valid email';
                    }
                    return null;
                  },
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 15),
                child: TextFormField(
                  maxLength: 15,
                  controller: _phoneController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: const BorderSide(color: Color(0xFFDEDEDE)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: const BorderSide(color: Colors.blue),
                    ),
                    labelText: 'Phone Number',
                    labelStyle: const TextStyle(
                      color: Color(0xFFAFAFAF),
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          await uploadProfile();
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text("Save Changes"),
                              content: const Text("Changes Saved Successfully"),
                              actions: [
                                TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: GestureDetector(
                                        child: Text("OK"),
                                        onTap: () {
                                          Navigator.pop(context);
                                          Navigator.pop(context);
                                        }))
                              ],
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(60),
                          backgroundColor: const Color(0XFF32ade6),
                          foregroundColor: Colors.white,
                          elevation: 2.0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(
                              color: Colors.white,
                              width: 0,
                            ),
                          ),
                        ),
                        child: const Text(
                          'Save',
                          style: TextStyle(
                            fontSize: 16,
                            fontFamily: 'SfPro',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(60),
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0XFF32ade6),
                          elevation: 2.0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(
                              color: Color(0XFF32ade6),
                              width: 2.0,
                            ),
                          ),
                        ),
                        child: const Text(
                          'Cancel Changes',
                          style: TextStyle(
                            fontSize: 16,
                            fontFamily: 'SfPro',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
