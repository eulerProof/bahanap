import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cc206_bahanap/features/user_role.dart';

import 'custom_bottom_nav.dart';
import 'package:cc206_bahanap/features/image_provider.dart';
import 'package:cc206_bahanap/features/lora_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:network_info_plus/network_info_plus.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  final List<Marker> _loraMarkers = [];
  // Use the mapStore initialized in main.dart
  final _tileProvider = FMTCTileProvider(
    stores: const {'mapStore': BrowseStoreStrategy.readUpdateCreate},
  );

  LatLng? userLocation;
  // Dedicated markers/lists for clear management
  Marker? _userMarker; // Current user marker
  Marker? _lorawanMarker; // Lorawan module marker
  final List<Marker> _peerMarkers = []; // Other users' markers
  final List<Marker> _markers = []; // Combined list for FlutterMap

  StreamSubscription<Position>? _positionStreamSubscription;
  StreamSubscription<QuerySnapshot>? _peerLocationsSubscription;
  Timer? _locationUpdateTimer;

  String userName = "";
  String _username = '';
  double _latitude = 0;
  double _longitude = 0;
  String _responseMessage = '';

  // --- INITIALIZATION AND DISPOSAL ---

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    // Auth and Data Fetching
    _fetchUserName();
    final loraProvider = Provider.of<LoRaProvider>(context, listen: false);
      loraProvider.addListener(() {
        _updateLorawanMarkersFromProvider();
      });
       WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateLorawanMarkersFromProvider();
      });
    // Location and Mapping
    // _fetchCurrentLocationAndStartUpdates();
    // _listenToOtherUserLocations();
    // _fetchLocationFromModule();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _peerLocationsSubscription?.cancel();
    _locationUpdateTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // --- CORE LOGIC ---

  /// Combines the initial location fetch and starts periodic updates.
  /// 
  Widget _buildCitizenSOSButton() {
  return SizedBox(
    height: 90,
    width: 90,
    child: FloatingActionButton(
      onPressed: () {
        Navigator.pushNamed(context, 'sos');
      },
      backgroundColor: Colors.transparent,
      elevation: 6,
      shape: const CircleBorder(),
      child: Container(
        alignment: Alignment.center,
        height: 77,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(
            colors: [
              Color.fromARGB(255, 255, 145, 145),
              Color(0xFFB70000),
            ],
            radius: 0.5,
          ),
        ),
        child: const Text(
          'SOS',
          style: TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 3,
          ),
        ),
      ),
    ),
  );
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
      title: const Text("Assigned SOS Alerts"),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: loraProvider.messages.length,
          itemBuilder: (context, index) {
            final msg = loraProvider.messages[index];
            return ListTile(
              title: Text("ID: ${msg['id']}"),
              subtitle: Text("Lat: ${msg['lat']}, Lon: ${msg['lon']}"),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Close"),
        )
      ],
    ),
  );
}
  void _fetchCurrentLocationAndStartUpdates() async {
    await _fetchCurrentLocation(); // Initial fetch

    // Stop previous timer if running
    _locationUpdateTimer?.cancel();

    // Start periodic updates (e.g., every 15 seconds to be battery-friendly)
    _locationUpdateTimer =
        Timer.periodic(const Duration(seconds: 15), (Timer t) {
      _fetchCurrentLocation();
    });
  }

  /// Listens to real-time coordinate updates for all other users.
  void _listenToOtherUserLocations() {
    final String currentUserUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (currentUserUid.isEmpty) return;

    // Listen for changes in the entire profiles collection
    _peerLocationsSubscription = FirebaseFirestore.instance
        .collection('profiles')
        .snapshots()
        .listen((snapshot) {
      _peerMarkers.clear();
      for (var doc in snapshot.docs) {
        if (doc.id == currentUserUid) continue; // Skip current user

        // Prioritize LiveCoordinates if available, fall back to static Coordinates
        String coordinatesString = doc['LiveCoordinates'] ??
            doc['Coordinates'] ??
            "Lat: 0.0, Lon: 0.0";
        String fullName = doc['Name'] ?? "User";

        // Simple regex to extract numbers, assuming format is "Lat: X, Lon: Y" or similar
        // We will remove non-numeric characters except for '.', '-', and ','
        List<String> latLngParts = coordinatesString.split(',');
        double latitude = double.tryParse(
                latLngParts[0].replaceAll(RegExp(r'[^\d.-]'), '').trim()) ??
            0.0;
        double longitude = double.tryParse(latLngParts.length > 1
                ? latLngParts[1].replaceAll(RegExp(r'[^\d.-]'), '').trim()
                : "0.0") ??
            0.0;

        if (latitude != 0.0 || longitude != 0.0) {
          String peerName = fullName.split(' ').first;
          // Other users get a Green circle border
          _peerMarkers.add(
            Marker(
              width: 100.0,
              height: 100.0,
              point: LatLng(latitude, longitude),
              child: _buildMarkerChild(
                  peerName,
                  Colors.green,
                  // Assuming all other users use the same default placeholder image
                  const AssetImage('assets/images/dgfdfdsdsf2.jpg')),
            ),
          );
        }
      }
      _rebuildMarkersList();
    }, onError: (error) {
      print("Error listening to peer locations: $error");
    });
  }

  /// Rebuilds the final list of markers for the map.
  void _rebuildMarkersList() {
    setState(() {
      _markers.clear();
      if (_userMarker != null) _markers.add(_userMarker!);
      _markers.addAll(_loraMarkers);      // <-- FIX
      _markers.addAll(_peerMarkers);
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
            String fullName = userDoc['Name'] ?? "You";
            userName = fullName.split(' ').first;
          });
        }
      } catch (e) {
        print("Error fetching user name: $e");
      }
    }
  }

  /// Fetches the user's current GPS location.
  Future<void> _fetchCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      LatLng newLocation = LatLng(position.latitude, position.longitude);
      setState(() {
        userLocation = newLocation;
        _updateUserMarker(newLocation);
        uploadLocation(newLocation);
        _rebuildMarkersList();
      });
      // Optionally move the map to the user's location on initial load
      if (_mapController.camera.center == LatLng(10.7202, 122.5621) ||
          _mapController.camera.zoom == 13.0) {
        _mapController.move(newLocation, 18.0);
      }
    } catch (e) {
      print("Error fetching current location: $e");
      // Only show dialog once if location is critical, otherwise log silently
      // _showErrorDialog('Unable to fetch current location.');
    }
  }

  /// Uploads the current user's location to Firestore.
  Future<void> uploadLocation(LatLng loc) async {
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) {
      print("Error: User not logged in.");
      return;
    }

    try {
      String formattedLocation = "Lat: ${loc.latitude}, Lon: ${loc.longitude}";

      // Use LiveCoordinates for real-time tracking
      await FirebaseFirestore.instance.collection("profiles").doc(uid).set({
        "LiveCoordinates": formattedLocation,
        "timestamp": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // print("Location updated successfully");
    } catch (e) {
      print("Error updating location: $e");
    }
  }

  /// Updates the current user's marker.
  void _updateUserMarker(LatLng location) {
    // Get the user's custom image from the provider
    final imageProvider =
        Provider.of<CustomImageProvider>(context, listen: false);
    final imageFile = imageProvider.imageFile;

    ImageProvider markerImage;
    if (imageFile != null) {
      markerImage = FileImage(imageFile);
    } else {
      markerImage = const AssetImage('assets/images/dgfdfdsdsf2.jpg');
    }

    _userMarker = Marker(
      width: 100.0,
      height: 100.0,
      point: location,
      child: _buildMarkerChild(userName, Colors.blue, markerImage),
    );
  }

  /// Fetches the Lorawan module's last reported location.
  // Future<void> _fetchLocationFromModule() async {
  //   try {
  //     final wifiName = await NetworkInfo().getWifiName();

  //     if (wifiName == null ||
  //         (!wifiName.contains("Bahanap_Node_A") &&
  //             !wifiName.contains("Bahanap_Node_B"))) {
  //       setState(() {
  //         _responseMessage = "Not connected to a relevant ESP32 node WiFi.";
  //       });
  //       return;
  //     }

  //     String? esp32IP;
  //     if (wifiName.contains("Bahanap_Node_A")) {
  //       esp32IP = "192.168.4.1";
  //     } else if (wifiName.contains("Bahanap_Node_B")) {
  //       esp32IP = "192.168.4.2";
  //     }

  //     final response = await http.get(Uri.parse('http://$esp32IP/lastmessage'));

  //     if (response.statusCode == 200) {
  //       final data = jsonDecode(response.body); // Parse JSON

  //       // Check if the reported ID matches the current user's name
  //       if (data["rescuer"]?.toString() == userName) {
  //         setState(() {
  //           _username = data["uid"] ?? "Unknown";
  //           _latitude = data["lat"]?.toDouble() ?? 0.0;
  //           _longitude = data["lon"]?.toDouble() ?? 0.0;
  //           _updateLorawanMarker(LatLng(_latitude, _longitude), _username);
  //           _rebuildMarkersList();
  //           _responseMessage = 'Location from module received.';
  //         });
  //       }
  //     } else {
  //       setState(() {
  //         _responseMessage =
  //             'Failed to receive message. Status: ${response.statusCode}';
  //       });
  //     }
  //   } on SocketException catch (_) {
  //     setState(() {
  //       _responseMessage = 'Error: No connection to ESP32 module.';
  //     });
  //   } catch (e) {
  //     setState(() {
  //       _responseMessage = 'Error fetching module location: $e';
  //     });
  //   }
  // }

  /// Updates the Lorawan module marker.
  void _updateLorawanMarkersFromProvider() {
  final loraProvider = Provider.of<LoRaProvider>(context, listen: false);
  final rescuerId = Provider.of<UserRoleProvider>(context, listen: false).id;
  final messages = loraProvider.messages;

  _loraMarkers.clear();  // Clear ONCE
  _markers.clear();
  for (int i = 0; i < messages.length; i++) {
    final msg = messages[i];
    final lat = msg['lat'] as double? ?? 0.0;
    final lon = msg['lon'] as double? ?? 0.0;
    final id = msg['id']?.toString() ?? 'Unknown';
    final rescuer = msg['rescuer']?.toString() ?? 'Unknown';

    if (rescuer != rescuerId) continue;
    _loraMarkers.add(
      Marker(
        key: ValueKey('lorawan_${id}_$i'),
        width: 100.0,
        height: 100.0,
        point: LatLng(lat, lon),
        child: _buildMarkerChild(
          id,
          Colors.red,
          const AssetImage('assets/images/dgfdfdsdsf2.jpg'),
        ),
      ),
    );
  }

  _rebuildMarkersList();
}
  /// Refreshes all non-streamed data (Lorawan location).
  void _refresh() async {
   _updateLorawanMarkersFromProvider();
    _rebuildMarkersList();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content:
              Text('Map data refreshed. Lorawan status: $_responseMessage')),
    );
  }

  // --- UI HELPER WIDGETS ---

  /// Reusable widget for creating the marker look (avatar and name tag).
  Widget _buildMarkerChild(
      String name, Color borderColor, ImageProvider imageProvider) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: borderColor,
              width: 3.0,
            ),
          ),
          child: CircleAvatar(
            radius: 15,
            backgroundImage: imageProvider,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          name,
          style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12.0,
              fontFamily: 'SfPro',
              color: Colors.black,
              shadows: [
                Shadow(
                  color: Colors.white,
                  blurRadius: 2.0,
                ),
              ]),
        ),
      ],
    );
  }

  // --- MAP CONTROLS AND SEARCH ---

  Future<void> _searchLocation() async {
    // ... (unchanged search logic)
    String query = _searchController.text.trim();
    if (query.isNotEmpty) {
      try {
        List<Location> locations = await locationFromAddress(query);
        if (locations.isEmpty) {
          _showErrorDialog('No locations found for "$query".');
        } else {
          Location location = locations.first;
          _mapController.move(
              LatLng(location.latitude, location.longitude), 15.0);
        }
      } catch (e) {
        _showErrorDialog(
            'Geocoding error: Check address or internet connection.');
      }
    } else {
      _showErrorDialog('Please enter a valid address to search.');
    }
  }

  Future<void> _moveToUserLocation() async {
    if (userLocation != null) {
      _mapController.move(userLocation!, 18.0);
    } else {
      await _fetchCurrentLocation();
      if (userLocation != null) {
        _mapController.move(userLocation!, 18.0);
      } else {
        _showErrorDialog('User location is not available.');
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Ok"),
          ),
        ],
      ),
    );
  }

  // --- BUILD METHOD ---

  @override
  Widget build(BuildContext context) {
    final role = Provider.of<UserRoleProvider>(context).role;
    return SafeArea(
      child: Scaffold(
        body: Stack(
          children: [
            // --- FLUTTER MAP WIDGET ---
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                // Use Iloilo as default center if location is not yet available
                initialCenter: userLocation ?? LatLng(10.7202, 122.5621),
                initialZoom: 13.0,
              ),
              children: [
                TileLayer(
                  // Using CartoDB Positron as a highly available, OSM-based alternative.
                  // This is generally more reliable for non-commercial use than the default OSM tiles.
                  urlTemplate:
                      "https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png",
                  subdomains: const [
                    'a',
                    'b',
                    'c',
                    'd'
                  ], // CartoDB uses subdomains
                  tileProvider: _tileProvider, // FMTC Caching is here
                  maxZoom: 20, // CartoDB supports higher zoom
                  minZoom: 1,
                ),
                MarkerLayer(markers: _markers),
              ],
            ),

            // --- SEARCH BAR ---
            Positioned(
                top: 20,
                left: 16,
                right: 16,
                child: Material(
                  elevation: 5.0,
                  shadowColor: Colors.black,
                  borderRadius: BorderRadius.circular(20),
                  child: TextFormField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(
                        Icons.location_searching_outlined,
                        color: Color(0xffafafaf),
                      ),
                      labelText: 'Search Map',
                      labelStyle: const TextStyle(color: Color(0xffafafaf)),
                      floatingLabelStyle: const TextStyle(
                        color: Colors.blue,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(
                          color: Colors.blue,
                          width: 1.5,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(
                          color: Colors.blue,
                          width: 2.0,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onFieldSubmitted: (_) {
                      _searchLocation();
                    },
                  ),
                )),

            // --- FLOATING CONTROLS (My Location, Zoom, Refresh) ---
            Positioned(
              top: 100,
              right: 16,
              child: Column(
                children: [
                  // My Location Button
                  GestureDetector(
                    onTap: _moveToUserLocation,
                    child: Container(
                      height: 35,
                      width: 35,
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 255, 255, 255),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.black,
                          width: 0.5,
                        ),
                      ),
                      child: const Icon(
                        Icons
                            .my_location, // Changed to a more standard location icon
                        size: 20.0,
                        color: Color(0xff32ade6),
                      ),
                    ),
                  ),

                  // Zoom In
                  GestureDetector(
                    onTap: () {
                      _mapController.move(
                        _mapController.camera.center,
                        _mapController.camera.zoom + 1,
                      );
                    },
                    child: Container(
                      height: 35,
                      width: 35,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.black,
                          width: 0.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.zoom_in,
                        size: 25,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Zoom Out
                  GestureDetector(
                    onTap: () {
                      _mapController.move(
                        _mapController.camera.center,
                        _mapController.camera.zoom - 1,
                      );
                    },
                    child: Container(
                      height: 35,
                      width: 35,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.black,
                          width: 0.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.zoom_out,
                        size: 25,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Refresh (mainly for Lorawan module location)
                  GestureDetector(
                    onTap: _refresh,
                    child: Container(
                      height: 35,
                      width: 35,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.black,
                          width: 0.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.refresh,
                        size: 25,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        
        // --- FLOATING ACTION BUTTON (SOS) ---
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: role == "Rescuee"
          ? _buildCitizenSOSButton()
          : _buildRescuerAlertButton(),
        bottomNavigationBar: CustomBottomNav(
          currentIndex: 1, // profile page index
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
