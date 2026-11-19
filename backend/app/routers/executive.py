from datetime import datetime, date, timezone
from typing import Optional, List
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from sqlalchemy import func
from app.database import get_db
from app.models.models import (
    User, Lead, LeadNote, Meeting, CustomerProfile, RiskProfile, Goal, Doubt, Notification, Consent, AuditLog
)
from app.schemas.schemas import (
    LeadListItemOut, LeadDetailOut, CustomerProfileOut, RiskProfileOut, GoalOut,
    DoubtHistoryOut, LeadNoteOut, MeetingOut, LeadNoteIn, MeetingIn, DecisionIn,
    LeadMessageIn
)
from app.core.deps import require_executive
from app.core.security import mask_pan
from app.services.calculator import format_inr_words

router = APIRouter(prefix="/exec", tags=["Executive Dashboard"])

@router.get("/leads")
def list_leads(
    status: Optional[str] = None,
    risk: Optional[str] = None,
    search: Optional[str] = None,
    assigned_to_me: bool = False,
    skip: int = 0,
    limit: int = 50,
    current_user: User = Depends(require_executive),
    db: Session = Depends(get_db)
):
    query = db.query(Lead).join(User, Lead.user_id == User.id)

    if assigned_to_me and current_user.role == "executive":
        query = query.filter(Lead.assigned_executive_id == current_user.id)

    if status and status.lower() != "all":
        query = query.filter(Lead.status.ilike(status))

    if search:
        search_term = f"%{search.strip()}%"
        query = query.filter(
            (User.name.ilike(search_term)) |
            (User.email.ilike(search_term)) |
            (User.mobile.ilike(search_term))
        )

    leads = query.order_by(Lead.updated_at.desc()).offset(skip).limit(limit).all()
    
    results = []
    today = date.today()
    for l in leads:
        customer = l.user
        profile = customer.customer_profile
        risk_prof = customer.risk_profile

        if risk and risk.lower() != "all":
            if not risk_prof or risk_prof.category.lower() != risk.lower():
                continue

        age = None
        if profile and profile.dob:
            age = today.year - profile.dob.year - ((today.month, today.day) < (profile.dob.month, profile.dob.day))

        # Goals aggregate
        goals = customer.goals or []
        total_amount = sum(g.current_cost for g in goals)
        total_sip = sum(g.required_sip for g in goals)

        results.append(LeadListItemOut(
            lead_id=l.id,
            user_id=customer.id,
            name=customer.name,
            age=age,
            city=profile.city if profile else None,
            risk_category=risk_prof.category if risk_prof else "Not Assessed",
            total_goals_count=len(goals),
            total_goal_amount=round(total_amount, 2),
            total_required_sip=round(total_sip, 2),
            status=l.status,
            assigned_executive_id=l.assigned_executive_id,
            assigned_executive_name=l.assigned_executive.name if l.assigned_executive else "Unassigned",
            submitted_at=l.submitted_at,
            updated_at=l.updated_at
        ))

    return {
        "total": len(results),
        "skip": skip,
        "limit": limit,
        "items": results
    }

@router.get("/leads/{lead_id}", response_model=LeadDetailOut)
def get_lead_detail(
    lead_id: int,
    current_user: User = Depends(require_executive),
    db: Session = Depends(get_db)
):
    lead = db.query(Lead).filter(Lead.id == lead_id).first()
    if not lead:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Lead not found.")

    customer = lead.user
    profile = customer.customer_profile
    risk_prof = customer.risk_profile
    goals = customer.goals or []
    doubts = customer.doubts or []
    notes = lead.notes or []
    meetings = lead.meetings or []
    consent = db.query(Consent).filter(Consent.user_id == customer.id).first()

    # Build profile out
    profile_out = None
    if profile:
        age = None
        if profile.dob:
            today = date.today()
            age = today.year - profile.dob.year - ((today.month, today.day) < (profile.dob.month, profile.dob.day))
        pan_masked = mask_pan(profile.pan_encrypted, is_encrypted=True) if profile.has_pan else None
        profile_out = CustomerProfileOut(
            id=profile.id,
            user_id=customer.id,
            name=customer.name,
            email=customer.email,
            mobile=customer.mobile,
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

    # Risk out
    risk_out = None
    if risk_prof:
        risk_out = RiskProfileOut(
            id=risk_prof.id,
            user_id=customer.id,
            answers=risk_prof.answers,
            score=risk_prof.score,
            category=risk_prof.category,
            explanation=f"Profile calibrated to {risk_prof.category} based on score {risk_prof.score}.",
            suggested_return=8.0 if risk_prof.category == "Conservative" else (12.0 if risk_prof.category == "Aggressive" else 10.0),
            created_at=risk_prof.created_at
        )

    goals_out = []
    for g in goals:
        g_out = GoalOut.model_validate(g)
        g_out.future_cost_words = format_inr_words(g.future_cost)
        g_out.required_lumpsum_words = format_inr_words(g.required_lumpsum)
        goals_out.append(g_out)

    doubts_out = [DoubtHistoryOut.model_validate(d) for d in doubts]

    notes_out = [
        LeadNoteOut(
            id=n.id,
            executive_name=n.executive.name if n.executive else "Executive",
            note=n.note,
            created_at=n.created_at
        )
        for n in notes
    ]

    meetings_out = [MeetingOut.model_validate(m) for m in meetings]

    return LeadDetailOut(
        lead_id=lead.id,
        user_id=customer.id,
        status=lead.status,
        final_decision=lead.final_decision,
        decision_reason=lead.decision_reason,
        submitted_at=lead.submitted_at,
        updated_at=lead.updated_at,
        assigned_executive_id=lead.assigned_executive_id,
        assigned_executive_name=lead.assigned_executive.name if lead.assigned_executive else "Unassigned",
        consent_accepted_at=consent.accepted_at if consent else None,
        profile=profile_out,
        risk_profile=risk_out,
        goals=goals_out,
        doubts_asked=doubts_out,
        notes=notes_out,
        meetings=meetings_out
    )

@router.patch("/leads/{lead_id}/status")
def update_lead_status(
    lead_id: int,
    status_update: dict,
    current_user: User = Depends(require_executive),
    db: Session = Depends(get_db)
):
    new_status = status_update.get("status")
    if not new_status:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="New status is required.")

    lead = db.query(Lead).filter(Lead.id == lead_id).first()
    if not lead:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Lead not found.")

    old_status = lead.status
    lead.status = new_status
    lead.updated_at = datetime.now(timezone.utc)

    # In-app notification for customer
    db.add(Notification(
        user_id=lead.user_id,
        title="Application Status Updated",
        body=f"Your profile status has been updated to '{new_status}' by your advisor {current_user.name}.",
        is_read=False,
        created_at=datetime.now(timezone.utc)
    ))

    # Audit log
    db.add(AuditLog(
        actor_id=current_user.id,
        action=f"STATUS_CHANGED_{old_status}_TO_{new_status}",
        entity="leads",
        entity_id=lead.id,
        created_at=datetime.now(timezone.utc)
    ))

    db.commit()
    return {"message": f"Status updated to '{new_status}' successfully."}

