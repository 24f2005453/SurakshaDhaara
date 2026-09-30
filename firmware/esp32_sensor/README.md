# ESP32 sensor node firmware contract

Implement in Arduino/PlatformIO.

## Sampling
1. Read ultrasonic distance every 5-10 s.
2. Convert distance to water level using calibrated tank/channel geometry.
3. Maintain rolling window.
4. Reject impossible jumps/outliers.
5. Compute rate of rise.
6. Confirm Warning/Critical using persistence + secondary sensor.

## Routine transport
MQTT over Wi-Fi -> `/flood/{areaId}/{nodeId}/reading`.

## Emergency transport
LoRa packet fields:
`version|packetType|nodeId|areaId|seq|timestamp|waterLevel|riseRate|risk|confidence|battery|crc`

Critical packets: send immediately, wait for ACK, retry with backoff, retain locally until acknowledged.

Never drive a public siren directly from an unverified single sensor sample.
