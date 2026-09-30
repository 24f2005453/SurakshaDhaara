# UrbanGuard Flood Safety MVP

A resilient flood warning + offline evacuation prototype based on the supplied technical report.

## MVP stack
- Mobile: Flutter/Dart, flutter_map, latlong2, geolocator, sqflite, connectivity_plus, flutter_local_notifications
- Maps/GIS: QGIS for authoring/validation; GeoJSON/SQLite on device; OpenStreetMap-derived data
- Routing: local road graph + A* with risk/closure penalties
- Backend: Python FastAPI, Pydantic, SQLite for MVP (PostgreSQL/PostGIS for deployment)
- Device comms: ESP32 + LoRa SX1262/SX1276; MQTT/HTTPS over Wi-Fi for routine telemetry
- Gateway: ESP32-S3/Raspberry Pi class gateway, LoRa receiver, SD local buffer, RTC, relay/MOSFET outputs
- Cloud messaging: FCM for connected citizen notifications
- Protocols: HTTPS, MQTT, LoRa packet protocol with ACK/retry/deduplication

## Build phases
1. Offline safety pack + map + GPS + shelters
2. Offline A* routing + hazard avoidance
3. Alert state machine + local notifications
4. Help/incident queue + synchronization
5. FastAPI backend + authority endpoints
6. ESP32 telemetry/LoRa integration
7. Gateway siren/PA control + buffering
8. QGIS data pipeline and field validation

## Important safety boundary
AI is not a sole public-warning trigger. Public alerts are driven by verified edge rules/approved authority logic. Offline routing is advisory and must exclude known closures/hazards.

## Source basis
The architecture and workflow are grounded in the supplied Resilient Last-Mile Flood Warning and Citizen Safety Ecosystem report.
