# Next implementation order

1. Replace `sample_offline_pack.json` with QGIS-exported pilot data.
2. Add MBTiles/vector-tile offline map package and render it with `flutter_map`.
3. Build a `RoadGraphRepository` from the QGIS road layer.
4. Replace demo buttons with real map, GPS, shelter, alert and report screens.
5. Add API client + offline sync queue.
6. Add FCM for connected notifications.
7. Add gateway/LoRa integration after the mobile offline path is stable.
