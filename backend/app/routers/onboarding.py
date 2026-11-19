from datetime import datetime, date, timezone
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.database import get_db
from app.models.models import User, CustomerProfile
from app.schemas.schemas import CustomerProfileOut, ProfileStepUpdateIn
from app.core.deps import get_current_user
from app.core.security import encrypt_pan, mask_pan, validate_pan

router = APIRouter(prefix="/profile", tags=["Customer Onboarding"])

def _build_profile_out(profile: CustomerProfile, user: User) -> CustomerProfileOut:
    age = None
    if profile.dob:
        today = date.today()
        age = today.year - profile.dob.year - ((today.month, today.day) < (profile.dob.month, profile.dob.day))

    pan_masked = None
    if profile.has_pan and profile.pan_encrypted:
        pan_masked = mask_pan(profile.pan_encrypted, is_encrypted=True)

    return CustomerProfileOut(
        id=profile.id,
        user_id=profile.user_id,
        name=user.name,
        email=user.email,
        mobile=user.mobile,
        dob=profile.dob,
        age=age,
        gender=profile.gender,
        city=profile.city,
        occupation=profile.occupation,
        income_range=profile.income_range,
        monthly_expenses=profile.monthly_expenses,
        savings=profile.savings,
        loans_emi=profile.loans_emi,
        dependents=profile.dependents,
        existing_investments=profile.existing_investments,
        has_pan=profile.has_pan,
        pan_masked=pan_masked,
        has_bank=profile.has_bank,
        has_aadhaar_linked_mobile=profile.has_aadhaar_linked_mobile,
        onboarding_step=profile.onboarding_step,
        completed=profile.completed,
        updated_at=profile.updated_at
    )

@router.get("", response_model=CustomerProfileOut)
def get_my_profile(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    profile = db.query(CustomerProfile).filter(CustomerProfile.user_id == current_user.id).first()
    if not profile:
        profile = CustomerProfile(
            user_id=current_user.id,
            onboarding_step=1,
            completed=False,
            updated_at=datetime.now(timezone.utc)
        )
        db.add(profile)
        db.commit()
        db.refresh(profile)

    return _build_profile_out(profile, current_user)

@router.put("", response_model=CustomerProfileOut)
def update_profile(
    data: ProfileStepUpdateIn,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    profile = db.query(CustomerProfile).filter(CustomerProfile.user_id == current_user.id).first()
    if not profile:
        profile = CustomerProfile(user_id=current_user.id)
        db.add(profile)

    # Step 1: Basic
    if data.name:
        user_to_update = db.query(User).filter(User.id == current_user.id).first()
        if user_to_update:
            user_to_update.name = data.name.strip()
            current_user = user_to_update
    if data.dob is not None:
        profile.dob = data.dob
    if data.gender is not None:
        profile.gender = data.gender
    if data.city is not None:
        profile.city = data.city.strip()
    if data.occupation is not None:
        profile.occupation = data.occupation

    # Step 2: Income & Expenses
    if data.income_range is not None:
        profile.income_range = data.income_range
    if data.monthly_expenses is not None:
        profile.monthly_expenses = max(data.monthly_expenses, 0.0)
    if data.savings is not None:
        profile.savings = max(data.savings, 0.0)
    if data.loans_emi is not None:
        profile.loans_emi = max(data.loans_emi, 0.0)
    if data.dependents is not None:
        profile.dependents = max(data.dependents, 0)

    # Step 3: Investments
    if data.existing_investments is not None:
        profile.existing_investments = [item.model_dump() for item in data.existing_investments]

    # Step 4: KYC Readiness
    if data.has_pan is not None:
        profile.has_pan = data.has_pan
    if data.pan_number:
        clean_pan = data.pan_number.strip().upper()
        if not validate_pan(clean_pan):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid PAN format. PAN must be in the format AAAAA9999A (e.g. ABCDE1234F)."
            )
        profile.has_pan = True
        profile.pan_encrypted = encrypt_pan(clean_pan)

    if data.has_aadhaar_linked_mobile is not None:
        profile.has_aadhaar_linked_mobile = data.has_aadhaar_linked_mobile
    if data.has_bank is not None:
        profile.has_bank = data.has_bank

    if data.onboarding_step is not None:
        profile.onboarding_step = max(profile.onboarding_step, data.onboarding_step)
        if data.onboarding_step >= 7:
            profile.completed = True

    profile.updated_at = datetime.now(timezone.utc)
    db.commit()
    db.refresh(profile)

    return _build_profile_out(profile, current_user)

@router.put("/step/{n}", response_model=CustomerProfileOut)
def update_profile_step(
    n: int,
    data: ProfileStepUpdateIn,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    if n < 1 or n > 7:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Onboarding step must be between 1 and 7."
        )
    data.onboarding_step = n
    return update_profile(data=data, current_user=current_user, db=db)
