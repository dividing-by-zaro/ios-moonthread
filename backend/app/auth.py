import hmac

from fastapi import Depends, HTTPException, Request
from fastapi.security import APIKeyHeader
from slowapi import Limiter
from slowapi.util import get_remote_address

from app.config import settings

limiter = Limiter(key_func=get_remote_address)

api_key_header = APIKeyHeader(name="X-API-Key", auto_error=False)


@limiter.limit("10/minute")
async def verify_api_key(
    request: Request, api_key: str | None = Depends(api_key_header)
) -> str:
    """Return 'user' or 'demo' based on which key matches."""
    if api_key is None:
        raise HTTPException(status_code=401, detail="Invalid or missing API key")

    if hmac.compare_digest(api_key, settings.api_key):
        return "user"

    if settings.demo_api_key is not None and hmac.compare_digest(
        api_key, settings.demo_api_key
    ):
        return "demo"

    raise HTTPException(status_code=401, detail="Invalid or missing API key")
