import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../models/road.dart';
import '../routing/a_star.dart';
import '../services/offline_store.dart';

class OfflineMapScreen extends StatefulWidget {
  const OfflineMapScreen({super.key});

  @override
  State<OfflineMapScreen> createState() => _OfflineMapScreenState();
}

class _OfflineMapScreenState extends State<OfflineMapScreen> {
  final OfflineStore _store = OfflineStore();
  final MapController _mapController = MapController();

  List<Map<String, dynamic>> _shelters = [];
  AStarData? _routingData;
  RouteResult? _route;

  Position? _currentPosition;
  String? _startNode;
  String _locationStatus = 'Locating device...';

  bool _loading = true;
  bool _r4Flooded = false;

  @override
  void initState() {
    super.initState();
    _loadOfflineData();
  }

  Future<void> _loadOfflineData() async {
    try {
      debugPrint('UrbanGuard: starting offline pack load');

      await _store.seedDemoPack();

      final shelters = await _store.getShelters();
      final routingData = await _store.getRoutingData();

      debugPrint(
        'UrbanGuard: loaded ${shelters.length} shelters',
      );

      if (!mounted) return;

      setState(() {
        _shelters = shelters;
        _routingData = routingData;
        _loading = false;
      });

      await _loadCurrentLocation();
    } catch (error, stackTrace) {
      debugPrint('UrbanGuard OFFLINE LOAD ERROR: $error');
      debugPrint('$stackTrace');

      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Offline data failed: $error',
          ),
          duration: const Duration(seconds: 10),
        ),
      );
    }
  }

  Future<void> _loadCurrentLocation() async {
    try {
      final serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        if (!mounted) return;

        setState(() {
          _locationStatus =
              'Location services are disabled.';
        });

        return;
      }

      var permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission =
            await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        if (!mounted) return;

        setState(() {
          _locationStatus =
              'Location permission denied.';
        });

        return;
      }

      if (permission ==
          LocationPermission.deniedForever) {
        if (!mounted) return;

        setState(() {
          _locationStatus =
              'Location permission permanently denied.';
        });

        return;
      }

      final position =
          await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (_routingData == null) return;

      final nearestNode = _nearestRoadNode(
        position.latitude,
        position.longitude,
      );

      if (!mounted) return;

      setState(() {
        _currentPosition = position;
        _startNode = nearestNode;
        _locationStatus = nearestNode == null
            ? 'No nearby road node.'
            : 'GPS → $nearestNode';
      });

      debugPrint(
        'UrbanGuard: GPS ${position.latitude}, '
        '${position.longitude}',
      );

      debugPrint(
        'UrbanGuard: nearest road node = '
        '$nearestNode',
      );
    } catch (error, stackTrace) {
      debugPrint(
        'UrbanGuard GPS ERROR: $error',
      );
      debugPrint('$stackTrace');

      if (!mounted) return;

      setState(() {
        _locationStatus =
            'Unable to obtain GPS location.';
      });
    }
  }

  Map<String, List<RoadEdge>>
      _graphWithCurrentHazards() {
    final data = _routingData!;

    final graph =
        <String, List<RoadEdge>>{};

    for (final entry in data.graph.entries) {
      graph[entry.key] =
          entry.value.map((edge) {
        if (_r4Flooded &&
            edge.id == 'R4') {
          return RoadEdge(
            id: edge.id,
            from: edge.from,
            to: edge.to,
            distanceM: edge.distanceM,
            riskScore: edge.riskScore,
            blocked: true,
          );
        }

        return edge;
      }).toList();
    }

    return graph;
  }

  String? _nearestRoadNode(
    double lat,
    double lon,
  ) {
    if (_routingData == null) {
      return null;
    }

    final coordinates =
        _routingData!.coordinates;

    String? nearest;
    var bestDistance =
        double.infinity;

    for (final entry
        in coordinates.entries) {
      final dLat =
          entry.value.lat - lat;

      final dLon =
          entry.value.lon - lon;

      final distanceSquared =
          (dLat * dLat) +
              (dLon * dLon);

      if (distanceSquared <
          bestDistance) {
        bestDistance =
            distanceSquared;
        nearest = entry.key;
      }
    }

    return nearest;
  }

  void _routeToShelter(
    Map<String, dynamic> shelter,
  ) {
    if (_routingData == null) {
      return;
    }

    if (_startNode == null) {
      _showMessage(
        'Current GPS location is not available.',
      );
      return;
    }

    final lat =
        (shelter['lat'] as num).toDouble();

    final lon =
        (shelter['lon'] as num).toDouble();

    final targetNode =
        _nearestRoadNode(lat, lon);

    if (targetNode == null) {
      _showMessage(
        'No road node found near this shelter.',
      );
      return;
    }

    final router = AStarRouter(
      _graphWithCurrentHazards(),
      _routingData!.coordinates,
    );

    final result = router.findRoute(
      _startNode!,
      targetNode,
    );

    if (result == null) {
      setState(() {
        _route = null;
      });

      _showMessage(
        'No safe route is currently available.',
      );

      return;
    }

    setState(() {
      _route = result;
    });

    _showMessage(
      'Route calculated: '
      '${result.nodes.join(' → ')}',
    );
  }

  void _routeToShelterB() {
    final shelter = _shelters.firstWhere(
      (shelter) =>
          shelter['id'] == 'S2',
      orElse: () =>
          <String, dynamic>{},
    );

    if (shelter.isEmpty) {
      _showMessage(
        'Demo Shelter B is unavailable.',
      );
      return;
    }

    _routeToShelter(shelter);
  }

  void _toggleFloodedR4() {
    setState(() {
      _r4Flooded = !_r4Flooded;
      _route = null;
    });

    if (_r4Flooded) {
      _showMessage(
        'R4 marked FLOODED. '
        'Recalculate the route.',
      );
    } else {
      _showMessage(
        'R4 reopened.',
      );
    }
  }

  List<Polyline> _buildRoadPolylines() {
    final data = _routingData!;

    final polylines =
        <Polyline>[];

    for (final edges
        in data.graph.values) {
      for (final edge in edges) {
        final from =
            data.coordinates[edge.from];

        final to =
            data.coordinates[edge.to];

        if (from == null ||
            to == null) {
          continue;
        }

        final blocked =
            edge.blocked ||
            (_r4Flooded &&
                edge.id == 'R4');

        polylines.add(
          Polyline(
            points: [
              LatLng(
                from.lat,
                from.lon,
              ),
              LatLng(
                to.lat,
                to.lon,
              ),
            ],
            strokeWidth:
                blocked ? 7 : 5,
            color: blocked
                ? Colors.red
                : Colors.blueGrey,
          ),
        );
      }
    }

    return polylines;
  }

  List<Polyline> _buildRoutePolyline() {
    if (_route == null ||
        _routingData == null) {
      return [];
    }

    final points =
        <LatLng>[];

    for (final node
        in _route!.nodes) {
      final coordinate =
          _routingData!
              .coordinates[node];

      if (coordinate == null) {
        continue;
      }

      points.add(
        LatLng(
          coordinate.lat,
          coordinate.lon,
        ),
      );
    }

    if (points.length < 2) {
      return [];
    }

    return [
      Polyline(
        points: points,
        strokeWidth: 10,
        color: Colors.green,
      ),
    ];
  }

  double _routeDistanceM() {
    if (_route == null ||
        _routingData == null) {
      return 0;
    }

    var distance = 0.0;

    for (var i = 0;
        i < _route!.nodes.length - 1;
        i++) {
      final from =
          _route!.nodes[i];

      final to =
          _route!.nodes[i + 1];

      final edges =
          _routingData!
              .graph[from] ??
          [];

      for (final edge
          in edges) {
        if (edge.to == to &&
            !edge.blocked) {
          if (!(_r4Flooded &&
              edge.id == 'R4')) {
            distance +=
                edge.distanceM;
            break;
          }
        }
      }
    }

    return distance;
  }

  void _showShelterInfo(
    Map<String, dynamic> shelter,
  ) {
    final name =
        shelter['name'] as String;

    final capacity =
        shelter['capacity'] as int;

    final occupancy =
        shelter['occupancy'] as int;

    final available =
        capacity - occupancy;

    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.all(20),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                Text(
                  name,
                  style:
                      Theme.of(context)
                          .textTheme
                          .headlineSmall,
                ),
                const SizedBox(
                  height: 12,
                ),
                Text(
                  'Capacity: $capacity',
                ),
                Text(
                  'Occupancy: $occupancy',
                ),
                Text(
                  'Available: $available',
                ),
                const SizedBox(
                  height: 16,
                ),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(
                      context,
                    );

                    _routeToShelter(
                      shelter,
                    );
                  },
                  icon: const Icon(
                    Icons.route,
                  ),
                  label: const Text(
                    'Route here',
                  ),
                ),
                const SizedBox(
                  height: 8,
                ),
                const Text(
                  'Source: local offline safety pack',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showMessage(
    String message,
  ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    const demoCenter =
        LatLng(
      13.0840,
      80.2717,
    );

    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Offline Safety Map',
          ),
        ),
        body: const Center(
          child:
              CircularProgressIndicator(),
        ),
      );
    }

    if (_routingData == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Offline Safety Map',
          ),
        ),
        body: const Center(
          child: Text(
            'Offline routing data unavailable.',
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Offline Safety Map',
        ),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController:
                _mapController,
            options:
                const MapOptions(
              initialCenter:
                  demoCenter,
              initialZoom: 15.5,
              minZoom: 13,
              maxZoom: 19,
            ),
            children: [
              PolylineLayer(
                polylines:
                    _buildRoadPolylines(),
              ),

              PolylineLayer(
                polylines:
                    _buildRoutePolyline(),
              ),

              MarkerLayer(
                markers:
                    _shelters.map(
                  (shelter) {
                    final lat =
                        (shelter['lat']
                                as num)
                            .toDouble();

                    final lon =
                        (shelter['lon']
                                as num)
                            .toDouble();

                    return Marker(
                      point: LatLng(
                        lat,
                        lon,
                      ),
                      width: 160,
                      height: 80,
                      child:
                          GestureDetector(
                        onTap: () {
                          _showShelterInfo(
                            shelter,
                          );
                        },
                        child:
                            const Icon(
                          Icons.home,
                          size: 44,
                          color:
                              Colors.green,
                        ),
                      ),
                    );
                  },
                ).toList(),
              ),

              if (_currentPosition !=
                  null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(
                        _currentPosition!
                            .latitude,
                        _currentPosition!
                            .longitude,
                      ),
                      width: 130,
                      height: 65,
                      child: Column(
                        children: [
                          const Icon(
                            Icons
                                .my_location,
                            size: 36,
                            color: Colors
                                .deepPurple,
                          ),
                          Container(
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            color:
                                Colors.white,
                            child: Text(
                              _startNode ==
                                      null
                                  ? 'GPS'
                                  : 'GPS → '
                                      '$_startNode',
                              style:
                                  const TextStyle(
                                fontSize: 11,
                                fontWeight:
                                    FontWeight
                                        .bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),

          Positioned(
            left: 12,
            right: 12,
            top: 12,
            child: Card(
              child: Padding(
                padding:
                    const EdgeInsets.all(
                  12,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    const Text(
                      'OFFLINE DEMO NETWORK',
                      style: TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    const SizedBox(
                      height: 4,
                    ),
                    Text(
                      _locationStatus,
                    ),
                    const SizedBox(
                      height: 4,
                    ),
                    Text(
                      _r4Flooded
                          ? 'R4: FLOODED'
                          : 'R4: OPEN',
                      style: TextStyle(
                        color: _r4Flooded
                            ? Colors.red
                            : Colors.green,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    if (_route !=
                        null) ...[
                      const SizedBox(
                        height: 4,
                      ),
                      Text(
                        'Route: '
                        '${_route!.nodes.join(' → ')}',
                      ),
                      Text(
                        'Distance: '
                        '${_routeDistanceM().round()} m',
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: SafeArea(
              child: Column(
                children: [
                  SizedBox(
                    width:
                        double.infinity,
                    child:
                        FilledButton.icon(
                      onPressed:
                          _routeToShelterB,
                      icon: const Icon(
                        Icons.route,
                      ),
                      label: const Text(
                        'Route to Demo Shelter B',
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  SizedBox(
                    width:
                        double.infinity,
                    child:
                        OutlinedButton
                            .icon(
                      onPressed:
                          _toggleFloodedR4,
                      icon: Icon(
                        _r4Flooded
                            ? Icons.water
                            : Icons.warning,
                      ),
                      label: Text(
                        _r4Flooded
                            ? 'Reopen R4'
                            : 'Simulate R4 Flooded',
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 4,
                  ),
                  const Text(
                    'Synthetic test data — not a live safety map',
                    style: TextStyle(
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}