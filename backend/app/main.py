from datetime import datetime, timezone
from uuid import uuid4

from fastapi import FastAPI, Header, HTTPException
from pydantic import BaseModel, Field


app = FastAPI(
    title="UrbanGuard API",
    version="0.1.0",
)


READINGS = []
ALERTS = []
HELP_REQUESTS = []


class Reading(BaseModel):
    readingId: str = Field(
        default_factory=lambda: str(uuid4())
    )
    areaId: str
    nodeId: str
    timestamp: datetime
    waterLevelCm: float
    riseRateCmPerMin: float = 0
    rainfallMmHr: float | None = None
    batteryPercent: float
    sensorHealth: str = "HEALTHY"
    riskState: str = "NORMAL"
    confidence: float = 0


class Alert(BaseModel):
    alertId: str = Field(
        default_factory=lambda: str(uuid4())
    )
    areaId: str
    severity: str
    urgency: str
    certainty: str
    instruction: str
    shelterId: str | None = None
    issuedAt: datetime
    expiresAt: datetime
    language: str = "en"
    status: str = "ACTIVE"


class HelpRequest(BaseModel):
    reportId: str = Field(
        default_factory=lambda: str(uuid4())
    )
    userId: str | None = None
    type: str
    priority: str = "NORMAL"
    latitude: float
    longitude: float
    accuracyM: float | None = None
    peopleCount: int = Field(
        default=1,
        ge=1,
    )
    needs: list[str] = Field(
        default_factory=list
    )
    message: str | None = None
    createdAt: datetime = Field(
        default_factory=lambda:
            datetime.now(timezone.utc)
    )
    status: str = "OPEN"


@app.get("/health")
def health():
    return {
        "status": "ok",
    }


@app.post("/api/v1/readings")
def create_reading(
    reading: Reading,
):
    READINGS.append(
        reading.model_dump(mode="json")
    )

    return {
        "accepted": True,
        "readingId": reading.readingId,
    }


@app.get("/api/v1/areas/{area_id}/live-status")
def live_status(
    area_id: str,
):
    latest = [
        reading
        for reading in reversed(READINGS)
        if reading["areaId"] == area_id
    ][:20]

    return {
        "areaId": area_id,
        "readings": latest,
    }


@app.post("/api/v1/alerts")
def create_alert(
    alert: Alert,
):
    ALERTS.append(
        alert.model_dump(mode="json")
    )

    return {
        "accepted": True,
        "alertId": alert.alertId,
    }


@app.get("/api/v1/areas/{area_id}/alerts")
def get_alerts(
    area_id: str,
):
    return [
        alert
        for alert in ALERTS
        if alert["areaId"] == area_id
        and alert["status"] == "ACTIVE"
    ]


@app.post("/api/v1/help-requests")
def create_help_request(
    report: HelpRequest,
    idempotency_key: str | None = Header(
        default=None,
        alias="Idempotency-Key",
    ),
):
    if idempotency_key is not None:
        if idempotency_key != report.reportId:
            raise HTTPException(
                status_code=400,
                detail=(
                    "Idempotency-Key must match "
                    "reportId."
                ),
            )

    existing = next(
        (
            item
            for item in HELP_REQUESTS
            if item["reportId"] == report.reportId
        ),
        None,
    )

    if existing is not None:
        return {
            "accepted": True,
            "reportId": report.reportId,
            "duplicate": True,
            "status": "ALREADY_EXISTS",
        }

    HELP_REQUESTS.append(
        report.model_dump(mode="json")
    )

    return {
        "accepted": True,
        "reportId": report.reportId,
        "duplicate": False,
        "status": "ACCEPTED",
    }


@app.get(
    "/api/v1/areas/{area_id}/help-requests"
)
def get_help_requests(
    area_id: str,
):
    # MVP: area filtering by polygon is intentionally
    # deferred to PostGIS.
    return HELP_REQUESTS