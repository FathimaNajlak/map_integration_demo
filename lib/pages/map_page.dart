import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:map_demo/const/keys.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final Location _locationcontroller = Location();
  final Completer<GoogleMapController> mapController =
      Completer<GoogleMapController>();
  static const LatLng _pGooglePlex = LatLng(37.4223, -122.0848);
  static const LatLng _pApplePark = LatLng(37.3346, -122.0090);
  LatLng? _currentP;

  Map<PolylineId, Polyline> polylines = {};
  @override
  @override
  void initState() {
    super.initState();
    getLocationUpdates(); // Only starts location tracking, does not fetch route immediately
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _currentP == null
          ? Center(
              child: CircularProgressIndicator(),
            )
          : GoogleMap(
              onMapCreated: (GoogleMapController controller) =>
                  mapController.complete(controller),
              initialCameraPosition:
                  CameraPosition(target: _pGooglePlex, zoom: 14.0),
              markers: {
                Marker(
                    markerId: MarkerId("_sourceLocation"),
                    icon: BitmapDescriptor.defaultMarker,
                    position: _pGooglePlex),
                Marker(
                    markerId: MarkerId("_destinationLocation"),
                    icon: BitmapDescriptor.defaultMarker,
                    position: _pApplePark),
                Marker(
                    markerId: MarkerId("_currentLocation"),
                    icon: BitmapDescriptor.defaultMarker,
                    position: _currentP!)
              },
              polylines: Set<Polyline>.of(polylines.values),
            ),
    );
  }

  Future<void> cameraToPosition(LatLng pos) async {
    final GoogleMapController controller = await mapController.future;
    CameraPosition newCameraPosition = CameraPosition(
      target: pos,
      zoom: 13,
    );
    await controller.animateCamera(
      CameraUpdate.newCameraPosition(newCameraPosition),
    );
  }

  Future<void> getLocationUpdates() async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    serviceEnabled = await _locationcontroller.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _locationcontroller.requestService();
      if (!serviceEnabled) {
        print("Location services are disabled.");
        return;
      }
    }

    permissionGranted = await _locationcontroller.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _locationcontroller.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        print("Location permission denied.");
        return;
      }
    }

    _locationcontroller.onLocationChanged
        .listen((LocationData currentLocation) {
      if (currentLocation.latitude != null &&
          currentLocation.longitude != null) {
        setState(() {
          _currentP =
              LatLng(currentLocation.latitude!, currentLocation.longitude!);
        });

        // Move the camera to user's location
        cameraToPosition(_currentP!);

        // Fetch polyline route now that we have the user's current location
        getPolylinePoints();
      }
    });
  }

  Future<void> getPolylinePoints() async {
    if (_currentP == null) {
      print("User location is not available yet.");
      return;
    }

    print(
        "Fetching polyline from ${_currentP!.latitude}, ${_currentP!.longitude} to ${_pApplePark.latitude}, ${_pApplePark.longitude}");

    List<LatLng> polylineCoordinates = [];
    PolylinePoints polylinePoints = PolylinePoints();

    // Use _currentP instead of _pGooglePlex
    PolylineRequest request = PolylineRequest(
      origin: PointLatLng(
          _currentP!.latitude, _currentP!.longitude), // User's current location
      destination: PointLatLng(_pApplePark.latitude, _pApplePark.longitude),
      mode: TravelMode.driving,
    );

    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      googleApiKey: API_KEY,
      request: request,
    );

    if (result.points.isNotEmpty) {
      for (PointLatLng point in result.points) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      }

      // ✅ Debugging print moved here
      print("Polyline Coordinates: $polylineCoordinates");

      generatePolyLineFromPoints(polylineCoordinates);
    } else {
      print("Error fetching polyline: ${result.errorMessage}");
    }
  }

  void generatePolyLineFromPoints(List<LatLng> polylineCoordinates) async {
    PolylineId id = PolylineId("poly");
    Polyline polyline = Polyline(
        polylineId: id,
        color: Colors.black,
        points: polylineCoordinates,
        width: 8);
    setState(() {
      polylines[id] = polyline;
    });
  }
}
