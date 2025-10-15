import 'dart:async';
import 'package:cc206_bahanap/features/image_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  LatLng? userLocation;
  Marker? _userMarker;
  final List<Marker> _markers = [];
  StreamSubscription<Position>? _positionStreamSubscription;
  String userName = " ";

  @override
  void initState() {
    super.initState();
    DeviceOrientation.portraitUp;

    _fetchUserName();
    _initializeMarkers();
    _startLocationUpdates();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchCurrentLocation();
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

  Future<void> _fetchCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      LatLng newLocation = LatLng(position.latitude, position.longitude);
      setState(() {
        userLocation = newLocation;
        _updateUserMarker(newLocation);
        uploadLocation(newLocation);
      });
    } catch (e) {
      print("Error fetching current location: $e");
      _showErrorDialog('Unable to fetch current location.');
    }
  }

  void _initializeMarkers() async {
    _markers.clear();

    final String currentUserUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    try {
      QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance.collection('profiles').get();

      for (var doc in querySnapshot.docs) {
        String coordinates = doc['Coordinates'] ?? "0.0, 0.0";
        String fullName = doc['Name'] ?? "User";
        String uid = doc.id;

        if (uid == currentUserUid) {
          continue;
        }

        String imagePath = 'assets/images/dgfdfdsdsf2.jpg';

        List<String> latLng = coordinates.split(',');
        double latitude = double.tryParse(latLng[0].trim()) ?? 0.0;
        double longitude = double.tryParse(latLng[1].trim()) ?? 0.0;

        String userName = fullName.split(' ').first;

        _markers.add(
          Marker(
            width: 100.0,
            height: 100.0,
            point: LatLng(latitude, longitude),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.green,
                      width: 3.0,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 15,
                    backgroundImage: AssetImage(imagePath),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  userName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12.0,
                    fontFamily: 'SfPro',
                  ),
                ),
              ],
            ),
          ),
        );
      }

      setState(() {});
    } catch (e) {
      print("Error initializing markers: $e");
    }
  }

  Future<void> uploadLocation(LatLng loc) async {
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) {
      print("Error: User not logged in.");
      return;
    }

    try {
      String formattedLocation = "Lat: ${loc.latitude}, Lon: ${loc.longitude}";

      await FirebaseFirestore.instance.collection("profiles").doc(uid).set({
        "LiveCoordinates": formattedLocation,
        "timestamp": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print("Location updated successfully");
    } catch (e) {
      print("Error updating location: $e");
    }
  }

  Future<void> _searchLocation() async {
    String query = _searchController.text.trim();
    if (query.isNotEmpty) {
      try {
        List<Location> locations = await locationFromAddress(query);

        debugPrint("Geocoding result: $locations");

        if (locations.isEmpty) {
          _showErrorDialog('No locations found for "$query".');
        } else {
          Location location = locations.first;
          debugPrint(
              "Location found: ${location.latitude}, ${location.longitude}");

          _mapController.move(
              LatLng(location.latitude, location.longitude), 13.0);
        }
      } catch (e) {
        debugPrint("Geocoding error: $e");
        _showErrorDialog('Error: $e');
      }
    } else {
      _showErrorDialog('Please enter a valid address to search.');
    }
  }

  void _startLocationUpdates() {
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 1,
      ),
    ).listen((Position position) {
      LatLng newLocation = LatLng(position.latitude, position.longitude);
      setState(() {
        userLocation = newLocation;
        _updateUserMarker(newLocation);
        uploadLocation(newLocation);
      });
    });
  }

  void _updateUserMarker(LatLng location) {
    if (_userMarker != null) {
      _markers.remove(_userMarker);
    }

    final imageProvider =
        Provider.of<CustomImageProvider>(context, listen: false);
    final imageFile = imageProvider.imageFile;

    _userMarker = Marker(
        width: 100.0,
        height: 100.0,
        point: location,
        child: Column(
          children: [
            Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.blue,
                    width: 3.0,
                  ),
                ),
                child: CircleAvatar(
                  radius: 15,
                  backgroundImage: imageFile != null
                      ? FileImage(imageFile)
                      : const AssetImage('assets/images/dgfdfdsdsf2.jpg'),
                )),
            Text(
              userName,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12.0,
                  fontFamily: 'SfPro'),
            ),
          ],
        ));

    _markers.add(_userMarker!);
  }

  Future<void> _moveToUserLocation() async {
    if (userLocation != null) {
      _mapController.move(userLocation!, 18.0);
    } else {
      _showErrorDialog('User location is not available.');
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

  Future<void> showUserLocationString() async {
    if (userLocation != null) {
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
            userLocation!.latitude, userLocation!.longitude);
        Placemark place = placemarks.first;

        String address =
            '${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.country}';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Your location: $address')),
        );
      } catch (e) {
        debugPrint('Error retrieving address: $e');
        _showErrorDialog('Error retrieving address: $e');
      }
    } else {
      _showErrorDialog('User location is not available.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: userLocation ?? LatLng(10.7202, 122.5621),
                initialZoom: 13.0,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                  subdomains: ['a', 'b', 'c'],
                ),
                MarkerLayer(markers: _markers),
              ],
            ),
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
            Positioned(
              top: 100,
              right: 16,
              child: GestureDetector(
                onTap: _moveToUserLocation,
                child: Container(
                  height: 35,
                  width: 35,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 255, 255, 255),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.black,
                      width: 0.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.location_on_outlined,
                    size: 25.0,
                    color: Color(0xff32ade6),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 140,
              right: 16,
              child: Column(
                children: [
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
                        size: 30,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
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
                        size: 30,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        backgroundColor: Color(0xff32ade6),
        floatingActionButton: SizedBox(
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
        bottomNavigationBar: BottomAppBar(
          color: Color(0xff32ade6),
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
                      iconSize: 30,
                      color: Colors.white,
                      onPressed: () {
                        Navigator.pushNamed(context, 'dash');
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.map),
                      color: Colors.white,
                      onPressed: () {
                        if (ModalRoute.of(context)?.settings.name != 'map') {
                          Navigator.pushNamed(context, 'map');
                        }
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
