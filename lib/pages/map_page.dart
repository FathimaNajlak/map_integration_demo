import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final Location _locationcontroller = Location();
  static const LatLng _sourceLocation = LatLng(11.2535, 75.9724);
  static const LatLng _destinationLocation = LatLng(11.2293, 75.9870);

  LatLng? _currentP; // Edavannappara, Kerala
  @override
  void initState() {
    super.initState();
    getLocationUpdates();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _currentP == null
          ? Center(
              child: CircularProgressIndicator(),
            )
          : GoogleMap(
              initialCameraPosition:
                  CameraPosition(target: _sourceLocation, zoom: 14.0),
              markers: {
                Marker(
                    markerId: MarkerId("_sourceLocation"),
                    icon: BitmapDescriptor.defaultMarker,
                    position: _sourceLocation),
                Marker(
                    markerId: MarkerId("_destinationLocation"),
                    icon: BitmapDescriptor.defaultMarker,
                    position: _destinationLocation),
                Marker(
                    markerId: MarkerId("_currentLocation"),
                    icon: BitmapDescriptor.defaultMarker,
                    position: _currentP!)
              },
            ),
    );
  }

  Future<void> getLocationUpdates() async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    // Check if location services are enabled
    serviceEnabled = await _locationcontroller.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _locationcontroller.requestService();
      if (!serviceEnabled) {
        print("Location services are disabled.");
        return;
      }
    }

    // Check for location permission
    permissionGranted = await _locationcontroller.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _locationcontroller.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        print("Location permission denied.");
        return;
      }
    }

    // Start listening to location updates
    _locationcontroller.onLocationChanged
        .listen((LocationData currentLocation) {
      if (currentLocation.latitude != null &&
          currentLocation.longitude != null) {
        setState(() {
          _currentP =
              LatLng(currentLocation.latitude!, currentLocation.longitude!);
        });
        print("Updated location: $_currentP");
      }
    });
  }
}
