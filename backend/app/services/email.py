import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from app.config import settings

def send_notification_email(to_email: str, subject: str, html_content: str, text_content: str = "") -> bool:
    """
    Sends an email notification to executive or customer.
    If SMTP is not configured in .env, prints formatted email to console.
    """
    if not settings.SMTP_HOST or not settings.SMTP_USER:
        print(f"\n{'-'*60}")
        print(f"[MoneyEase EMAIL NOTIFICATION] (Console Fallback)")
        print(f"From: {settings.SMTP_FROM}")
        print(f"To: {to_email}")
        print(f"Subject: {subject}")
        print(f"Body: {text_content or html_content}")
        print(f"{'-'*60}\n")
        return True

    try:
        msg = MIMEMultipart("alternative")
        msg["Subject"] = subject
        msg["From"] = settings.SMTP_FROM
        msg["To"] = to_email

        if text_content:
            msg.attach(MIMEText(text_content, "plain"))
        if html_content:
            msg.attach(MIMEText(html_content, "html"))

        with smtplib.SMTP(settings.SMTP_HOST, settings.SMTP_PORT) as server:
            server.starttls()
            if settings.SMTP_PASSWORD:
                server.login(settings.SMTP_USER, settings.SMTP_PASSWORD)
            server.sendmail(settings.SMTP_FROM, [to_email], msg.as_string())
        return True
    except Exception as e:
        print(f"[MoneyEase EMAIL ERROR] Failed to send email to {to_email}: {e}")
        return False
