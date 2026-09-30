import 'package:flutter_test/flutter_test.dart';

import 'package:urbangard/models/road.dart';
import 'package:urbangard/routing/a_star.dart';

void main() {
  test('A* avoids a blocked road', () {
    final coordinates = <String, ({double lat, double lon})>{
      'A': (lat: 13.0000, lon: 80.0000),
      'B': (lat: 13.0010, lon: 80.0000),
      'C': (lat: 13.0020, lon: 80.0000),
      'D': (lat: 13.0020, lon: 80.0020),
    };

    final graph = <String, List<RoadEdge>>{
      'A': [
        const RoadEdge(
          id: 'R1',
          from: 'A',
          to: 'B',
          distanceM: 100,
        ),
      ],
      'B': [
        const RoadEdge(
          id: 'R2',
          from: 'B',
          to: 'C',
          distanceM: 100,
          blocked: true,
        ),
        const RoadEdge(
          id: 'R4',
          from: 'B',
          to: 'D',
          distanceM: 250,
        ),
      ],
      'C': [
        const RoadEdge(
          id: 'R3',
          from: 'C',
          to: 'D',
          distanceM: 100,
        ),
      ],
    };

    final router = AStarRouter(graph, coordinates);

    final result = router.findRoute('A', 'D');

    expect(result, isNotNull);
    expect(result!.nodes, ['A', 'B', 'D']);
  });
}