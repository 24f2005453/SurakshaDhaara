# Architecture and Risk Register

## Data path
Sensor -> local validation -> Wi-Fi MQTT/HTTPS (routine) and LoRa (verified emergency) -> gateway -> siren/PA/LED + backend -> citizen app/authority portal.

## Why two communications paths?
- Wi-Fi/cloud: rich telemetry, dashboards, configuration.
- LoRa: low-bandwidth resilient emergency packets when normal backhaul is unavailable.
- Local gateway: keeps public warning functional without cloud access.

## Risk register
| Component | Failure/risk | Mitigation |
|---|---|---|
| Ultrasonic sensor | Splash, fog, debris, bad mounting | Persistence filter + secondary confirmation + health checks + manual inspection |
| Single sensor | False alarm / missed event | Dual sensing for critical state; hysteresis; rate-of-rise checks |
| ESP32 | Brownout/watchdog lockup | Hardware watchdog, brownout handling, heartbeat, safe reboot |
| Wi-Fi | Router/power/backhaul outage | LoRa emergency path + gateway local rules + SD buffering |
| LoRa | Packet collision/interference/range gap | ACK/retry, sequence IDs, relay nodes, store-and-forward, link test |
| Gateway | Power loss | UPS/battery, local storage, watchdog, periodic health heartbeat |
| Siren/PA | Relay/amplifier failure | Output self-test, health status, redundant visual LED, volunteer fallback |
| Cloud | Internet outage/service failure | Gateway operates locally; local event log; later sync with idempotent IDs |
| GPS | Poor indoor/urban accuracy | Snap-to-road, accuracy threshold, manual map position fallback |
| Offline map | Stale road/shelter data | Versioned safety pack, expiry timestamp, authority update, visible last-updated time |
| Routing | Unsafe route due to stale hazard | Hard-block authority closures; conservative hazard penalties; prominent advisory notice |
| Shelter | Full/closed/incorrect status | Capacity/status timestamps; fallback shelters; authority override |
| Citizen report | Spam/duplicates | UUID, rate limits, dedupe, moderation, offline queue |
| Alert authenticity | Spoofed packets | Device keys/signatures, allowlisted node IDs, replay protection |
| Privacy | Precise citizen location exposure | Minimal data, role-based access, encryption, retention policy |
| OTA update | Malicious/broken firmware | Signed firmware, staged rollout, rollback image |
| Power | Solar/battery depletion | Battery telemetry, low-power sampling, low-battery warning, maintenance queue |
| Localization | Translation ambiguity | Pre-approved emergency messages; human review; no machine-generated critical wording |
| AI | Overconfidence / opaque decision | AI advisory only; deterministic safety trigger path |
| OSM/QGIS data | Licensing/geometry issues | Attribute sources, keep license notices, validate topology before deployment |
