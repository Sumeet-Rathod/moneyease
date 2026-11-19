from datetime import datetime, timezone
from typing import List, Dict, Any
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import func
from app.database import get_db
from app.models.models import User, Lead, CustomerProfile, Doubt, Setting, FAQ, AuditLog
from app.schemas.schemas import (
    UserOut, ExecutiveCreateIn, ExecutiveUpdateIn, FAQCreateIn, FAQUpdateIn,
    SettingsUpdateIn, AdminStatsOut
)
from app.core.deps import require_admin
from app.core.security import get_password_hash

router = APIRouter(prefix="/admin", tags=["Admin Portal"])

# ----------------- Executive Management -----------------
@router.get("/executives", response_model=List[UserOut])
def list_executives(
    current_user: User = Depends(require_admin),
    db: Session = Depends(get_db)
):
    execs = db.query(User).filter(User.role == "executive").order_by(User.created_at.desc()).all()
    return [UserOut.model_validate(e) for e in execs]

@router.post("/executives", response_model=UserOut)
def create_executive(
    data: ExecutiveCreateIn,
    current_user: User = Depends(require_admin),
    db: Session = Depends(get_db)
):
    existing = db.query(User).filter(User.email == data.email.lower()).first()
    if existing:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Email already registered.")

    new_exec = User(
        name=data.name.strip(),
        email=data.email.lower(),
        mobile=data.mobile.strip(),
        role="executive",
        password_hash=get_password_hash(data.password),
        is_active=True,
        created_at=datetime.now(timezone.utc)
    )
    db.add(new_exec)
    db.commit()
    db.refresh(new_exec)
    return UserOut.model_validate(new_exec)

@router.put("/executives/{exec_id}", response_model=UserOut)
def update_executive(
    exec_id: int,
    data: ExecutiveUpdateIn,
    current_user: User = Depends(require_admin),
    db: Session = Depends(get_db)
):
    target = db.query(User).filter(User.id == exec_id, User.role == "executive").first()
    if not target:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Executive not found.")

    if data.name:
        target.name = data.name.strip()
    if data.email:
        target.email = data.email.lower()
    if data.mobile:
        target.mobile = data.mobile.strip()
    if data.is_active is not None:
        target.is_active = data.is_active
    if data.password:
        target.password_hash = get_password_hash(data.password)

    db.commit()
    db.refresh(target)
    return UserOut.model_validate(target)

# ----------------- FAQ Management -----------------
@router.get("/faqs")
def list_faqs(
    current_user: User = Depends(require_admin),
    db: Session = Depends(get_db)
):
    return db.query(FAQ).all()

@router.post("/faqs")
def create_faq(
    data: FAQCreateIn,
    current_user: User = Depends(require_admin),
    db: Session = Depends(get_db)
):
    faq = FAQ(
        question=data.question.strip(),
        answer=data.answer.strip(),
        keywords=data.keywords.strip() if data.keywords else "",
        category=data.category.strip(),
        is_active=data.is_active
    )
    db.add(faq)
    db.commit()
    db.refresh(faq)
    return faq

@router.put("/faqs/{faq_id}")
def update_faq(
    faq_id: int,
    data: FAQUpdateIn,
    current_user: User = Depends(require_admin),
    db: Session = Depends(get_db)
):
    faq = db.query(FAQ).filter(FAQ.id == faq_id).first()
    if not faq:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="FAQ not found.")

    if data.question:
        faq.question = data.question.strip()
    if data.answer:
        faq.answer = data.answer.strip()
    if data.keywords is not None:
        faq.keywords = data.keywords.strip()
    if data.category:
        faq.category = data.category.strip()
    if data.is_active is not None:
        faq.is_active = data.is_active

    db.commit()
    db.refresh(faq)
    return faq

@router.delete("/faqs/{faq_id}")
def delete_faq(
    faq_id: int,
    current_user: User = Depends(require_admin),
    db: Session = Depends(get_db)
):
    faq = db.query(FAQ).filter(FAQ.id == faq_id).first()
    if not faq:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="FAQ not found.")
    db.delete(faq)
    db.commit()
    return {"message": "FAQ deleted successfully."}

