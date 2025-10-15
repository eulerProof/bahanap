import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'image_provider.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:network_info_plus/network_info_plus.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  Location location = Location();
  bool _serviceEnabled = false;
  PermissionStatus _permissionGranted = PermissionStatus.denied;
  LocationData? _locationData;
  String currentAddress = "Fetching address...";
  final TextEditingController _textController = TextEditingController();
  String _responseMessage = '';

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> uploadLocation(double lat, double lon) async {
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) {
      print("Error: User not logged in.");
      return;
    }

    try {
      await FirebaseFirestore.instance.collection("profiles").doc(uid).set({
        "Coordinates": lat.toString() + ', ' + lon.toString(),
        "Location": currentAddress,
      }, SetOptions(merge: true));

      print("Location updated successfully");
    } catch (e) {
      print("Error updating location: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, 'welcome');
  }

  Future<void> _fetchLocation() async {
    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) return;
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) return;
    }

    _locationData = await location.getLocation();
    if (_locationData != null) {
      double lat = _locationData!.latitude!;
      double lon = _locationData!.longitude!;

      _fetchAddressFromCoordinates(lat, lon);
      uploadLocation(lat, lon);
    }
  }

  Future<void> _fetchAddressFromCoordinates(double lat, double lon) async {
    final url =
        "https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lon&format=json";

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          currentAddress = data["display_name"] ??
              "Address not found. Please wait for a moment then try again.";
        });
      } else {
        setState(() {
          currentAddress = "Failed to fetch address";
        });
      }
    } catch (e) {
      setState(() {
        currentAddress = "Error occurred: $e";
      });
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      Provider.of<CustomImageProvider>(context, listen: false)
          .setImage(File(image.path));
    }
  }

  Future<void> _sendPostRequest() async {
    try {
      final wifiName = await NetworkInfo().getWifiName();

      if (wifiName == null) {
        setState(() {
          _responseMessage = "Not connected to any WiFi network.";
        });
        return;
      }

      String? esp32IP;
      if (wifiName.contains("Bahanap_Node_A")) {
        esp32IP = "192.168.4.1";
      } else if (wifiName.contains("Bahanap_Node_B")) {
        esp32IP = "192.168.4.2";
      } else {
        setState(() {
          _responseMessage = "Not connected to a valid ESP32 node WiFi.";
        });
        return;
      }

      final response = await http.post(
        Uri.parse('http://$esp32IP/message'),
        headers: {'Content-Type': 'text/plain; charset=UTF-8'},
        body: _textController.text,
      );

      setState(() {
        _responseMessage = response.statusCode == 200
            ? 'Message sent successfully!'
            : 'Failed to send. Status: ${response.statusCode}';
      });
    } catch (e) {
      setState(() {
        _responseMessage = 'Error: $e';
      });
    }
  }

  Future<void> _fetchReceivedMessage() async {
    try {
      final wifiName = await NetworkInfo().getWifiName();

      if (wifiName == null) {
        setState(() {
          _responseMessage = "Not connected to any WiFi network.";
        });
        return;
      }

      String? esp32IP;
      if (wifiName.contains("Bahanap_Node_A")) {
        esp32IP = "192.168.4.1";
      } else if (wifiName.contains("Bahanap_Node_B")) {
        esp32IP = "192.168.4.2";
      } else {
        setState(() {
          _responseMessage = "Not connected to a valid ESP32 node WiFi.";
        });
        return;
      }

      final response = await http.get(Uri.parse('http://$esp32IP/lastmessage'));

      setState(() {
        if (response.statusCode == 200) {
          _responseMessage = response.body;
        } else {
          _responseMessage =
              'Failed to receive message. Status: ${response.statusCode}';
        }
      });
    } catch (e) {
      setState(() {
        _responseMessage = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Container(
          height: MediaQuery.of(context).size.height,
          color: Colors.white,
          child: SingleChildScrollView(
            child: Column(
              children: [
                Container(
                    height: 80,
                    width: MediaQuery.of(context).size.width,
                    child: Padding(
                      padding: EdgeInsets.all(10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: _pickImage,
                            child: CircleAvatar(
                              radius: 30,
                              backgroundImage: Provider.of<CustomImageProvider>(
                                              context)
                                          .imageFile !=
                                      null
                                  ? FileImage(
                                      Provider.of<CustomImageProvider>(context)
                                          .imageFile!)
                                  : AssetImage('assets/images/dgfdfdsdsf2.jpg'),
                            ),
                          ),
                          const Text('BaHanap',
                              key: ValueKey('bahanapText'),
                              style: TextStyle(
                                fontSize: 35,
                                fontFamily: 'Gilroy',
                                color: Color(0XFF32ade6),
                                letterSpacing: -3.0,
                              )),
                          IconButton.outlined(
                            padding: EdgeInsets.all(9),
                            icon: const Icon(Icons.logout, color: Colors.black),
                            onPressed: () {
                              _signOut();
                            },
                          ),
                        ],
                      ),
                    )),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Expanded(
                      child: Card(
                        elevation: 5,
                        margin: const EdgeInsets.fromLTRB(25, 17, 10, 17),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        ),
                        color: const Color(0xff32ade6),
                        child: Padding(
                          padding: const EdgeInsets.all(5),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                color: Colors.white,
                                size: 30,
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                height: 25,
                                width: 275,
                                child: Text(
                                  currentAddress,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                    fontFamily: 'SfPro',
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        _fetchLocation();
                      },
                      icon: const Icon(Icons.edit_location_alt_outlined),
                      iconSize: 30,
                      color: const Color(0xff32ade6),
                    ),
                  ],
                ),
                Padding(
                  padding: EdgeInsets.all(10),
                  child: GridView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 3,
                      mainAxisSpacing: 8,
                    ),
                    children: [
                      // ---- Water Level ----
                      Padding(
                        padding: EdgeInsets.all(8),
                        child: GestureDetector(
                          child: Card(
                            color: Color(0xffa1d9f4),
                            elevation: 10,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                const SizedBox(height: 6),
                                const Text(
                                  'Water Level',
                                  style: TextStyle(
                                      letterSpacing: 0.5,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'SfPro',
                                      shadows: [
                                        Shadow(
                                          offset: Offset(2.0, 3.0),
                                          blurRadius: 6.0,
                                          color: Colors.black54,
                                        ),
                                      ],
                                      color: Colors.white),
                                  textAlign: TextAlign.center,
                                ),
                                Image.asset('assets/waterlevel.png',
                                    height: 130.2),
                              ],
                            ),
                          ),
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text("Water Level"),
                                content: Text(
                                    "This is where the Water level information would be."),
                                actions: [
                                  TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text("Ok"))
                                ],
                              ),
                            );
                          },
                        ),
                      ),

                      // ---- Flood Probability ----
                      Padding(
                        padding: EdgeInsets.all(8),
                        child: GestureDetector(
                          child: Card(
                            color: Color(0xffa1d9f4),
                            elevation: 10,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                const SizedBox(height: 6),
                                const Text(
                                  'Flood Probability',
                                  style: TextStyle(
                                    letterSpacing: 0.5,
                                    fontSize: 19,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'SfPro',
                                    shadows: [
                                      Shadow(
                                        offset: Offset(2.0, 3.0),
                                        blurRadius: 6.0,
                                        color: Colors.black54,
                                      ),
                                    ],
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Image.asset(
                                  'assets/floodprob.png',
                                  color: Colors.white,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: 120,
                                ),
                              ],
                            ),
                          ),
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text("Flood Probability"),
                                content: Text(
                                    "This is where the flood probability info would be."),
                                actions: [
                                  TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text("Ok"))
                                ],
                              ),
                            );
                          },
                        ),
                      ),

                      // ---- Evacuation ----
                      Padding(
                        padding: EdgeInsets.all(8),
                        child: GestureDetector(
                          child: Card(
                            color: Color(0xffa1d9f4),
                            elevation: 10,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                const SizedBox(height: 6),
                                const Text(
                                  'Evacuation',
                                  style: TextStyle(
                                      letterSpacing: 0.5,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'SfPro',
                                      shadows: [
                                        Shadow(
                                          offset: Offset(2.0, 3.0),
                                          blurRadius: 6.0,
                                          color: Colors.black54,
                                        ),
                                      ],
                                      color: Colors.white),
                                  textAlign: TextAlign.center,
                                ),
                                Image.asset('assets/evacuation.png',
                                    height: 130, color: Color(0xff247ba3)),
                              ],
                            ),
                          ),
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text("Evacuation"),
                                content: Text(
                                    "This is where the evacuation info would be."),
                                actions: [
                                  TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text("Ok"))
                                ],
                              ),
                            );
                          },
                        ),
                      ),

                      // ---- Alert Warnings ----
                      Padding(
                        padding: EdgeInsets.all(8),
                        child: GestureDetector(
                          child: Card(
                            color: Color(0xffa1d9f4),
                            elevation: 10,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                const SizedBox(height: 6),
                                const Text(
                                  'Alert Warnings',
                                  style: TextStyle(
                                      letterSpacing: 0.5,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'SfPro',
                                      shadows: [
                                        Shadow(
                                          offset: Offset(2.0, 3.0),
                                          blurRadius: 6.0,
                                          color: Colors.black54,
                                        ),
                                      ],
                                      color: Colors.white),
                                  textAlign: TextAlign.center,
                                ),
                                Image.asset('assets/alert.png', height: 130.2),
                              ],
                            ),
                          ),
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text("Alert Warnings"),
                                content: Text(
                                    "This is where the alert warning info would be."),
                                actions: [
                                  TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text("Ok"))
                                ],
                              ),
                            );
                          },
                        ),
                      ),

                      // ---- Send Message ----
                      Padding(
                        padding: EdgeInsets.all(8),
                        child: Card(
                          color: Color(0xffa1d9f4),
                          elevation: 10,
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'Send Message',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontFamily: 'SfPro',
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _textController,
                                  decoration: InputDecoration(
                                    hintText: 'Enter message',
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    fillColor: Colors.white,
                                    filled: true,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton(
                                  onPressed: _sendPostRequest,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xff32ade6),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 10),
                                  ),
                                  child: const Text('Send',
                                      style: TextStyle(color: Colors.white)),
                                ),
                                if (_responseMessage.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(
                                      _responseMessage,
                                      style: TextStyle(
                                        color: _responseMessage
                                                .contains('successfully')
                                            ? Colors.green
                                            : Colors.red,
                                        fontSize: 12,
                                        fontFamily: 'SfPro',
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // ---- Received Message ----
                      Padding(
                        padding: EdgeInsets.all(8),
                        child: Card(
                          color: Color(0xffa1d9f4),
                          elevation: 10,
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'Received Message',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontFamily: 'SfPro',
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _responseMessage.isEmpty
                                      ? 'No message received yet.'
                                      : _responseMessage,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontFamily: 'SfPro',
                                  ),
                                ),
                                const SizedBox(height: 10),
                                ElevatedButton.icon(
                                  onPressed: _fetchReceivedMessage,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xff32ade6),
                                  ),
                                  icon: const Icon(Icons.refresh,
                                      color: Colors.white),
                                  label: const Text(
                                    'Refresh',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        backgroundColor: const Color(0xff32ade6),
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
                        Navigator.pushNamed(context, 'notifications');
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.person),
                      iconSize: 30,
                      color: Colors.white,
                      onPressed: () {
                        Navigator.pushNamed(context, 'profile');
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