@router.post("/leads/{lead_id}/notes")
def add_lead_note(
    lead_id: int,
    data: LeadNoteIn,
    current_user: User = Depends(require_executive),
    db: Session = Depends(get_db)
):
    lead = db.query(Lead).filter(Lead.id == lead_id).first()
    if not lead:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Lead not found.")

    note = LeadNote(
        lead_id=lead.id,
        executive_id=current_user.id,
        note=data.note.strip(),
        created_at=datetime.now(timezone.utc)
    )
    db.add(note)
    lead.updated_at = datetime.now(timezone.utc)
    db.commit()
    return {"message": "Internal note recorded successfully."}

@router.post("/leads/{lead_id}/meetings")
def schedule_lead_meeting(
    lead_id: int,
    data: MeetingIn,
    current_user: User = Depends(require_executive),
    db: Session = Depends(get_db)
):
    lead = db.query(Lead).filter(Lead.id == lead_id).first()
    if not lead:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Lead not found.")

    meeting = Meeting(
        lead_id=lead.id,
        scheduled_at=data.scheduled_at,
        mode=data.mode,
        status="scheduled"
    )
    db.add(meeting)
    lead.status = "Meeting Scheduled"
    lead.updated_at = datetime.now(timezone.utc)

    # Notify customer
    dt_str = data.scheduled_at.strftime("%d %b %Y at %I:%M %p")
    db.add(Notification(
        user_id=lead.user_id,
        title="Consultation Meeting Scheduled!",
        body=f"Your {data.mode} consultation with advisor {current_user.name} is scheduled for {dt_str}.",
        is_read=False,
        created_at=datetime.now(timezone.utc)
    ))

    db.commit()
    return {"message": "Meeting scheduled successfully and customer notified."}

@router.post("/leads/{lead_id}/message")
def send_customer_message(
    lead_id: int,
    data: LeadMessageIn,
    current_user: User = Depends(require_executive),
    db: Session = Depends(get_db)
):
    lead = db.query(Lead).filter(Lead.id == lead_id).first()
    if not lead:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Lead not found.")

    # Create notification for customer
    db.add(Notification(
        user_id=lead.user_id,
        title=data.title,
        body=f"{data.message}\n\n— {current_user.name} (Wealth Advisor)",
        is_read=False,
        created_at=datetime.now(timezone.utc)
    ))
    db.commit()
    return {"message": "Message sent to customer successfully."}

@router.post("/leads/{lead_id}/decision")
def make_final_decision(
    lead_id: int,
    data: DecisionIn,
    current_user: User = Depends(require_executive),
    db: Session = Depends(get_db)
):
    valid_decisions = ["Approved", "Not suitable", "Follow-up later"]
    if data.decision not in valid_decisions:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Decision must be one of: {', '.join(valid_decisions)}"
        )

    lead = db.query(Lead).filter(Lead.id == lead_id).first()
    if not lead:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Lead not found.")

    lead.final_decision = data.decision
    lead.decision_reason = data.reason.strip()
    if data.decision == "Approved":
        lead.status = "Converted"
    lead.updated_at = datetime.now(timezone.utc)

    # Log note
    db.add(LeadNote(
        lead_id=lead.id,
        executive_id=current_user.id,
        note=f"FINAL DECISION: {data.decision}. Reason: {data.reason}",
        created_at=datetime.now(timezone.utc)
    ))

    # Notify customer
    status_msg = (
        "Congratulations! Your customized financial blueprint has been approved."
        if data.decision == "Approved"
        else f"Advisor Update: {data.decision} - {data.reason}"
    )
    db.add(Notification(
        user_id=lead.user_id,
        title=f"Application Decision: {data.decision}",
        body=status_msg,
        is_read=False,
        created_at=datetime.now(timezone.utc)
    ))

    db.commit()
    return {"message": f"Final decision '{data.decision}' recorded successfully."}
