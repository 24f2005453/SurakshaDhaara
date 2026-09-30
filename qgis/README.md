# QGIS workflow

QGIS is the authoring/validation tool, not the citizen runtime.

## Layers
- roads
- shelters
- flood_zones
- hazard_closures
- sensor_nodes
- gateways
- safe_zones

## Export
Create a pilot-area GeoPackage/GeoJSON, validate geometry, then export a compact offline pack consumed by Flutter.

## Validation checklist
- No self-intersecting road geometries.
- Shelter coordinates verified in field.
- Road graph connectivity checked.
- Closure segments map to routable edge IDs.
- Every shelter has status/capacity metadata.
- Every dataset has `version`, `generated_at`, and `expires_at`.
