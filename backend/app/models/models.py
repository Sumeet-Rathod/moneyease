from datetime import datetime, timezone
from sqlalchemy import (
    Column, Integer, String, Float, Boolean, DateTime, Date,
    ForeignKey, Text, JSON
)
from sqlalchemy.orm import relationship
from app.database import Base

def utcnow():
    return datetime.now(timezone.utc)

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    role = Column(String(20), nullable=False, default="customer")  # customer, executive, admin
    name = Column(String(100), nullable=False)
    email = Column(String(255), unique=True, index=True, nullable=True)
    mobile = Column(String(20), unique=True, index=True, nullable=True)
    password_hash = Column(String(255), nullable=True)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), default=utcnow)

    # Relationships
    consents = relationship("Consent", back_populates="user", cascade="all, delete-orphan")
    customer_profile = relationship("CustomerProfile", back_populates="user", uselist=False, cascade="all, delete-orphan")
    risk_profile = relationship("RiskProfile", back_populates="user", uselist=False, cascade="all, delete-orphan")
    goals = relationship("Goal", back_populates="user", cascade="all, delete-orphan")
    doubts = relationship("Doubt", back_populates="user", cascade="all, delete-orphan")
    lead = relationship("Lead", back_populates="user", foreign_keys="Lead.user_id", uselist=False, cascade="all, delete-orphan")
    assigned_leads = relationship("Lead", back_populates="assigned_executive", foreign_keys="Lead.assigned_executive_id")
    notifications = relationship("Notification", back_populates="user", cascade="all, delete-orphan")


class Consent(Base):
    __tablename__ = "consents"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    consent_text_version = Column(String(50), nullable=False, default="DPDP_ACT_2023_V1")
    accepted_at = Column(DateTime(timezone=True), default=utcnow)
    ip = Column(String(50), nullable=True)

    user = relationship("User", back_populates="consents")


class CustomerProfile(Base):
    __tablename__ = "customer_profiles"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), unique=True, nullable=False)
    dob = Column(Date, nullable=True)
    gender = Column(String(20), nullable=True)
    city = Column(String(100), nullable=True)
    occupation = Column(String(50), nullable=True)  # student, salaried, self-employed, business, other
    income_range = Column(String(50), nullable=True)
    monthly_expenses = Column(Float, nullable=True, default=0.0)
    savings = Column(Float, nullable=True, default=0.0)
    loans_emi = Column(Float, nullable=True, default=0.0)
    dependents = Column(Integer, nullable=True, default=0)
    existing_investments = Column(JSON, nullable=True, default=list)  # [{"type": "FD", "amount": 50000}, ...]
    has_pan = Column(Boolean, default=False)
    pan_encrypted = Column(String(255), nullable=True)
    has_bank = Column(Boolean, default=False)
    has_aadhaar_linked_mobile = Column(Boolean, default=False)
    onboarding_step = Column(Integer, default=1)
    completed = Column(Boolean, default=False)
    updated_at = Column(DateTime(timezone=True), default=utcnow, onupdate=utcnow)

    user = relationship("User", back_populates="customer_profile")


class RiskProfile(Base):
    __tablename__ = "risk_profiles"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), unique=True, nullable=False)
    answers = Column(JSON, nullable=False, default=dict)  # {"q1": 2, "q2": 3, ...}
    score = Column(Integer, nullable=False, default=0)
    category = Column(String(30), nullable=False, default="Moderate")  # Conservative, Moderate, Aggressive
    created_at = Column(DateTime(timezone=True), default=utcnow)

    user = relationship("User", back_populates="risk_profile")


