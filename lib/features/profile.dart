import 'package:cc206_bahanap/features/lora_provider.dart';
import 'package:cc206_bahanap/features/rescuer_provider.dart';
import 'package:cc206_bahanap/features/user_role.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'image_provider.dart';
import 'package:provider/provider.dart';
import 'custom_bottom_nav.dart';

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
  Widget _buildCitizenSOSButton() {
  return SizedBox(
              height: 90,
              width: 90,
              child: FloatingActionButton(
                onPressed: () {
                  Navigator.pushNamed(context, 'sos');
                },
                backgroundColor:
                    Colors.transparent, // set to transparent so gradient shows
                elevation: 6,
                shape: const CircleBorder(),
                child: Container(
                  alignment: Alignment.center,
                  height: 77,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      colors: [
                        Color.fromARGB(255, 255, 145, 145), // lighter red
                        Color(0xFFB70000), // dark red
                      ],
                      center: Alignment.center,
                      radius: 0.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Text(
                    'SOS',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 23,
                      fontFamily: 'SfPro',
                      color: Colors.white,
                      letterSpacing: 3,
                    ),
                  ),
                ),
              ));
  }
  Widget _buildRescuerAlertButton() {
    return FloatingActionButton(
      backgroundColor: Colors.blue,
      child: const Icon(Icons.warning_amber, size: 32, color: Colors.white),
      onPressed: () {
        _showAssignedSOSDialog();
      },
    );
  }
  void _showAssignedSOSDialog() {
    final loraProvider = Provider.of<LoRaProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Assigned SOS Alerts", textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),),
        content: SizedBox(
          width: double.maxFinite,
          height: MediaQuery.of(context).size.height * 0.5,
          child: loraProvider.messages.isEmpty ?
          const Center(
            child: Text("No SOS Alerts Received", style: TextStyle(fontSize: 15,),),
          )

          : ListView.builder(
            shrinkWrap: true,
            itemCount: loraProvider.messages.length,
            itemBuilder: (context, index) {
              final msg = loraProvider.messages[index];
                return ListTile(
                  title: Text(
                    "ID: ${msg['id']}",
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w100),
                  ),
                  subtitle: Text(
                    "Lat: ${msg['lat']}, Lon: ${msg['lon']}",
                    style: const TextStyle(fontSize: 15),
                  ),

                  // ⭐ Add Confirm button on the right
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2294C9),
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      _confirmSOS(msg);   // <-- This is where confirmation happens
                    },
                    child: const Text(
                      "Confirm",
                      style: TextStyle(fontSize: 14, color: Colors.white),
                    ),
                  ),
                );
              
            },
          )
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0XFF2294C9),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Close",
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
          )
        ],
      ),
    );
  }
  void _confirmSOS(Map<String, dynamic> msg) {
    final loraProvider = Provider.of<LoRaProvider>(context, listen: false);
    final rescueProvider = Provider.of<RescueModeProvider>(context, listen: false);
    // Remove from active list  
    loraProvider.sendConfirmation(msg, rescueProvider);

    // Optional: You can show a feedback dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("SOS from ${msg['id']} confirmed."),
        backgroundColor: Colors.green,
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    final role = Provider.of<UserRoleProvider>(context).role;
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
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Account',
                                  style: TextStyle(
                                      fontSize: 26,
                                      fontFamily: 'SfPro',
                                      color: Colors.black)),
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
      floatingActionButton: role == "Rescuer"
          ? _buildRescuerAlertButton()
          : _buildCitizenSOSButton(),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 3, // profile page index
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushNamed(context, 'dash');
              break;
            case 1:
              Navigator.pushNamed(context, 'map');
              break;
            case 2:
              Navigator.pushNamed(context, 'notifications');
              break;
            case 3:
              Navigator.pushNamed(context, 'profile');
              break;
          }
        },
      ),
    );
  }
}
