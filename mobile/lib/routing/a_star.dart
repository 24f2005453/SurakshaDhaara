import 'dart:math' as math;

import '../models/road.dart';

class RouteResult {
  final List<String> nodes;
  final double cost;

  const RouteResult(this.nodes, this.cost);
}

/// Offline A* router for the UrbanGuard local road graph.
///
/// All edge costs are in metres (plus safety penalties).
/// Blocked roads are excluded from routing.
class AStarRouter {
  final Map<String, List<RoadEdge>> graph;
  final Map<String, ({double lat, double lon})> coordinates;

  AStarRouter(this.graph, this.coordinates);

  /// Straight-line distance between two coordinates in metres.
  double _heuristic(String a, String b) {
    final p = coordinates[a];
    final q = coordinates[b];

    if (p == null || q == null) {
      return 0;
    }

    const metersPerDegreeLat = 111320.0;

    final meanLat = ((p.lat + q.lat) / 2) * math.pi / 180.0;
    final metersPerDegreeLon =
        metersPerDegreeLat * math.cos(meanLat);

    final dLat = (p.lat - q.lat) * metersPerDegreeLat;
    final dLon = (p.lon - q.lon) * metersPerDegreeLon;

    return math.sqrt((dLat * dLat) + (dLon * dLon));
  }

  RouteResult? findRoute(String start, String goal) {
    if (!coordinates.containsKey(start) ||
        !coordinates.containsKey(goal)) {
      return null;
    }

    final open = <String>{start};

    final cameFrom = <String, String>{};

    final gScore = <String, double>{
      start: 0,
    };

    final fScore = <String, double>{
      start: _heuristic(start, goal),
    };

    while (open.isNotEmpty) {
      String current = open.first;

      for (final node in open) {
        if ((fScore[node] ?? double.infinity) <
            (fScore[current] ?? double.infinity)) {
          current = node;
        }
      }

      if (current == goal) {
        return _reconstructRoute(
          cameFrom,
          current,
          gScore[current] ?? double.infinity,
        );
      }

      open.remove(current);

      for (final edge in graph[current] ?? const <RoadEdge>[]) {
        // A flooded/blocked road must never be used.
        if (edge.blocked) {
          continue;
        }

        final tentativeG =
            (gScore[current] ?? double.infinity) + edge.cost;

        final existingG =
            gScore[edge.to] ?? double.infinity;

        if (tentativeG < existingG) {
          cameFrom[edge.to] = current;
          gScore[edge.to] = tentativeG;

          fScore[edge.to] =
              tentativeG + _heuristic(edge.to, goal);

          open.add(edge.to);
        }
      }
    }

    // No safe route exists.
    return null;
  }

  RouteResult _reconstructRoute(
    Map<String, String> cameFrom,
    String current,
    double cost,
  ) {
    final path = <String>[current];

    var node = current;

    while (cameFrom.containsKey(node)) {
      node = cameFrom[node]!;
      path.add(node);
    }

    return RouteResult(
      path.reversed.toList(),
      cost,
    );
  }
}