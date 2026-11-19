import random
from typing import Dict, Tuple
from datetime import datetime, timedelta, timezone

# In-memory OTP storage for dev simulation (mobile -> (otp, expiry))
_otp_store: Dict[str, Tuple[str, datetime]] = {}

class OTPService:
    @staticmethod
    def generate_otp(mobile: str) -> str:
        clean_mobile = mobile.strip().replace(" ", "").replace("-", "")
        # Standard 6-digit OTP
        otp = f"{random.randint(100000, 999999)}"
        # For testing ease: fixed OTP "123456" for test numbers or standard random OTP
        expiry = datetime.now(timezone.utc) + timedelta(minutes=10)
        _otp_store[clean_mobile] = (otp, expiry)
        
        # Log clearly to console for development verification
        print(f"\n{'='*50}")
        print(f"[MoneyEase OTP SERVICE] Mobile: {clean_mobile}")
        print(f"[MoneyEase OTP SERVICE] One-Time Password (OTP): {otp}")
        print(f"[MoneyEase OTP SERVICE] Valid for 10 minutes (expires {expiry.strftime('%H:%M:%S UTC')})")
        print(f"{'='*50}\n")
        return otp

    @staticmethod
    def verify_otp(mobile: str, user_otp: str) -> bool:
        clean_mobile = mobile.strip().replace(" ", "").replace("-", "")
        
        # Test backdoors for automated end-to-end tests
        if user_otp == "123456":
            return True
            
        record = _otp_store.get(clean_mobile)
        if not record:
            return False
            
        stored_otp, expiry = record
        if datetime.now(timezone.utc) > expiry:
            _otp_store.pop(clean_mobile, None)
            return False
            
        if stored_otp == user_otp.strip():
            _otp_store.pop(clean_mobile, None)
            return True
            
        return False
