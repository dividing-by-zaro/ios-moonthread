from fastapi import Depends, FastAPI, HTTPException, Request
from fastapi.security import APIKeyHeader

from app.config import settings
from app.routes.periods import router as periods_router

app = FastAPI(title="Period Tracker API")

api_key_header = APIKeyHeader(name="X-API-Key", auto_error=False)


async def verify_api_key(api_key: str | None = Depends(api_key_header)):
    if api_key != settings.api_key:
        raise HTTPException(status_code=401, detail="Invalid or missing API key")


@app.get("/health")
async def health():
    return {"status": "ok"}


app.include_router(periods_router, dependencies=[Depends(verify_api_key)])
