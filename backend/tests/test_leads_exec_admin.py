import pytest
from httpx import AsyncClient, ASGITransport
from app.main import app

@pytest.mark.asyncio
async def test_leads_lifecycle_and_role_security():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        # 1. Customer Login (Rahul)
        cust_login = await ac.post("/api/v1/auth/login", json={
            "email_or_mobile": "rahul.sharma@example.com",
            "password": "Customer@123"
        })
        cust_token = cust_login.json()["access_token"]
        cust_headers = {"Authorization": f"Bearer {cust_token}"}
        cust_id = cust_login.json()["user"]["id"]

        # 2. Executive Login (Amit)
        exec_login = await ac.post("/api/v1/auth/login", json={
            "email_or_mobile": "amit.verma@moneyease.local",
            "password": "Exec@123"
        })
        exec_token = exec_login.json()["access_token"]
        exec_headers = {"Authorization": f"Bearer {exec_token}"}

        # 3. Admin Login
        admin_login = await ac.post("/api/v1/auth/login", json={
            "email_or_mobile": "admin@moneyease.local",
            "password": "Admin@123"
        })
        admin_token = admin_login.json()["access_token"]
        admin_headers = {"Authorization": f"Bearer {admin_token}"}

        # ----------------- SECURITY: Role Access Enforcement -----------------
        # Customer trying to access executive endpoints -> 403 Forbidden
        bad_exec_access = await ac.get("/api/v1/exec/leads", headers=cust_headers)
        assert bad_exec_access.status_code == 403

        # Customer trying to access admin endpoints -> 403 Forbidden
        bad_admin_access = await ac.get("/api/v1/admin/stats", headers=cust_headers)
        assert bad_admin_access.status_code == 403

        # Executive trying to access admin endpoints -> 403 Forbidden
        bad_admin_by_exec = await ac.get("/api/v1/admin/stats", headers=exec_headers)
        assert bad_admin_by_exec.status_code == 403

        # ----------------- Customer Submits Profile -----------------
        submit_res = await ac.post("/api/v1/leads/submit", headers=cust_headers, json={
            "note": "Looking to invest in equity SIPs for retirement."
        })
        assert submit_res.status_code == 200
        lead_data = submit_res.json()
        assert lead_data["status"] in ["Submitted", "Assigned"]
        assert len(lead_data["tracker_steps"]) == 5
        lead_id = lead_data["lead_id"]

        # Customer checks my-status
        status_res = await ac.get("/api/v1/leads/my-status", headers=cust_headers)
        assert status_res.status_code == 200
        assert status_res.json()["lead_id"] == lead_id

        # ----------------- Executive Workflow -----------------
        # List leads
        list_res = await ac.get("/api/v1/exec/leads", headers=exec_headers)
        assert list_res.status_code == 200
        items = list_res.json()["items"]
        assert len(items) >= 1

        # View full lead detail
        detail_res = await ac.get(f"/api/v1/exec/leads/{lead_id}", headers=exec_headers)
        assert detail_res.status_code == 200
        detail = detail_res.json()
        assert detail["user_id"] == cust_id
        assert detail["profile"] is not None
        assert detail["risk_profile"] is not None

        # Add internal note
        note_res = await ac.post(f"/api/v1/exec/leads/{lead_id}/notes", headers=exec_headers, json={
            "note": "Verified customer goals. Looks ready for flexi-cap funds."
        })
        assert note_res.status_code == 200

        # Schedule meeting
        meet_res = await ac.post(f"/api/v1/exec/leads/{lead_id}/meetings", headers=exec_headers, json={
            "scheduled_at": "2026-11-25T14:30:00Z",
            "mode": "video"
        })
        assert meet_res.status_code == 200

        # Send message to customer
        msg_res = await ac.post(f"/api/v1/exec/leads/{lead_id}/message", headers=exec_headers, json={
            "title": "Welcome to MoneyEase",
            "message": "Hi Rahul, looking forward to our video consultation!"
        })
        assert msg_res.status_code == 200

        # Customer checks notifications
        notif_res = await ac.get("/api/v1/notifications", headers=cust_headers)
        assert notif_res.status_code == 200
        notifs = notif_res.json()
        assert len(notifs) >= 1
        assert any("Welcome to MoneyEase" in n["title"] or "Meeting" in n["title"] for n in notifs)

        # Mark notification as read
        notif_id = notifs[0]["id"]
        read_res = await ac.patch(f"/api/v1/notifications/{notif_id}/read", headers=cust_headers)
        assert read_res.status_code == 200
        assert read_res.json()["is_read"] is True

        # Final Decision
        dec_res = await ac.post(f"/api/v1/exec/leads/{lead_id}/decision", headers=exec_headers, json={
            "decision": "Approved",
            "reason": "Profile fits 10-year equity compounding allocation."
        })
        assert dec_res.status_code == 200

        # ----------------- PDF Report Authorization -----------------
        # Customer downloads own PDF -> 200 OK
        own_pdf = await ac.get(f"/api/v1/reports/profile/{cust_id}.pdf", headers=cust_headers)
        assert own_pdf.status_code == 200
        assert own_pdf.headers["content-type"] == "application/pdf"
        assert len(own_pdf.content) > 1000

        # Executive downloads assigned customer's PDF -> 200 OK
        exec_pdf = await ac.get(f"/api/v1/reports/profile/{cust_id}.pdf", headers=exec_headers)
        assert exec_pdf.status_code == 200

        # Login as second customer (Ananya)
        cust2_login = await ac.post("/api/v1/auth/login", json={
            "email_or_mobile": "ananya.patel@example.com",
            "password": "Customer@123"
        })
        cust2_token = cust2_login.json()["access_token"]
        cust2_headers = {"Authorization": f"Bearer {cust2_token}"}

        # Customer 2 trying to download Customer 1's PDF -> 403 Forbidden!
        unauth_pdf = await ac.get(f"/api/v1/reports/profile/{cust_id}.pdf", headers=cust2_headers)
        assert unauth_pdf.status_code == 403

        # ----------------- Admin Operations -----------------
        # Admin stats
        stats_res = await ac.get("/api/v1/admin/stats", headers=admin_headers)
        assert stats_res.status_code == 200
        stats_data = stats_res.json()
        assert stats_data["total_signups"] >= 5
        assert stats_data["total_leads"] >= 5
        assert "Converted" in stats_data["leads_by_status"]

        # Admin settings GET & PUT
        settings_res = await ac.get("/api/v1/admin/settings", headers=admin_headers)
        assert settings_res.status_code == 200
        assert "inflation_rate" in settings_res.json()

        update_settings = await ac.put("/api/v1/admin/settings", headers=admin_headers, json={
            "settings": [
                {"key": "inflation_rate", "value": "6.5"}
            ]
        })
        assert update_settings.status_code == 200
