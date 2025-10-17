// assignment_map_page.dart
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mobilepos/models/assignment.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:mobilepos/views/task.dart';

class AssignmentMapPage extends StatefulWidget {
  final String assignmentName;
  final List<Shop> shops;
  final List<Task> tasks;

  const AssignmentMapPage({
    super.key,
    required this.assignmentName,
    required this.shops,
    required this.tasks,
  });

  @override
  State<AssignmentMapPage> createState() => _AssignmentMapPageState();
}

class _AssignmentMapPageState extends State<AssignmentMapPage> {
  final Completer<GoogleMapController> _controller = Completer();

  // map state
  CameraPosition? _initialCamera;
  double _currentZoom = 14.0;
  bool _hasCenteredOnce = false;
  bool _userInteracted = false;

  // markers / polyline
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  // location
  LatLng? _currentLocation; // google_maps_flutter LatLng
  LatLng? _nearestShop; // google_maps_flutter LatLng
  LatLng? _lastLocation; // for GPS jitter filtering
  double? _distanceKm;
  double? _timeMinutes;

  late final Location _location;
  StreamSubscription<LocationData>? _locationSubscription;

  @override
  void initState() {
    super.initState();
    _setupMarkers();
    _initLocation();
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }

  void _setupMarkers() {
    final validShops =
        widget.shops.where((s) => s.latitude != 0.0 && s.longitude != 0.0).toList();

    if (validShops.isNotEmpty) {
      final first = validShops.first;
      _initialCamera = CameraPosition(
        target: LatLng(first.latitude!, first.longitude!),
        zoom: _currentZoom,
      );

      for (final shop in validShops) {
        final id = 'shop_${shop.id}';
        _markers.add(
          Marker(
            markerId: MarkerId(id),
            position: LatLng(shop.latitude!, shop.longitude!),
            infoWindow: InfoWindow(
              title: shop.name ?? 'Shop ${shop.id}',
              snippet: shop.street ?? '',
            ),
          ),
        );
      }
    } else {
      _initialCamera = const CameraPosition(target: LatLng(0.0, 0.0), zoom: 2);
    }
  }

