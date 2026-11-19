from datetime import datetime, timezone
from typing import Dict, Any
from fastapi import APIRouter, Depends, HTTPException, status, Request
from sqlalchemy.orm import Session
from app.database import get_db
from app.models.models import User, Consent, CustomerProfile, AuditLog
from app.schemas.schemas import (
    RequestOtpIn, VerifyOtpIn, RegisterIn, LoginIn, TokenOut, UserOut, RefreshTokenIn
)
from app.core.security import (
    verify_password, get_password_hash, create_access_token,
    create_refresh_token, decode_token
)
from app.core.deps import get_current_user
from app.services.otp import OTPService

router = APIRouter(prefix="/auth", tags=["Authentication"])

@router.post("/request-otp")
def request_otp(data: RequestOtpIn):
    clean_mobile = data.mobile.strip().replace(" ", "").replace("-", "")
    if len(clean_mobile) < 10:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Please provide a valid 10-digit mobile number."
        )
    otp = OTPService.generate_otp(clean_mobile)
    return {
        "message": "OTP sent successfully to your mobile number.",
        "mobile": clean_mobile,
        "dev_otp": otp  # Included for dev/testing ease
    }

@router.post("/verify-otp", response_model=TokenOut)
def verify_otp(data: VerifyOtpIn, request: Request, db: Session = Depends(get_db)):
    clean_mobile = data.mobile.strip().replace(" ", "").replace("-", "")
    is_valid = OTPService.verify_otp(clean_mobile, data.otp)
    if not is_valid:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid or expired OTP. Please enter the correct 6-digit code."
        )

    # Find or create user
    user = db.query(User).filter(User.mobile == clean_mobile).first()
    if not user:
        user = User(
            name=f"User {clean_mobile[-4:]}",
            mobile=clean_mobile,
            role="customer",
            is_active=True,
            created_at=datetime.now(timezone.utc)
        )
        db.add(user)
        db.flush()

        # DPDP Consent
        client_ip = request.client.host if request.client else "127.0.0.1"
        consent = Consent(
            user_id=user.id,
            consent_text_version="DPDP_ACT_2023_V1",
            accepted_at=datetime.now(timezone.utc),
            ip=client_ip
        )
        db.add(consent)

        # Blank Customer Profile
        profile = CustomerProfile(
            user_id=user.id,
            onboarding_step=1,
            completed=False,
            updated_at=datetime.now(timezone.utc)
        )
        db.add(profile)
        db.commit()
        db.refresh(user)

    access_token = create_access_token({"sub": str(user.id), "role": user.role})
    refresh_token = create_refresh_token({"sub": str(user.id), "role": user.role})

    return TokenOut(
        access_token=access_token,
        refresh_token=refresh_token,
        user=UserOut.model_validate(user)
    )

@router.post("/register", response_model=TokenOut)
def register(data: RegisterIn, request: Request, db: Session = Depends(get_db)):
    if not data.consent_accepted:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Consent for data processing under DPDP Act 2023 is mandatory to continue."
        )

    if not data.email and not data.mobile:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Either email or mobile number must be provided."
        )

    # Check duplicates
    if data.email:
        existing_email = db.query(User).filter(User.email == data.email.lower()).first()
        if existing_email:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="An account with this email already exists."
            )

    clean_mobile = data.mobile.strip().replace(" ", "").replace("-", "") if data.mobile else None
    if clean_mobile:
        existing_mobile = db.query(User).filter(User.mobile == clean_mobile).first()
        if existing_mobile:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="An account with this mobile number already exists."
            )

    pwd_hash = get_password_hash(data.password) if data.password else None
    user = User(
        name=data.name.strip(),
        email=data.email.lower() if data.email else None,
        mobile=clean_mobile,
        role="customer",
        password_hash=pwd_hash,
        is_active=True,
        created_at=datetime.now(timezone.utc)
    )
    db.add(user)
    db.flush()

    # DPDP Consent
    client_ip = request.client.host if request.client else "127.0.0.1"
    consent = Consent(
        user_id=user.id,
        consent_text_version="DPDP_ACT_2023_V1",
        accepted_at=datetime.now(timezone.utc),
        ip=client_ip
    )
    db.add(consent)

    # Blank Customer Profile
    profile = CustomerProfile(
        user_id=user.id,
        onboarding_step=1,
        completed=False,
        updated_at=datetime.now(timezone.utc)
    )
    db.add(profile)
    db.commit()
    db.refresh(user)

    access_token = create_access_token({"sub": str(user.id), "role": user.role})
    refresh_token = create_refresh_token({"sub": str(user.id), "role": user.role})

    return TokenOut(
        access_token=access_token,
        refresh_token=refresh_token,
        user=UserOut.model_validate(user)
    )

@router.post("/login", response_model=TokenOut)
def login(data: LoginIn, db: Session = Depends(get_db)):
    identifier = data.email_or_mobile.strip().lower()
    clean_mobile = identifier.replace(" ", "").replace("-", "")

    user = db.query(User).filter(
        (User.email == identifier) | (User.mobile == clean_mobile) | (User.mobile == identifier)
    ).first()

    if not user or not user.password_hash:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email/mobile or password."
        )

    if not verify_password(data.password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email/mobile or password."
        )

    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Account is inactive. Please contact support."
        )

    access_token = create_access_token({"sub": str(user.id), "role": user.role})
    refresh_token = create_refresh_token({"sub": str(user.id), "role": user.role})

    return TokenOut(
        access_token=access_token,
        refresh_token=refresh_token,
        user=UserOut.model_validate(user)
    )

@router.post("/refresh", response_model=Dict[str, str])
def refresh_token_endpoint(data: RefreshTokenIn, db: Session = Depends(get_db)):
    payload = decode_token(data.refresh_token)
    if not payload or payload.get("type") != "refresh":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired refresh token."
        )

    user_id = payload.get("sub")
    user = db.query(User).filter(User.id == int(user_id)).first()
    if not user or not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found or inactive."
        )

    new_access_token = create_access_token({"sub": str(user.id), "role": user.role})
    return {
        "access_token": new_access_token,
        "token_type": "bearer"
    }

@router.get("/me", response_model=UserOut)
def get_me(current_user: User = Depends(get_current_user)):
    return UserOut.model_validate(current_user)
