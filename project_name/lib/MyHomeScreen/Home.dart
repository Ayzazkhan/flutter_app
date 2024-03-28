import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:timer_builder/timer_builder.dart';

class Home extends StatefulWidget {
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final Completer<GoogleMapController> _controller = Completer();

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(24.89398, 67.08803), // Initial position set to Bahria University Karachi
    zoom: 15, // Zoom level adjusted for better visibility
  );

  final List<Marker> MyMarker = [];
  final List<Marker> MarkerList = [
    const Marker(
      markerId: MarkerId('First'),
      position: LatLng(24.8936304, 67.0877557),
      infoWindow: InfoWindow(
        title: 'Bahria University',
      ),
    ),
  ];

  List<LatLng> bukCampusBoundaries = [
  //  Define the boundary points of Bahria University Karachi campus
    LatLng(24.904843, 67.200169),
    LatLng(24.905253, 67.202188),
    LatLng(24.904486, 67.202620),
    LatLng(24.903265, 67.199914),
    LatLng(24.904843, 67.200169),

    // LatLng(24.904843, 67.200169),
    // LatLng(24.903052, 67.200017),
    // LatLng(24.904354, 67.199597),
    // LatLng(24.904843, 67.200169),
  ];

  Set<Polygon> _bukCampusPolygons = {}; // Set to store the polygon boundary

  // Geofence related variables
  bool _isInsideGeofence = false;

  // Timer related variables
  Timer? _timer;
  int _secondsInsideGeofence = 0;

  @override
  void initState() {
    super.initState();
    MyMarker.addAll(MarkerList);
    _bukCampusPolygons.add(
      Polygon(
        polygonId: PolygonId('buk_campus_polygon'),
        points: bukCampusBoundaries,
        fillColor: Colors.yellow.withOpacity(0.3),
        strokeColor: Colors.blue,
        strokeWidth: 2,
      ),
    );
    _startGeofencing();
  }

  void _startGeofencing() {
    Geolocator.getPositionStream().listen((Position position) {
      bool isInside = _isInsideGeofenceArea(position);
      if (isInside != _isInsideGeofence) {
        setState(() {
          _isInsideGeofence = isInside;
          if (_isInsideGeofence) {
            _startTimer();
          } else {
            _stopTimer();
          }
        });
      }
    });
  }

  bool _isInsideGeofenceArea(Position position) {
    LatLng deviceLocation = LatLng(position.latitude, position.longitude);
    return _isPointInPolygon(deviceLocation, bukCampusBoundaries);
  }

  bool _isPointInPolygon(LatLng point, List<LatLng> polygonPoints) {
    bool isInside = false;
    int count = 0;
    int numPoints = polygonPoints.length;

    for (int i = 0, j = numPoints - 1; i < numPoints; j = i++) {
      double xi = polygonPoints[i].latitude;
      double yi = polygonPoints[i].longitude;
      double xj = polygonPoints[j].latitude;
      double yj = polygonPoints[j].longitude;

      bool intersect = ((yi > point.longitude) != (yj > point.longitude)) &&
          (point.latitude <
              (xj - xi) * (point.longitude - yi) / (yj - yi) + xi);

      if (intersect) count++;
    }

    isInside = count % 2 == 1;
    return isInside;
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _secondsInsideGeofence++;
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _secondsInsideGeofence = 0;
  }
  Future<Position> getUserLocation() async{
    await Geolocator.requestPermission().then((value){

    }).onError((error, stackTrace) {
      print('error$error');
    });

    return await Geolocator.getCurrentPosition();
  }
  packData(){
    getUserLocation().then((value)
    async{
      print('my location');
      print('${value.latitude} ${value.longitude}');
      MyMarker.add(
          Marker(markerId: const MarkerId('location'),
              position: LatLng(value.latitude,value.longitude),
              infoWindow: InfoWindow(
                title: 'My location',
              )
          )
      );
      CameraPosition cameraPosition = CameraPosition(
        target:LatLng(value.latitude,value.longitude),
        zoom: 18,
      );
      final GoogleMapController controller = await _controller.future;
      controller.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
      setState(() {

      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Timer'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Show timer at the top of the screen
            TimerBuilder.periodic(Duration(seconds: 1), builder: (context) {
              return Text('Time inside Bahria University: $_secondsInsideGeofence seconds');
            }),
            // Google Map widget and other UI components...
            Expanded(
              child: GoogleMap(
                initialCameraPosition: _initialPosition,
                mapType: MapType.satellite,
                markers: Set<Marker>.of(MyMarker),
                onMapCreated: (GoogleMapController controller) {
                  _controller.complete(controller);
                },
                polygons: _bukCampusPolygons,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Action button onPressed event
          packData();
        },
        child: Icon(Icons.location_searching),
      ),
    );
  }
}
