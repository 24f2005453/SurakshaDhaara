class RoadEdge {
  final String id;
  final String from;
  final String to;
  final double distanceM;
  final double riskScore;
  final bool blocked;
  const RoadEdge({required this.id, required this.from, required this.to, required this.distanceM, this.riskScore = 0, this.blocked = false});

  double get cost => distanceM + (5000 * riskScore) + (blocked ? 1000000000 : 0);
}
