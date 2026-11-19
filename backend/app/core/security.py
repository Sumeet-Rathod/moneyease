import re
import base64
from datetime import datetime, timedelta, timezone
from typing import Optional, Any
import bcrypt
import jwt
from cryptography.fernet import Fernet
from app.config import settings

# ----------------- Fernet Encryption for PAN -----------------
def _get_fernet() -> Fernet:
    try:
        return Fernet(settings.FERNET_KEY.encode())
    except Exception:
        # Fallback to deterministic valid 32-byte Fernet key if env is invalid
        key = base64.urlsafe_b64encode(b"MoneyEaseFernetKey32BytesLength!")
        return Fernet(key)

fernet = _get_fernet()

def encrypt_pan(pan: str) -> str:
    if not pan:
        return ""
    clean_pan = pan.strip().upper()
    return fernet.encrypt(clean_pan.encode()).decode()

def decrypt_pan(encrypted_pan: str) -> str:
    if not encrypted_pan:
        return ""
    try:
        return fernet.decrypt(encrypted_pan.encode()).decode()
    except Exception:
        return ""

def mask_pan(pan_or_encrypted: str, is_encrypted: bool = False) -> str:
    pan = decrypt_pan(pan_or_encrypted) if is_encrypted else (pan_or_encrypted or "")
    pan = pan.strip().upper()
    if not pan or len(pan) < 10:
        return "XXXXXXXXXX"
    # Mask first 5 characters and last character: e.g., XXXXX1234X
    return f"XXXXX{pan[5:9]}X"

def validate_pan(pan: str) -> bool:
    if not pan:
        return False
    return bool(re.match(r"^[A-Z]{5}[0-9]{4}[A-Z]{1}$", pan.strip().upper()))

# ----------------- Password Hashing (bcrypt) -----------------
def get_password_hash(password: str) -> str:
    pwd_bytes = password.encode('utf-8')
    salt = bcrypt.gensalt()
    return bcrypt.hashpw(pwd_bytes, salt).decode('utf-8')

def verify_password(plain_password: str, hashed_password: str) -> bool:
    if not plain_password or not hashed_password:
        return False
    try:
        return bcrypt.checkpw(plain_password.encode('utf-8'), hashed_password.encode('utf-8'))
    except Exception:
        return False

# ----------------- JWT Tokens -----------------
def create_access_token(data: dict[str, Any], expires_delta: Optional[timedelta] = None) -> str:
    to_encode = data.copy()
    expire = datetime.now(timezone.utc) + (
        expires_delta if expires_delta else timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    )
    to_encode.update({"exp": expire, "type": "access"})
    return jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)

def create_refresh_token(data: dict[str, Any], expires_delta: Optional[timedelta] = None) -> str:
    to_encode = data.copy()
    expire = datetime.now(timezone.utc) + (
        expires_delta if expires_delta else timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS)
    )
    to_encode.update({"exp": expire, "type": "refresh"})
    return jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)

def decode_token(token: str) -> Optional[dict[str, Any]]:
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        return payload
    except jwt.PyJWTError:
        return None
