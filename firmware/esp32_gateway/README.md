# ESP32/Raspberry Pi gateway contract

1. Receive LoRa packets.
2. Verify node allowlist, sequence/replay window, CRC/authentication.
3. Deduplicate by `(nodeId, seq)`.
4. ACK valid packets.
5. Persist events to SD before actuation.
6. Apply deterministic alert state machine.
7. Drive siren/PA/LED through isolated relay/MOSFET hardware.
8. Upload buffered events via MQTT/HTTPS when backhaul exists.
9. Maintain RTC and gateway health heartbeat.

For a production design, use authenticated cryptographic packets rather than relying on CRC alone.
