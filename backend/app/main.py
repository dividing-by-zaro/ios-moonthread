import hmac

from fastapi import Depends, FastAPI, HTTPException, Request
from fastapi.security import APIKeyHeader
from slowapi import Limiter
from slowapi.errors import RateLimitExceeded
from slowapi.util import get_remote_address
from starlette.responses import JSONResponse

from app.config import settings
from app.routes.periods import router as periods_router

limiter = Limiter(key_func=get_remote_address)

app = FastAPI(title="Period Tracker API", docs_url=None, redoc_url=None, openapi_url=None)
app.state.limiter = limiter


@app.exception_handler(RateLimitExceeded)
async def rate_limit_handler(request: Request, exc: RateLimitExceeded):
    return JSONResponse(status_code=429, content={"detail": "Rate limit exceeded"})


api_key_header = APIKeyHeader(name="X-API-Key", auto_error=False)


@limiter.limit("10/minute")
async def verify_api_key(
    request: Request, api_key: str | None = Depends(api_key_header)
):
    if api_key is None or not hmac.compare_digest(api_key, settings.api_key):
        raise HTTPException(status_code=401, detail="Invalid or missing API key")


@app.get("/health")
async def health():
    return {"status": "ok"}


app.include_router(periods_router, dependencies=[Depends(verify_api_key)])
