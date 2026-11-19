from datetime import datetime, timezone
from typing import List, Dict, Any
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.database import get_db
from app.models.models import User, Lead, LeadNote, CustomerProfile, Notification, AuditLog
from app.schemas.schemas import LeadSubmitIn, LeadStatusOut, CallbackRequestIn
from app.core.deps import get_current_user
from app.services.leads import assign_lead_round_robin
from app.config import settings

router = APIRouter(prefix="/leads", tags=["Customer Leads & Status"])

TRACKER_STAGES = [
    ("Submitted", "Profile and financial goals submitted to MoneyEase"),
    ("Assigned", "Dedicated AMFI-registered wealth advisor assigned"),
    ("Contacted", "Advisor reviewed profile and initiated contact"),
    ("Meeting Scheduled", "1-on-1 portfolio consultation meeting set"),
    ("Converted", "Financial blueprint approved and onboarding finalized")
]

def _build_tracker(status_str: str, submitted_at: datetime, updated_at: datetime) -> List[Dict[str, Any]]:
    order = ["Submitted", "Assigned", "Contacted", "Meeting Scheduled", "Converted"]
    current_idx = 0
    if status_str in order:
        current_idx = order.index(status_str)
    elif status_str == "Closed":
        current_idx = len(order) - 1

    steps = []
    for idx, (title, desc) in enumerate(TRACKER_STAGES):
        is_completed = idx <= current_idx
        is_current = idx == current_idx
        steps.append({
            "stage": title,
            "description": desc,
            "is_completed": is_completed,
            "is_current": is_current,
            "date": (submitted_at if idx == 0 else (updated_at if is_current else None))
        })
    return steps

@router.post("/submit", response_model=LeadStatusOut)
def submit_customer_profile(
    data: LeadSubmitIn,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    profile = db.query(CustomerProfile).filter(CustomerProfile.user_id == current_user.id).first()
    if profile:
        profile.completed = True
        profile.onboarding_step = 7
        profile.updated_at = datetime.now(timezone.utc)

    lead = db.query(Lead).filter(Lead.user_id == current_user.id).first()
    if not lead:
        lead = Lead(
            user_id=current_user.id,
            status="Submitted",
            submitted_at=datetime.now(timezone.utc),
            updated_at=datetime.now(timezone.utc)
        )
        db.add(lead)
        db.flush()
        assigned_exec = assign_lead_round_robin(db, lead)
    else:
        # Re-submission / update
        lead.updated_at = datetime.now(timezone.utc)
        if lead.status in ["Closed", "Converted"]:
            lead.status = "Submitted"
        db.add(AuditLog(
            actor_id=current_user.id,
            action="PROFILE_RESUBMITTED",
            entity="leads",
            entity_id=lead.id,
            created_at=datetime.now(timezone.utc)
        ))
        db.commit()
        assigned_exec = lead.assigned_executive

    if data.note:
        if assigned_exec:
            db.add(LeadNote(
                lead_id=lead.id,
                executive_id=assigned_exec.id,
                note=f"Customer Note on Submission: {data.note}",
                created_at=datetime.now(timezone.utc)
            ))
            db.commit()

    db.refresh(lead)

    return LeadStatusOut(
        lead_id=lead.id,
        status=lead.status,
        assigned_executive_name=assigned_exec.name if assigned_exec else None,
        assigned_executive_email=assigned_exec.email if assigned_exec else None,
        assigned_executive_phone=assigned_exec.mobile if assigned_exec else settings.SUPPORT_PHONE,
        submitted_at=lead.submitted_at,
        updated_at=lead.updated_at,
        tracker_steps=_build_tracker(lead.status, lead.submitted_at, lead.updated_at)
    )

@router.get("/my-status", response_model=LeadStatusOut)
def get_my_lead_status(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    lead = db.query(Lead).filter(Lead.user_id == current_user.id).first()
    if not lead:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="You haven't submitted your profile yet. Please complete onboarding and submit."
        )

    assigned_exec = lead.assigned_executive
    return LeadStatusOut(
        lead_id=lead.id,
        status=lead.status,
        assigned_executive_name=assigned_exec.name if assigned_exec else None,
        assigned_executive_email=assigned_exec.email if assigned_exec else None,
        assigned_executive_phone=assigned_exec.mobile if assigned_exec else settings.SUPPORT_PHONE,
        submitted_at=lead.submitted_at,
        updated_at=lead.updated_at,
        tracker_steps=_build_tracker(lead.status, lead.submitted_at, lead.updated_at)
    )

@router.post("/callback")
def request_callback(
    data: CallbackRequestIn,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    lead = db.query(Lead).filter(Lead.user_id == current_user.id).first()
    if not lead:
        lead = Lead(
            user_id=current_user.id,
            status="Submitted",
            submitted_at=datetime.now(timezone.utc),
            updated_at=datetime.now(timezone.utc)
        )
        db.add(lead)
        db.flush()
        assign_lead_round_robin(db, lead)

    exec_user = lead.assigned_executive
    note_content = f"CALLBACK REQUESTED by {current_user.name} ({current_user.mobile or current_user.email})."
    if data.note:
        note_content += f" Message: {data.note}"

    if exec_user:
        db.add(LeadNote(
            lead_id=lead.id,
            executive_id=exec_user.id,
            note=note_content,
            created_at=datetime.now(timezone.utc)
        ))

    db.add(Notification(
        user_id=current_user.id,
        title="Callback Requested!",
        body="We received your request. An advisor will contact you within 2-4 business hours.",
        is_read=False,
        created_at=datetime.now(timezone.utc)
    ))

    db.commit()
    return {"message": "Callback requested successfully. Our advisor will reach out shortly."}