  Future<void> _initLocation() async {
    _location = Location();

    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) return;
    }

    PermissionStatus permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return;
    }

    try {
      final loc = await _location.getLocation();
      if (loc.latitude != null && loc.longitude != null) {
        _onLocationUpdate(loc);
        if (!_hasCenteredOnce) {
          _moveCamera(_currentLocation!, _currentZoom, animate: false);
          _hasCenteredOnce = true;
        }
      }
    } catch (e) {
      // ignore initial errors
    }

    _locationSubscription = _location.onLocationChanged.listen(_onLocationUpdate);
  }

  void _onLocationUpdate(LocationData newLoc) async {
    if (newLoc.latitude == null || newLoc.longitude == null) return;

    final newLatLng = LatLng(newLoc.latitude!, newLoc.longitude!);

    // Only update if user moved more than 15 meters
    if (_lastLocation != null) {
      final movedDistance = _haversineKm(_lastLocation!, newLatLng) * 1000; // meters
      if (movedDistance < 15) return; // ignore GPS jitter
    }

    _lastLocation = newLatLng;
    _currentLocation = newLatLng;

    await _updateUserMarkerAndRoute();

    if (!_userInteracted && !_hasCenteredOnce) {
      _moveCamera(_currentLocation!, _currentZoom);
      _hasCenteredOnce = true;
    }
  }

  Future<void> _updateUserMarkerAndRoute() async {
    if (_currentLocation == null) return;

    // update user marker
    print(_currentLocation);
    _markers.removeWhere((m) => m.markerId.value == 'user_location');
    _markers.add(
      Marker(
        markerId: const MarkerId('user_location'),
        position: _currentLocation!,
        infoWindow: const InfoWindow(title: 'You'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ),
    );

    // compute nearest shop
    _computeNearestShop();

    // draw route using Directions API
    _polylines.removeWhere((p) => p.polylineId.value == 'route_to_nearest');
    if (_nearestShop != null) {
      await _drawRoute(_currentLocation!, _nearestShop!);
    }

    if (mounted) setState(() {});
  }

  void _computeNearestShop() {
    if (_currentLocation == null || _markers.isEmpty) return;

    double minDist = double.infinity;
    LatLng? nearest;

    for (final m in _markers) {
      if (m.markerId.value == 'user_location') continue;
      final shopLatLng = LatLng(m.position.latitude, m.position.longitude);
      final d = _haversineKm(_currentLocation!, shopLatLng);
      if (d < minDist) {
        minDist = d;
        nearest = shopLatLng;
      }
    }

    _nearestShop = nearest;
    _distanceKm = minDist;
    _timeMinutes = (minDist / 40) * 60; // 40 km/h default
  }

  Future<void> _moveCamera(LatLng target, double zoom, {bool animate = true}) async {
    final controller = await _controller.future;
    final update = CameraUpdate.newLatLngZoom(target, zoom);
    if (animate) {
      await controller.animateCamera(update);
    } else {
      await controller.moveCamera(update);
    }
  }

  /// Draw route from Directions API
  Future<void> _drawRoute(LatLng origin, LatLng destination) async {
    const apiKey = 'YOUR_GOOGLE_MAPS_API_KEY';
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/directions/json'
      '?origin=${origin.latitude},${origin.longitude}'
      '&destination=${destination.latitude},${destination.longitude}'
      '&mode=driving'
      '&key=$apiKey',
    );

    final response = await http.get(url);
    final data = jsonDecode(response.body);

    if (data['status'] == 'OK') {
      final points = data['routes'][0]['overview_polyline']['points'];
      final polylineCoordinates = _decodePolyline(points);

      setState(() {
        _polylines.add(
          Polyline(
            polylineId: const PolylineId('route_to_nearest'),
            points: polylineCoordinates,
            color: Colors.blue,
            width: 6,
          ),
        );
      });
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> poly = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      poly.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return poly;
  }

  double _haversineKm(LatLng a, LatLng b) {
    const R = 6371;
    final dLat = _deg2rad(b.latitude - a.latitude);
    final dLon = _deg2rad(b.longitude - a.longitude);
    final lat1 = _deg2rad(a.latitude);
    final lat2 = _deg2rad(b.latitude);
    final sinDLat = sin(dLat / 2);
    final sinDLon = sin(dLon / 2);
    final hav = sinDLat * sinDLat + sinDLon * sinDLon * cos(lat1) * cos(lat2);
    final c = 2 * atan2(sqrt(hav), sqrt(1 - hav));
    return R * c;
  }

  double _deg2rad(double deg) => deg * (pi / 180);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Map — ${widget.assignmentName}')),
      body: GoogleMap(
        initialCameraPosition: _initialCamera ?? const CameraPosition(target: LatLng(0, 0), zoom: 2),
        markers: _markers,
        polylines: _polylines,
        myLocationEnabled: false,
        zoomControlsEnabled: false,
        onMapCreated: (gmController) {
          if (!_controller.isCompleted) _controller.complete(gmController);
        },
        onCameraMove: (position) {
          _currentZoom = position.zoom;
          _userInteracted = true;
        },
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_markers.isNotEmpty)
          FloatingActionButton(
            heroTag: 'center',
            onPressed: () {
              if (_currentLocation != null) {
                _userInteracted = false;
                _moveCamera(_currentLocation!, _currentZoom);
              }
            },
            child: const Icon(Icons.my_location),
          ),
        ],
      ),
      bottomNavigationBar: _markers.isNotEmpty
        ? Container(
            color: Colors.white,
            height: 120,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: widget.shops.length,
              itemBuilder: (context, index) {
                final shop = widget.shops[index];
                final shopLatLng = LatLng(shop.latitude!, shop.longitude!);

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(12),
                      minimumSize: const Size(120, 100),
                      backgroundColor: Colors.blueAccent,
                    ),
                    onPressed: () async {
                      if (_currentLocation == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Current location not available')));
                        return;
                      }

                      // distance in meters
                      final distanceMeters = _haversineKm(_currentLocation!, shopLatLng) * 1000;

                      if (distanceMeters <= 6) {
                        // inside 20 feet (~6 meters)
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Check-in'),
                            content: Text(
                              'You are within ${distanceMeters.toStringAsFixed(1)} meters of ${shop.name}. You can check in.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context); // close dialog first
                                },
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context); // close dialog
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => TaskPage(shop: shop, tasks: widget.tasks,), // redirect to your new page
                                    ),
                                  );
                                },
                                child: const Text('Check-in'),
                              ),
                            ],
                          ),
                        );

                      } else {
                        // too far
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Too far'),
                            content: Text('You are ${distanceMeters.toStringAsFixed(1)} meters away from ${shop.name}. Cannot check in. Go to shop to check in.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                        );

                        // move camera to shop
                        _moveCamera(shopLatLng, _currentZoom);
                      }
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.store, size: 32, color: Colors.white),
                        const SizedBox(height: 8),
                        Text(
                          shop.name ?? 'Shop ${shop.id}',
                          style: const TextStyle(color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          )
        : null,

    );
  }
}
