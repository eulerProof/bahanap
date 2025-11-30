import 'package:cc206_bahanap/features/lora_provider.dart';
import 'package:cc206_bahanap/features/rescuer_provider.dart';
import 'package:cc206_bahanap/features/user_role.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cc206_bahanap/features/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'image_provider.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:network_info_plus/network_info_plus.dart';
import 'custom_bottom_nav.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => NotificationsPageState();
}

class NotificationsPageState extends State<NotificationsPage> {
  Timer? _timer;
  String userName = "";
  List<Map<String, dynamic>> receivedJSON = [];
  List<Map<String, dynamic>> get assignedSOS {
    return receivedJSON.where((msg) => msg['id'] == userName).toList();
  }

  final List<String> items = List.generate(3, (index) => "Item $index");
  @override
  void initState() {
    super.initState();
    _fetchUserName();
    _startReceivingMessages();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _startReceivingMessages() {
    _fetchMessage(); // Fetch once immediately
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _fetchMessage());
  }

  Future<void> _fetchMessage() async {
    try {
      final wifiName = await NetworkInfo().getWifiName();

      if (wifiName == null) {
        // setState(() {
        //   _responseMessage = "Not connected to any WiFi network.";
        // });
        return;
      }

      String? esp32IP;
      if (wifiName.contains("Bahanap_Node_A")) {
        esp32IP = "192.168.4.1";
      } else if (wifiName.contains("Bahanap_Node_B")) {
        esp32IP = "192.168.4.2";
      } else {
        return;
      }
      final response = await http.get(Uri.parse('http://$esp32IP/lastmessage'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is Map<String, dynamic>) {
          // ✅ Check if we already have this message (by ID or timestamp)
          final existing = receivedJSON.any((item) => item["id"] == data["id"]);

          if (!existing) {
            setState(() {
              receivedJSON.add(data);
            });
          }
        }
      } else {
        debugPrint("Failed: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error fetching message: $e");
    }
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
//   Future<void> fetchAndStoreMessage() async {
//   try {
//     final response = await http.get(Uri.parse('http://192.168.4.1/lastmessage'));
//     if (response.statusCode == 200) {
//       Map<String, dynamic> message = json.decode(response.body);

//       // Only store messages assigned to this user
//       if (message['id'] == userName) {
//         // Optional: check for duplicates if needed
//         bool exists = _assignedSOS.any((m) => m['id'] == msg['id'] && m['timestamp'] == msg['timestamp']);
//           if (!exists) {
//             _assignedSOS.add(msg);
//             notifyListeners(); // Important: tells UI to rebuild
//     }
//         }
//       }
//     }
//   } catch (e) {
//     print("Error fetching message: $e");
//   }
// }
  @override
  Widget build(BuildContext context) {
    final role = Provider.of<UserRoleProvider>(context).role;
    return SafeArea(
      child: Scaffold(
        body: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'BaHanap',
                      key: ValueKey('bahanapText'),
                      style: TextStyle(
                        fontSize: 35,
                        fontFamily: 'Gilroy',
                        color: Color(0XFF32ade6),
                        letterSpacing: -3.0,
                      ),
                    ),
                    // IconButton(
                    //   padding: const EdgeInsets.all(9),
                    //   icon: const Icon(Icons.notifications_none_outlined,
                    //       color: Colors.black),
                    //   iconSize: 35,
                    //   onPressed: () {},
                    // ),
                  ],
                ),
              ),
              // Padding(
              //   padding: const EdgeInsets.all(10),
              //   child: GridView.builder(
              //   shrinkWrap: true,
              //   itemCount: assignedSOS.length,
              //   gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              //     maxCrossAxisExtent: 550,
              //     mainAxisSpacing: 15,
              //     crossAxisSpacing: 15,
              //     mainAxisExtent: 150,
              //   ),
              //   itemBuilder: (context, i) {
              //     final item = assignedSOS[i];
              //     final lat = item['lat'] ?? "Unknown";
              //     final lon = item['lon'] ?? "Unknown";
              //     final id = item['id'] ?? "No Username";

              //     return Container(
              //       color: Colors.grey,
              //       child: Column(
              //         children: [
              //           Text("Coordinates: $lat, $lon")
              //         ],
              //       ),
              //     ); // Your card widget
              //   },
              //       )
              // ),

              Padding(
                padding: const EdgeInsets.all(10),
                child: SizedBox(
                    height: 240,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return Container(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 12),
                          child: SizedBox(
                            width: 300,
                            height: 700,
                            child: Center(
                              child: Card(
                                color: Color.fromARGB(255, 175, 220, 241),
                                elevation: 10,
                                child: Padding(
                                  padding: const EdgeInsets.all(13),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(15),
                                        child: Image.asset(
                                          'assets/pepito.png',
                                          fit: BoxFit.fitWidth,
                                          width: 400,
                                          height: 90,
                                        ),
                                      ),
                                      const Text(
                                        'Pepito rapidly intensifies into typhoon',
                                        style: TextStyle(
                                          fontFamily: 'SfPro',
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const Text(
                                        'Typhoon Pepito (Man-yi) will continue to undergo rapid intensification until Saturday, November 16...',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color:
                                              Color.fromARGB(255, 62, 62, 62),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    )),
              ),
              const Padding(
                padding: EdgeInsets.all(10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'More Stories',
                      style: TextStyle(
                        fontSize: 25,
                        fontFamily: 'Gilroy',
                        color: Color(0XFF154961),
                        letterSpacing: -1.0,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: SizedBox(
                    height: 300,
                    width: 800,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return Container(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 12),
                          child: SizedBox(
                            width: 200,
                            height: 700,
                            child: Center(
                              child: Card(
                                color: Color.fromARGB(255, 175, 220, 241),
                                elevation: 10,
                                child: Padding(
                                  padding: const EdgeInsets.all(13),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(15),
                                        child: Image.asset(
                                          'assets/pepito.png',
                                          fit: BoxFit.fitHeight,
                                          width: 200,
                                          height: 120,
                                        ),
                                      ),
                                      const Text(
                                        'Ofel weakens into severe tropical storm...',
                                        style: TextStyle(
                                          fontFamily: 'SfPro',
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const Text(
                                        'At its peak, Ofel was a super typhoon with maximum sust...',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color:
                                              Color.fromARGB(255, 62, 62, 62),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    )),
              ),
            ],
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        floatingActionButton: role == "Rescuer"
          ? _buildRescuerAlertButton()
          : _buildCitizenSOSButton(),
        bottomNavigationBar: CustomBottomNav(
          currentIndex: 2, // profile page index
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
