import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

enum GpsStatus {
  available,
  permissionDenied,
  unavailable,
  outsideCoverage,
  poorAccuracy,
}

class GpsSafetyResult {
  final GpsStatus status;
  final Position? position;
  final String? nearestNode;
  final double? distanceToNearestNodeM;

  const GpsSafetyResult({
    required this.status,
    this.position,
    this.nearestNode,
    this.distanceToNearestNodeM,
  });

  bool get canRoute => status == GpsStatus.available;
}

class GpsSafetyService {
  static const double maxCoverageDistanceM = 5000.0;
  static const double maxAcceptableAccuracyM = 100.0;

  final Distance _distance = const Distance();

  Future<GpsSafetyResult> getCurrentLocation({
    required Map<String, ({double lat, double lon})>
        roadCoordinates,
  }) async {
    final serviceEnabled =
        await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      return const GpsSafetyResult(
        status: GpsStatus.unavailable,
      );
    }

    var permission =
        await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission =
          await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return const GpsSafetyResult(
        status: GpsStatus.permissionDenied,
      );
    }

    final position =
        await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );

    if (position.accuracy > maxAcceptableAccuracyM) {
      return GpsSafetyResult(
        status: GpsStatus.poorAccuracy,
        position: position,
      );
    }

    if (roadCoordinates.isEmpty) {
      return GpsSafetyResult(
        status: GpsStatus.outsideCoverage,
        position: position,
      );
    }

    String? nearestNode;
    double? nearestDistance;

    for (final entry in roadCoordinates.entries) {
      final node = LatLng(
        entry.value.lat,
        entry.value.lon,
      );

      final distanceM = _distance.as(
        LengthUnit.Meter,
        LatLng(
          position.latitude,
          position.longitude,
        ),
        node,
      );

      if (nearestDistance == null ||
          distanceM < nearestDistance) {
        nearestDistance = distanceM;
        nearestNode = entry.key;
      }
    }

    if (nearestNode == null ||
        nearestDistance == null ||
        nearestDistance >
            maxCoverageDistanceM) {
      return GpsSafetyResult(
        status: GpsStatus.outsideCoverage,
        position: position,
        nearestNode: nearestNode,
        distanceToNearestNodeM:
            nearestDistance,
      );
    }

    return GpsSafetyResult(
      status: GpsStatus.available,
      position: position,
      nearestNode: nearestNode,
      distanceToNearestNodeM:
          nearestDistance,
    );
  }
}