class Goal(Base):
    __tablename__ = "goals"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    type = Column(String(50), nullable=False)  # Emergency Fund, Higher Education, etc.
    name = Column(String(100), nullable=False)
    current_cost = Column(Float, nullable=False)
    years = Column(Float, nullable=False)
    saved_amount = Column(Float, default=0.0)
    inflation = Column(Float, default=6.0)
    assumed_return = Column(Float, default=10.0)
    future_cost = Column(Float, nullable=False)
    required_sip = Column(Float, nullable=False)
    required_lumpsum = Column(Float, nullable=False)
    step_up_pct = Column(Float, default=0.0)
    created_at = Column(DateTime(timezone=True), default=utcnow)

    user = relationship("User", back_populates="goals")


class Doubt(Base):
    __tablename__ = "doubts"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    question = Column(Text, nullable=False)
    answer = Column(Text, nullable=False)
    source = Column(String(20), default="faq")  # ai, faq
    topic = Column(String(100), nullable=True)
    created_at = Column(DateTime(timezone=True), default=utcnow)

    user = relationship("User", back_populates="doubts")


class Lead(Base):
    __tablename__ = "leads"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), unique=True, nullable=False)
    assigned_executive_id = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"), nullable=True)
    status = Column(String(30), default="Submitted")  # Submitted, Assigned, Contacted, Meeting Scheduled, Converted, Closed
    final_decision = Column(String(30), nullable=True)  # Approved, Not suitable, Follow-up later
    decision_reason = Column(Text, nullable=True)
    submitted_at = Column(DateTime(timezone=True), default=utcnow)
    updated_at = Column(DateTime(timezone=True), default=utcnow, onupdate=utcnow)

    user = relationship("User", foreign_keys=[user_id], back_populates="lead")
    assigned_executive = relationship("User", foreign_keys=[assigned_executive_id], back_populates="assigned_leads")
    notes = relationship("LeadNote", back_populates="lead", cascade="all, delete-orphan")
    meetings = relationship("Meeting", back_populates="lead", cascade="all, delete-orphan")


class LeadNote(Base):
    __tablename__ = "lead_notes"

    id = Column(Integer, primary_key=True, index=True)
    lead_id = Column(Integer, ForeignKey("leads.id", ondelete="CASCADE"), nullable=False)
    executive_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    note = Column(Text, nullable=False)
    created_at = Column(DateTime(timezone=True), default=utcnow)

    lead = relationship("Lead", back_populates="notes")
    executive = relationship("User")


class Meeting(Base):
    __tablename__ = "meetings"

    id = Column(Integer, primary_key=True, index=True)
    lead_id = Column(Integer, ForeignKey("leads.id", ondelete="CASCADE"), nullable=False)
    scheduled_at = Column(DateTime(timezone=True), nullable=False)
    mode = Column(String(20), default="call")  # call, video, office
    status = Column(String(20), default="scheduled")  # scheduled, completed, cancelled

    lead = relationship("Lead", back_populates="meetings")


class Notification(Base):
    __tablename__ = "notifications"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    title = Column(String(150), nullable=False)
    body = Column(Text, nullable=False)
    is_read = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), default=utcnow)

    user = relationship("User", back_populates="notifications")


class Setting(Base):
    __tablename__ = "settings"

    id = Column(Integer, primary_key=True, index=True)
    key = Column(String(100), unique=True, nullable=False, index=True)
    value = Column(Text, nullable=False)


class FAQ(Base):
    __tablename__ = "faqs"

    id = Column(Integer, primary_key=True, index=True)
    question = Column(String(255), nullable=False)
    answer = Column(Text, nullable=False)
    keywords = Column(String(255), nullable=True)
    category = Column(String(50), nullable=False, default="Mutual Funds")
    is_active = Column(Boolean, default=True)


class AuditLog(Base):
    __tablename__ = "audit_logs"

    id = Column(Integer, primary_key=True, index=True)
    actor_id = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"), nullable=True)
    action = Column(String(100), nullable=False)
    entity = Column(String(100), nullable=False)
    entity_id = Column(Integer, nullable=True)
    created_at = Column(DateTime(timezone=True), default=utcnow)
