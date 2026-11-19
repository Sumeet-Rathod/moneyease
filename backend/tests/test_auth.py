import pytest
from httpx import AsyncClient, ASGITransport
from app.main import app
from app.core.security import decode_token

@pytest.mark.asyncio
async def test_request_and_verify_otp():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        # 1. Request OTP
        req_res = await ac.post("/api/v1/auth/request-otp", json={"mobile": "9812345678"})
        assert req_res.status_code == 200
        req_data = req_res.json()
        assert "dev_otp" in req_data
        otp = req_data["dev_otp"]

        # 2. Verify with wrong OTP
        wrong_res = await ac.post("/api/v1/auth/verify-otp", json={"mobile": "9812345678", "otp": "000000"})
        assert wrong_res.status_code == 400

        # 3. Verify with correct OTP
        valid_res = await ac.post("/api/v1/auth/verify-otp", json={"mobile": "9812345678", "otp": otp})
        assert valid_res.status_code == 200
        token_data = valid_res.json()
        assert "access_token" in token_data
        assert "refresh_token" in token_data
        assert token_data["user"]["role"] == "customer"
        assert token_data["user"]["mobile"] == "9812345678"

        # 4. Access /auth/me with access token
        headers = {"Authorization": f"Bearer {token_data['access_token']}"}
        me_res = await ac.get("/api/v1/auth/me", headers=headers)
        assert me_res.status_code == 200
        assert me_res.json()["mobile"] == "9812345678"

@pytest.mark.asyncio
async def test_email_registration_and_login():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        # 1. Register without DPDP consent should fail
        fail_res = await ac.post("/api/v1/auth/register", json={
            "name": "Consent Tester",
            "email": "consent.fail@example.com",
            "password": "Password@123",
            "consent_accepted": False
        })
        assert fail_res.status_code == 400

        # 2. Register with consent
        reg_res = await ac.post("/api/v1/auth/register", json={
            "name": "Pooja Verma",
            "email": "pooja.verma@example.com",
            "mobile": "9899988811",
            "password": "Password@123",
            "consent_accepted": True
        })
        assert reg_res.status_code == 200
        data = reg_res.json()
        assert data["user"]["email"] == "pooja.verma@example.com"

        # 3. Duplicate email should fail
        dup_res = await ac.post("/api/v1/auth/register", json={
            "name": "Duplicate User",
            "email": "pooja.verma@example.com",
            "password": "Password@123",
            "consent_accepted": True
        })
        assert dup_res.status_code == 400

        # 4. Login with registered email
        login_res = await ac.post("/api/v1/auth/login", json={
            "email_or_mobile": "pooja.verma@example.com",
            "password": "Password@123"
        })
        assert login_res.status_code == 200
        assert "access_token" in login_res.json()

@pytest.mark.asyncio
async def test_admin_and_executive_login():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        # Admin login
        admin_res = await ac.post("/api/v1/auth/login", json={
            "email_or_mobile": "admin@moneyease.local",
            "password": "Admin@123"
        })
        assert admin_res.status_code == 200
        assert admin_res.json()["user"]["role"] == "admin"

        # Executive login
        exec_res = await ac.post("/api/v1/auth/login", json={
            "email_or_mobile": "amit.verma@moneyease.local",
            "password": "Exec@123"
        })
        assert exec_res.status_code == 200
        assert exec_res.json()["user"]["role"] == "executive"

        # Refresh token
        ref_token = exec_res.json()["refresh_token"]
        ref_res = await ac.post("/api/v1/auth/refresh", json={"refresh_token": ref_token})
        assert ref_res.status_code == 200
        assert "access_token" in ref_res.json()
