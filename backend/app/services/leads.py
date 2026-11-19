from datetime import datetime, timezone
from sqlalchemy.orm import Session
from sqlalchemy import func
from app.models.models import User, Lead, Notification, AuditLog
from app.services.email import send_notification_email
from app.config import settings

def assign_lead_round_robin(db: Session, lead: Lead) -> User:
    """
    Assigns a newly submitted customer profile lead to active executives
    in a round-robin manner (assigns to the executive with the least active leads).
    """
    executives = db.query(User).filter(
        User.role == "executive",
        User.is_active == True
    ).all()

    if not executives:
        # Fallback to admin if no executive is created yet
        admin = db.query(User).filter(User.role == "admin", User.is_active == True).first()
        if admin:
            lead.assigned_executive_id = admin.id
            lead.status = "Assigned"
            return admin
        return None

    # Count assigned leads per executive to achieve fair round-robin
    counts = (
        db.query(Lead.assigned_executive_id, func.count(Lead.id))
        .filter(Lead.assigned_executive_id.in_([e.id for e in executives]))
        .group_by(Lead.assigned_executive_id)
        .all()
    )
    count_map = {e.id: 0 for e in executives}
    for exec_id, c in counts:
        if exec_id in count_map:
            count_map[exec_id] = c

    # Pick executive with minimum lead count
    chosen_exec = min(executives, key=lambda e: count_map[e.id])
    lead.assigned_executive_id = chosen_exec.id
    lead.status = "Assigned"
    lead.updated_at = datetime.now(timezone.utc)

    # Send Notification Email to Executive
    customer_name = lead.user.name if lead.user else "Customer"
    subject = f"[MoneyEase] New Lead Assigned: {customer_name}"
    html = f"""
    <h3>New Customer Profile Assigned</h3>
    <p>Hello {chosen_exec.name},</p>
    <p>A new customer profile for <b>{customer_name}</b> has been completed and assigned to you.</p>
    <p><b>Lead ID:</b> #{lead.id}<br/>
    <b>Status:</b> Assigned<br/>
    <b>Date:</b> {datetime.now().strftime('%d %b %Y, %H:%M')}</p>
    <p>Please log in to the MoneyEase Executive Dashboard to review their goals, risk profile, and initiate contact.</p>
    <br/>
    <p>Regards,<br/>{settings.FIRM_NAME}</p>
    """
    send_notification_email(
        to_email=chosen_exec.email or settings.SUPPORT_EMAIL,
        subject=subject,
        html_content=html,
        text_content=f"New Lead Assigned: {customer_name} (#{lead.id}). Review in MoneyEase Executive Dashboard."
    )

    # In-App Notification for Customer
    db.add(Notification(
        user_id=lead.user_id,
        title="Advisor Assigned!",
        body=f"Your financial snapshot has been submitted. Dedicated advisor {chosen_exec.name} has been assigned to your profile.",
        is_read=False,
        created_at=datetime.now(timezone.utc)
    ))

    # Audit log
    db.add(AuditLog(
        actor_id=lead.user_id,
        action="LEAD_SUBMITTED_AND_ASSIGNED",
        entity="leads",
        entity_id=lead.id,
        created_at=datetime.now(timezone.utc)
    ))

    db.commit()
    return chosen_exec
