import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'image_provider.dart';
import 'package:provider/provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final CollectionReference fetchData =
      FirebaseFirestore.instance.collection("profiles");
  final User? user = FirebaseAuth.instance.currentUser;
  bool showLiveCoordinates = true;
  File? _imageFile;
  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, 'welcome');
  }

  Future<void> _pickImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      Provider.of<CustomImageProvider>(context, listen: false)
          .setImage(File(image.path));
    }
  }

  void _removeImage() {
    Provider.of<CustomImageProvider>(context, listen: false).clearImage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StreamBuilder<QuerySnapshot>(
                stream:
                    fetchData.where('uid', isEqualTo: user?.uid).snapshots(),
                builder:
                    (context, AsyncSnapshot<QuerySnapshot> streamSnapshot) {
                  if (streamSnapshot.hasData) {
                    if (streamSnapshot.data!.docs.isNotEmpty) {
                      final DocumentSnapshot documentSnapshot =
                          streamSnapshot.data!.docs.first;

                      return Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Account',
                                  style: TextStyle(
                                      fontSize: 26,
                                      fontFamily: 'SfPro',
                                      color: Colors.black)),
                              IconButton.outlined(
                                padding: EdgeInsets.all(9),
                                icon: const Icon(Icons.settings,
                                    color: Colors.black),
                                onPressed: () {
                                  Navigator.pushNamed(context, 'settings');
                                },
                              ),
                            ],
                          ),
                          Container(
                            margin: const EdgeInsets.all(13),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Column(
                                  children: [
                                    GestureDetector(
                                      onTap: _pickImage,
                                      child: CircleAvatar(
                                        radius: 50,
                                        backgroundImage: Provider.of<
                                                            CustomImageProvider>(
                                                        context)
                                                    .imageFile !=
                                                null
                                            ? FileImage(Provider.of<
                                                        CustomImageProvider>(
                                                    context)
                                                .imageFile!)
                                            : const AssetImage(
                                                'assets/images/dgfdfdsdsf2.jpg'),
                                      ),
                                    ),
                                    SizedBox(height: 10),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        padding: EdgeInsets.all(12),
                                        backgroundColor:
                                            Color.fromARGB(255, 220, 24, 24),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10)),
                                      ),
                                      onPressed: () {
                                        _removeImage();
                                      },
                                      child: const Text('Remove Image',
                                          style: TextStyle(
                                              fontSize: 14,
                                              fontFamily: 'SfPro')),
                                    ),
                                  ],
                                ),
                                SizedBox(width: 30),
                                Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(documentSnapshot['Name'],
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 17,
                                            fontFamily: 'SfPro',
                                            color: Colors.black)),
                                    const Text('Citizen',
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontFamily: 'SfPro',
                                            color: Color(0xff575757))),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 12),
                                        foregroundColor: Colors.white,
                                        backgroundColor: Color(0xff32ade6),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10)),
                                      ),
                                      onPressed: () {
                                        Navigator.pushNamed(
                                            context, 'editprofile');
                                      },
                                      child: const Text('Edit Profile',
                                          style: TextStyle(
                                              fontSize: 15,
                                              fontFamily: 'SfPro')),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Personal Details',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      fontFamily: 'SfPro',
                                      color: Color(0xff555555))),
                              IconButton(
                                onPressed: () {
                                  Navigator.pushNamed(context, 'editprofile');
                                },
                                icon: Icon(Icons.mode_edit_outlined),
                                iconSize: 30,
                                color: Color.fromARGB(255, 146, 146, 146),
                              )
                            ],
                          ),
                          Container(
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                    color: Color.fromARGB(255, 168, 168, 168),
                                    width: 1.0)),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Row(
                                        children: [
                                          Icon(Icons.phone_outlined),
                                          SizedBox(width: 40),
                                          const Text('Phone Number',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                  fontFamily: 'SfPro',
                                                  color: Color(0xff555555))),
                                        ],
                                      ),
                                      Text(documentSnapshot['PhoneNumber'],
                                          style: const TextStyle(
                                              fontSize: 13,
                                              fontFamily: 'SfPro',
                                              color: Color(0xff575757))),
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Row(
                                        children: [
                                          Icon(Icons.email_outlined),
                                          SizedBox(width: 40),
                                          const Text('Alt Email',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                  fontFamily: 'SfPro',
                                                  color: Color(0xff555555))),
                                        ],
                                      ),
                                      const SizedBox(width: 40),
                                      Text(documentSnapshot['email'],
                                          style: const TextStyle(
                                              fontSize: 13,
                                              fontFamily: 'SfPro',
                                              color: Color(0xff575757))),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 16),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                  color: Color(0xff32ade6), width: 1.0),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text('Live Coordinates',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 20,
                                              fontFamily: 'SfPro',
                                              color: Color(0xff32ade6))),
                                      Transform.scale(
                                        scale: 0.7,
                                        child: Switch(
                                          value: showLiveCoordinates,
                                          activeColor: Colors.blue,
                                          inactiveThumbColor: Colors.grey,
                                          onChanged: (value) {
                                            setState(() {
                                              showLiveCoordinates = value;
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 10),
                                  Center(
                                    child: Text(
                                      showLiveCoordinates
                                          ? documentSnapshot['LiveCoordinates']
                                          : documentSnapshot['Coordinates'],
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontFamily: 'SfPro',
                                          color: Color(0xff32ade6)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    } else {
                      return Center(
                          child: ElevatedButton(
                        onPressed: _signOut,
                        child: const Text('Sign Out'),
                      ));
                    }
                  }
                  return const Center(child: CircularProgressIndicator());
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 0),
        child: SizedBox(
          height: 90,
          width: 90,
          child: FloatingActionButton(
            onPressed: () {
              Navigator.pushNamed(context, 'sos');
            },
            backgroundColor: const Color.fromARGB(255, 239, 66, 63),
            shape: const CircleBorder(),
            child: const Text(
              'SOS',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 25,
                  fontFamily: 'SfPro',
                  color: Colors.white,
                  letterSpacing: 3),
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: const Color(0xff32ade6),
        shape: const CircularNotchedRectangle(),
        notchMargin: 6.0,
        child: Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: SizedBox(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.home),
                    color: Colors.white,
                    onPressed: () {
                      if (ModalRoute.of(context)?.settings.name != 'dash') {
                        Navigator.pushNamed(context, 'dash');
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.map),
                    color: Colors.white,
                    onPressed: () {
                      Navigator.pushNamed(context, 'map');
                    },
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    icon: const Icon(Icons.notifications),
                    iconSize: 30,
                    color: Colors.white,
                    onPressed: () {
                      if (ModalRoute.of(context)?.settings.name !=
                          'notifications') {
                        Navigator.pushNamed(context, 'notifications');
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.person),
                    iconSize: 30,
                    color: Colors.white,
                    onPressed: () {
                      if (ModalRoute.of(context)?.settings.name != 'profile') {
                        Navigator.pushNamed(context, 'profile');
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