# ----------------- Settings & Rates -----------------
@router.get("/settings")
def get_settings(
    current_user: User = Depends(require_admin),
    db: Session = Depends(get_db)
):
    settings_records = db.query(Setting).all()
    return {s.key: s.value for s in settings_records}

@router.put("/settings")
def update_settings(
    data: SettingsUpdateIn,
    current_user: User = Depends(require_admin),
    db: Session = Depends(get_db)
):
    for item in data.settings:
        s = db.query(Setting).filter(Setting.key == item.key).first()
        if s:
            s.value = item.value
        else:
            db.add(Setting(key=item.key, value=item.value))
    db.commit()
    return {"message": "Settings updated successfully."}

# ----------------- Lead Reassignment -----------------
@router.patch("/leads/{lead_id}/assign")
def reassign_lead(
    lead_id: int,
    assignment: dict,
    current_user: User = Depends(require_admin),
    db: Session = Depends(get_db)
):
    exec_id = assignment.get("executive_id")
    if not exec_id:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="executive_id is required.")

    lead = db.query(Lead).filter(Lead.id == lead_id).first()
    if not lead:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Lead not found.")

    target_exec = db.query(User).filter(User.id == exec_id, User.role == "executive", User.is_active == True).first()
    if not target_exec:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Active executive not found.")

    lead.assigned_executive_id = target_exec.id
    lead.updated_at = datetime.now(timezone.utc)

    db.add(AuditLog(
        actor_id=current_user.id,
        action=f"LEAD_REASSIGNED_TO_EXEC_{target_exec.id}",
        entity="leads",
        entity_id=lead.id,
        created_at=datetime.now(timezone.utc)
    ))
    db.commit()
    return {"message": f"Lead #{lead_id} successfully reassigned to {target_exec.name}."}

# ----------------- Overall Statistics -----------------
@router.get("/stats", response_model=AdminStatsOut)
def get_admin_stats(
    current_user: User = Depends(require_admin),
    db: Session = Depends(get_db)
):
    total_signups = db.query(func.count(User.id)).filter(User.role == "customer").scalar() or 0
    completed_profiles = db.query(func.count(CustomerProfile.id)).filter(CustomerProfile.completed == True).scalar() or 0
    completion_pct = round((completed_profiles / total_signups * 100.0) if total_signups > 0 else 0.0, 1)

    total_leads = db.query(func.count(Lead.id)).scalar() or 0

    # Leads by status
    status_counts = (
        db.query(Lead.status, func.count(Lead.id))
        .group_by(Lead.status)
        .all()
    )
    leads_by_status = {s: c for s, c in status_counts}

    # Leads per executive
    executives = db.query(User).filter(User.role == "executive").all()
    leads_per_exec = []
    for e in executives:
        count = db.query(func.count(Lead.id)).filter(Lead.assigned_executive_id == e.id).scalar() or 0
        leads_per_exec.append({
            "executive_id": e.id,
            "executive_name": e.name,
            "leads_count": count
        })

    # Top doubt topics
    top_topics_query = (
        db.query(Doubt.topic, func.count(Doubt.id))
        .filter(Doubt.topic != None)
        .group_by(Doubt.topic)
        .order_by(func.count(Doubt.id).desc())
        .limit(10)
        .all()
    )
    top_doubt_topics = [{"topic": t, "count": c} for t, c in top_topics_query if t]

    # Conversion rate (Converted leads / total leads)
    converted_count = leads_by_status.get("Converted", 0)
    conv_rate = round((converted_count / total_leads * 100.0) if total_leads > 0 else 0.0, 1)

    return AdminStatsOut(
        total_signups=total_signups,
        onboarding_completed_count=completed_profiles,
        onboarding_completion_pct=completion_pct,
        total_leads=total_leads,
        leads_by_status=leads_by_status,
        leads_per_executive=leads_per_exec,
        top_doubt_topics=top_doubt_topics,
        conversion_rate_pct=conv_rate
    )
