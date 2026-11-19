import os
from pydantic_settings import BaseSettings
from cryptography.fernet import Fernet

class Settings(BaseSettings):
    PROJECT_NAME: str = "MoneyEase"
    VERSION: str = "1.0.0"
    API_V1_STR: str = "/api/v1"
    
    # AMFI Registered MFD Firm Configuration (Single source of truth)
    FIRM_NAME: str = "MoneyEase Wealth Advisors"
    ARN_NUMBER: str = "ARN-189452"
    SUPPORT_PHONE: str = "+91 98765 43210"
    SUPPORT_EMAIL: str = "support@moneyease.in"
    
    # Mandatory SEBI / AMFI Compliance Disclaimer
    COMPLIANCE_DISCLAIMER: str = (
        "Mutual fund investments are subject to market risks, read all scheme related "
        "documents carefully. Projections are illustrative and based on assumed returns; "
        "they are not guaranteed."
    )
    
    # Security & JWT
    SECRET_KEY: str = "moneyease-super-secure-jwt-secret-key-production-ready-2026"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24  # 1 day
    REFRESH_TOKEN_EXPIRE_DAYS: int = 30
    
    # PAN Encryption Key (Fernet 32-byte url-safe base64)
    # Default is a generated valid Fernet key for local dev
    FERNET_KEY: str = os.getenv("FERNET_KEY", "uE2N_l4-O9xP7G2j5K8y1W4r6T8u0Z2x4C6v8B0n2M4=")
    
    # Database (Resolved to backend directory to be working-directory independent)
    DATABASE_URL: str = os.getenv(
        "DATABASE_URL",
        f"sqlite:///{os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'moneyease.db')).replace(os.sep, '/')}"
    )
    
    # External integrations
    GEMINI_API_KEY: str = os.getenv("GEMINI_API_KEY", "")
    
    # SMTP Email Configuration (If not configured, emails log to console)
    SMTP_HOST: str = os.getenv("SMTP_HOST", "")
    SMTP_PORT: int = int(os.getenv("SMTP_PORT", "587"))
    SMTP_USER: str = os.getenv("SMTP_USER", "")
    SMTP_PASSWORD: str = os.getenv("SMTP_PASSWORD", "")
    SMTP_FROM: str = os.getenv("SMTP_FROM", "notifications@moneyease.in")
    
    # CORS
    CORS_ORIGINS: list[str] = [
        "http://localhost",
        "http://localhost:3000",
        "http://localhost:8000",
        "http://localhost:8080",
        "http://127.0.0.1",
        "http://127.0.0.1:3000",
        "http://127.0.0.1:8000",
        "http://127.0.0.1:8080"
    ]
    
    model_config = {
        "env_file": ".env",
        "extra": "allow"
    }

settings = Settings()
