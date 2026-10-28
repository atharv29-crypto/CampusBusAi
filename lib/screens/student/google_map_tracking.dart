import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class _RouteStop {
  final String name;
  final LatLng point;
  const _RouteStop(this.name, this.point);
}

class GoogleMapTracking extends StatefulWidget {
  const GoogleMapTracking({super.key});

  @override
  State<GoogleMapTracking> createState() => _GoogleMapTrackingState();
}

class _GoogleMapTrackingState extends State<GoogleMapTracking> {
  final MapController _mapController = MapController();

  // Stops and coordinates supplied earlier for the Lonand -> Yashoda route.
  // Tambe is left out until its exact coordinate is confirmed.
  static const List<_RouteStop> _stops = [
    _RouteStop('Lonand', LatLng(18.044076715321413, 74.190706244364)),
    _RouteStop('Koparde Phata', LatLng(17.965745951444216, 74.16670933013405)),
    _RouteStop('Salpe', LatLng(17.95385614371621, 74.16652026164522)),
    _RouteStop('Adaki Phata', LatLng(17.9097882697773, 74.15098985861472)),
    _RouteStop('Wathar', LatLng(17.885611860193144, 74.13794359408968)),
    _RouteStop('Deur', LatLng(17.85228222369379, 74.1173442290501)),
    _RouteStop('Pimpode Khurd', LatLng(17.833654117660213, 74.10449907833612)),
    _RouteStop('Ambawade', LatLng(17.81836302541664, 74.093058552444)),
    _RouteStop('Revadi Phata', LatLng(17.806082704644794, 74.0838672602306)),
    _RouteStop('Shivtar', LatLng(17.780158472356174, 74.06324031340611)),
    _RouteStop(
      'Yashoda Technical Campus',
      LatLng(17.72885215607223, 74.0184843148415),
    ),
  ];

  List<LatLng> _route = [];
  LatLng? _busPosition;

  Timer? _timer;
  int _animationIndex = 0;

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRoadRoute();
  }

  Future<void> _loadRoadRoute() async {
    _timer?.cancel();

    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      // OSRM expects longitude,latitude order. Include every known stop
      // so the road route follows the stop sequence.
      final coordinates = _stops
          .map((stop) => '${stop.point.longitude},${stop.point.latitude}')
          .join(';');

      final uri = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '$coordinates?overview=full&geometries=geojson&steps=false',
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw Exception('Routing service error: ${response.statusCode}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      final routes = data['routes'] as List?;

      if (data['code'] != 'Ok' || routes == null || routes.isEmpty) {
        throw Exception('No drivable road route was found.');
      }

      final geometry = routes.first['geometry'] as Map<String, dynamic>;

      final coordinatesList = geometry['coordinates'] as List;

      final roadPoints = coordinatesList.map((coordinate) {
        final pair = coordinate as List;

        return LatLng((pair[1] as num).toDouble(), (pair[0] as num).toDouble());
      }).toList();

      if (roadPoints.length < 2) {
        throw Exception('The route returned too few coordinates.');
      }

      if (!mounted) return;

      setState(() {
        _route = roadPoints;
        _busPosition = roadPoints.first;
        _animationIndex = 0;
        _loading = false;
        _error = null;
      });

      // Fit the complete route inside the map.
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints(roadPoints),
          padding: const EdgeInsets.all(45),
        ),
      );

      _startDemoAnimation();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  // Demo animation only. This is NOT the bus's real GPS location.
  void _startDemoAnimation() {
    _timer?.cancel();

    if (_route.length < 2) return;

    _timer = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (!mounted || _route.length < 2) return;

      setState(() {
        _animationIndex++;

        if (_animationIndex >= _route.length) {
          _animationIndex = 0;
        }

        _busPosition = _route[_animationIndex];
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 400,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: LatLng(17.88, 74.10),
              initialZoom: 9,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.campusbusai360.app',
              ),

              // Road-following route returned by OSRM.
              if (_route.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _route,
                      strokeWidth: 5,
                      color: Colors.orange,
                    ),
                  ],
                ),

              // Mark every known stop on the route.
              MarkerLayer(
                markers: [
                  for (int i = 0; i < _stops.length; i++)
                    Marker(
                      point: _stops[i].point,
                      width: 48,
                      height: 54,
                      child: Tooltip(
                        message: '${i + 1}. ${_stops[i].name}',
                        child: Icon(
                          i == 0
                              ? Icons.trip_origin
                              : i == _stops.length - 1
                              ? Icons.school
                              : Icons.location_on,
                          color: i == 0
                              ? Colors.green
                              : i == _stops.length - 1
                              ? Colors.red
                              : Colors.deepOrange,
                          size: i == _stops.length - 1 ? 36 : 32,
                        ),
                      ),
                    ),
                ],
              ),

              // Animated demo bus marker.
              if (_busPosition != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _busPosition!,
                      width: 54,
                      height: 54,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.orange, width: 3),
                          boxShadow: const [
                            BoxShadow(color: Color(0x33000000), blurRadius: 8),
                          ],
                        ),
                        child: const Icon(
                          Icons.directions_bus_rounded,
                          color: Colors.orange,
                          size: 30,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // Route status.
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Card(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    Icon(
                      _loading
                          ? Icons.hourglass_top
                          : _error == null
                          ? Icons.check_circle
                          : Icons.error_outline,
                      color: _error == null ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _loading
                            ? 'LOADING LONAND → CAMPUS ROUTE...'
                            : _error == null
                            ? 'LONAND BUS • DEMO'
                            : 'ROUTE UNAVAILABLE',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Error and retry.
          if (_error != null)
            Center(
              child: Card(
                margin: const EdgeInsets.all(20),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: _loadRoadRoute,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Route endpoint labels.
          Positioned(
            left: 10,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '🟢 Lonand',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 3),
                  Text(
                    '🔴 Yashoda Technical Campus',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Intermediate stops marked on map',
                    style: TextStyle(fontSize: 10, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ),

          const Positioned(
            right: 0,
            bottom: 0,
            child: DecoratedBox(
              decoration: BoxDecoration(color: Colors.white70),
              child: Padding(
                padding: EdgeInsets.all(4),
                child: Text(
                  '© OpenStreetMap contributors',
                  style: TextStyle(fontSize: 10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
