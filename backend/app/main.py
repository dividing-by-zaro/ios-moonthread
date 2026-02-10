from fastapi import FastAPI, Request
from slowapi.errors import RateLimitExceeded
from starlette.responses import JSONResponse

from app.auth import limiter
from app.routes.periods import router as periods_router

app = FastAPI(title="Period Tracker API", docs_url=None, redoc_url=None, openapi_url=None)
app.state.limiter = limiter


@app.exception_handler(RateLimitExceeded)
async def rate_limit_handler(request: Request, exc: RateLimitExceeded):
    return JSONResponse(status_code=429, content={"detail": "Rate limit exceeded"})


@app.get("/health")
async def health():
    return {"status": "ok"}


app.include_router(periods_router)
