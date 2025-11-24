import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cc206_bahanap/features/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'image_provider.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:network_info_plus/network_info_plus.dart';
import 'custom_bottom_nav.dart';

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
  String _responseMessage2 = '';
  String _coordinates = '';
  String userName = "";

  @override
  void dispose() {
    _textController.dispose();

    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _initializeUser();
    _fetchLocation();
    _fetchUserName();
    fetchGuidelines();
  }

  Widget buildCategorySection(String title, List<String> items) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: const Color.fromARGB(255, 4, 87, 142),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const SizedBox(height: 10),
            if (items.isEmpty)
              const Text(
                "No guidelines added yet.",
                style: TextStyle(color: Colors.grey),
              )
            else
              ...items.map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text("• $item",
                        style:
                            const TextStyle(fontSize: 16, color: Colors.white)),
                  )),
          ],
        ),
      ),
    );
  }

  Future<void> fetchGuidelines() async {
    final provider = Provider.of<CustomImageProvider>(context, listen: false);
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
      final response = await http.get(Uri.parse('http://$esp32IP/guidelines'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["category"] == "Pre-disaster") {
          provider.addPreDisaster(data["content"]);
        } else if (data["category"] == "During disaster") {
          provider.addDuringDisaster(data["content"]);
        } else if (data["category"] == "Post-disaster") {
          provider.addPostDisaster(data["content"]);
        }
      } else {
        print("Failed to fetch guidelines: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching guidelines: $e");
    }
  }

  void _showGuidelines() async {
    final provider = Provider.of<CustomImageProvider>(context, listen: false);
    await fetchGuidelines();
    showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'FullScreenDialog',
        barrierColor: Colors.black54, // dim background
        pageBuilder: (context, animation1, animation2) {
          return Scaffold(
            body: Container(
              padding: const EdgeInsets.all(16),
              color: const Color(0xff002F4E),
              child: ListView(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Disaster Preparedness Guidelines',
                    style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'SfPro',
                        color: Colors.white),
                    textAlign: TextAlign.start,
                  ),
                  const SizedBox(height: 20),
                  buildCategorySection(
                      "Pre-Disaster Guidelines", provider.preDisaster),
                  const SizedBox(height: 20),
                  buildCategorySection(
                      "During Disaster Guidelines", provider.duringDisaster),
                  const SizedBox(height: 20),
                  buildCategorySection(
                      "Post-Disaster Guidelines", provider.postDisaster),
                ],
              ),
            ),
          );
        });
  }

  Future<void> _fetchUserName() async {
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isNotEmpty) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection("profiles")
            .doc(uid)
            .get();
        if (userDoc.exists) {
          setState(() {
            String fullName = userDoc['Name'] ?? "You ";
            userName = fullName.split(' ').first;
          });
        }
      } catch (e) {
        print("Error fetching user name: $e");
      }
    }
  }

  Future<void> _initializeUser() async {
    await UserService().fetchUsername();
    print("Username stored: ${UserService().username}");
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

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    UserService().clear(); 
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
      final message = {
        "text": _textController.text,
        "coordinates":
            "Placeholder. This is merely for testing. May all go well."
      };
      final response = await http.post(
        Uri.parse('http://$esp32IP/message'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(message),
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
          try {
            final data = jsonDecode(response.body);

            if (data is Map) {
              // Safely extract both fields
              _responseMessage = data["id"]?.toString() ?? "No text found";

              if (data["id"]?.toString() == userName) {
                _responseMessage2 = "You are the rescuer.";
              } else {
                _responseMessage2 = "You are NOT the rescuer";
              }
              // _coordinates = data['coordinates']?.toString() ?? "No coordinates";
            } else {
              _responseMessage = "Invalid JSON format";
              _coordinates = "";
            }
          } catch (e) {
            _responseMessage = "Error parsing JSON: $e";
            _coordinates = "";
          }
        } else {
          _responseMessage =
              'Failed to receive message. Status: ${response.statusCode}';
          _coordinates = "";
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
    final provider = Provider.of<CustomImageProvider>(context);
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
                          const SizedBox(width: 48),
                          const Expanded(
                            child: Center(
                              child: Text(
                                'BaHanap',
                                key: ValueKey('bahanapText'),
                                style: TextStyle(
                                  fontSize: 40,
                                  fontFamily: 'Gilroy',
                                  color: Color(0XFF32ade6),
                                  letterSpacing: -3.0,
                                ),
                              ),
                            ),
                          ),
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
                const Divider(),
                const SizedBox(
                  height: 20,
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
                        child: Container(
                          padding: EdgeInsets.fromLTRB(0, 10, 0, 0),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(23),
                              gradient: const LinearGradient(
                                  colors: [
                                    Color(0xff2B96C7),
                                    Color(0xff064400),
                                  ],
                                  begin: FractionalOffset(0.0, 0.0),
                                  end: FractionalOffset(0.0, 1.0))),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              SizedBox(height: 6),
                              Text(
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
                              SizedBox(height: 22),
                              Center(
                                child: Text(
                                  "Low",
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Gilroy',
                                    color: Colors.lightGreen,
                                    shadows: [
                                      Shadow(
                                        offset: Offset.zero,
                                        blurRadius: 10.0,
                                        color: Colors.green,
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),

                      // ---- Flood Probability ----
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: GestureDetector(
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(23),
                                gradient: const LinearGradient(
                                    colors: [
                                      Color(0xff7F7F7F),
                                      Color(0xff232323),
                                    ],
                                    begin: FractionalOffset(0.0, 0.0),
                                    end: FractionalOffset(0.0, 1.0))),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SizedBox(height: 6),
                                const Text(
                                  'Risk Level',
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
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 22),
                                const Text(
                                  'Minimal Risk',
                                  style: TextStyle(
                                    letterSpacing: 0.5,
                                    fontSize: 15,
                                    fontFamily: 'SfPro',
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                // Image.asset(
                                //   'assets/floodprob.png',
                                //   color: Colors.white,
                                //   fit: BoxFit.cover,
                                //   width: double.infinity,
                                //   height: 120,
                                // ),
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
                          child: Container(
                            padding: EdgeInsets.fromLTRB(20, 10, 0, 15),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(23),
                                gradient: const LinearGradient(
                                    colors: [
                                      Color(0xff0899F8),
                                      Color(0xff055A92),
                                    ],
                                    begin: FractionalOffset(0.0, 0.0),
                                    end: FractionalOffset(0.0, 1.0))),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 6),
                                const Text(
                                  'Disaster Preparedness Guidelines',
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
                                  textAlign: TextAlign.start,
                                ),
                                Spacer(),
                                const Text(
                                  "View",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                      fontSize: 16,
                                      fontFamily: 'SfPro',
                                      decoration: TextDecoration.underline,
                                      decorationColor: Colors.white,
                                      color: Colors.white),
                                  textAlign: TextAlign.left,
                                )
                              ],
                            ),
                          ),
                          onTap: () {
                            _showGuidelines();
                          },
                        ),
                      ),

                      // ---- Alert Warnings ----
                      Padding(
                        padding: EdgeInsets.all(8),
                        child: GestureDetector(
                          child: Container(
                            padding: EdgeInsets.fromLTRB(20, 10, 0, 15),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(23),
                                gradient: const LinearGradient(
                                    colors: [
                                      Color(0xff055A92),
                                      Color(0xff0899F8),
                                    ],
                                    begin: FractionalOffset(0.0, 0.0),
                                    end: FractionalOffset(0.0, 1.0))),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 6),
                                const Text(
                                  'Evacuation Centers',
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
                                  textAlign: TextAlign.start,
                                ),
                                Spacer(),
                                const Text(
                                  "View",
                                  style: TextStyle(
                                      letterSpacing: 0.5,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'SfPro',
                                      decoration: TextDecoration.underline,
                                      decorationColor: Colors.white,
                                      color: Colors.white),
                                  textAlign: TextAlign.left,
                                )
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
              )),
        ),
        bottomNavigationBar: CustomBottomNav(
          currentIndex: 0, // profile page index
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
      ),
    );
  }
}
