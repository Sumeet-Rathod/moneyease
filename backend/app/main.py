from contextlib import asynccontextmanager
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded

from app.config import settings
from app.database import engine, Base
from app.seed import seed_database

# Routers
from app.routers import (
    auth,
    onboarding,
    risk,
    goals,
    doubts,
    leads,
    reports,
    executive,
    admin,
    notifications
)

limiter = Limiter(key_func=get_remote_address)

@asynccontextmanager
async def lifespan(app: FastAPI):
    yield

app = FastAPI(
    title=settings.PROJECT_NAME,
    version=settings.VERSION,
    description=(
        "MoneyEase is an AMFI-registered Mutual Fund Distribution & Wealth Management "
        "mobile-first platform tailored for Indian youth (18–35).\n\n"
        f"**Compliance Notice:** {settings.COMPLIANCE_DISCLAIMER}\n"
        f"**Firm:** {settings.FIRM_NAME} | **ARN:** {settings.ARN_NUMBER}"
    ),
    openapi_url=f"{settings.API_V1_STR}/openapi.json",
    docs_url="/docs",
    redoc_url="/redoc",
    lifespan=lifespan
)

app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

# CORS Middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Mount all versioned API routers
app.include_router(auth.router, prefix=settings.API_V1_STR)
app.include_router(onboarding.router, prefix=settings.API_V1_STR)
app.include_router(risk.router, prefix=settings.API_V1_STR)
app.include_router(goals.router, prefix=settings.API_V1_STR)
app.include_router(doubts.router, prefix=settings.API_V1_STR)
app.include_router(leads.router, prefix=settings.API_V1_STR)
app.include_router(reports.router, prefix=settings.API_V1_STR)
app.include_router(executive.router, prefix=settings.API_V1_STR)
app.include_router(admin.router, prefix=settings.API_V1_STR)
app.include_router(notifications.router, prefix=settings.API_V1_STR)

@app.get("/", tags=["General"])
async def root_info():
    return {
        "app": settings.PROJECT_NAME,
        "version": settings.VERSION,
        "firm": settings.FIRM_NAME,
        "arn": settings.ARN_NUMBER,
        "docs": "/docs",
        "compliance_disclaimer": settings.COMPLIANCE_DISCLAIMER
    }

@app.get("/health", tags=["General"])
async def health_check():
    return {
        "status": "healthy",
        "firm": settings.FIRM_NAME,
        "arn": settings.ARN_NUMBER,
        "database": "connected"
    }
