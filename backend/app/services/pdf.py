import io
from datetime import datetime
from reportlab.lib import colors
from reportlab.lib.pagesizes import letter
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, KeepTogether
)
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from app.config import settings
from app.core.security import mask_pan
from app.services.calculator import format_inr_words

def generate_customer_snapshot_pdf(
    customer_user,
    customer_profile,
    risk_profile,
    goals,
    doubts,
    lead=None
) -> bytes:
    """
    Generates a high-quality, professional 'My Financial Snapshot' PDF
    report using ReportLab for the customer or executive.
    """
    buffer = io.BytesIO()
    doc = SimpleDocTemplate(
        buffer,
        pagesize=letter,
        rightMargin=36,
        leftMargin=36,
        topMargin=36,
        bottomMargin=36
    )

    styles = getSampleStyleSheet()
    
    # Custom styles
    title_style = ParagraphStyle(
        'DocTitle',
        parent=styles['Heading1'],
        fontName='Helvetica-Bold',
        fontSize=20,
        leading=24,
        textColor=colors.HexColor("#0D47A1")  # Deep blue
    )
    subtitle_style = ParagraphStyle(
        'DocSubtitle',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=10,
        leading=14,
        textColor=colors.HexColor("#555555")
    )
    section_heading = ParagraphStyle(
        'SectionHead',
        parent=styles['Heading2'],
        fontName='Helvetica-Bold',
        fontSize=13,
        leading=16,
        textColor=colors.HexColor("#1B5E20"),  # Dark green
        spaceBefore=12,
        spaceAfter=6
    )
    body_style = ParagraphStyle(
        'BodyDark',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=9,
        leading=12,
        textColor=colors.HexColor("#222222")
    )
    disclaimer_style = ParagraphStyle(
        'Disclaimer',
        parent=styles['Normal'],
        fontName='Helvetica-Oblique',
        fontSize=8,
        leading=11,
        textColor=colors.HexColor("#7F0000")  # Dark red
    )

    elements = []

    # 1. Header with Firm Branding
    header_data = [
        [
            Paragraph(f"<b>{settings.FIRM_NAME}</b><br/>AMFI Registered Mutual Fund Distributor ({settings.ARN_NUMBER})", title_style),
            Paragraph(f"<b>Generated:</b> {datetime.now().strftime('%d %b %Y, %H:%M')}<br/><b>Email:</b> {settings.SUPPORT_EMAIL}<br/><b>Phone:</b> {settings.SUPPORT_PHONE}", subtitle_style)
        ]
    ]
    header_table = Table(header_data, colWidths=[340, 200])
    header_table.setStyle(TableStyle([
        ('VALIGN', (0, 0), (-1, -1), 'TOP'),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 8),
    ]))
    elements.append(header_table)
    elements.append(Spacer(1, 8))

    # 2. SEBI Compliance Disclaimer
    disclaimer_box = Table(
        [[Paragraph(f"<b>IMPORTANT REGULATORY DISCLAIMER:</b> {settings.COMPLIANCE_DISCLAIMER}", disclaimer_style)]],
        colWidths=[540]
    )
    disclaimer_box.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, -1), colors.HexColor("#FFF3E0")),
        ('BOX', (0, 0), (-1, -1), 1, colors.HexColor("#FFB74D")),
        ('TOPPADDING', (0, 0), (-1, -1), 6),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 6),
        ('LEFTPADDING', (0, 0), (-1, -1), 8),
        ('RIGHTPADDING', (0, 0), (-1, -1), 8),
    ]))
    elements.append(disclaimer_box)
    elements.append(Spacer(1, 12))

    # 3. Personal & Profile Information
    elements.append(Paragraph("1. Customer Profile", section_heading))
    age_str = ""
    if customer_profile and customer_profile.dob:
        age_str = f" ({datetime.now().year - customer_profile.dob.year} years)"
    
    pan_display = "Not Provided"
    if customer_profile and customer_profile.has_pan:
        pan_display = mask_pan(customer_profile.pan_encrypted, is_encrypted=True)

    info_data = [
        [
            Paragraph("<b>Full Name:</b>", body_style),
            Paragraph(customer_user.name, body_style),
            Paragraph("<b>Email:</b>", body_style),
            Paragraph(customer_user.email or "N/A", body_style),
        ],
        [
            Paragraph("<b>Mobile:</b>", body_style),
            Paragraph(customer_user.mobile or "N/A", body_style),
            Paragraph("<b>City / Location:</b>", body_style),
            Paragraph((customer_profile.city if customer_profile else "N/A") or "N/A", body_style),
        ],
        [
            Paragraph("<b>Date of Birth:</b>", body_style),
            Paragraph(f"{customer_profile.dob.strftime('%d-%m-%Y') if (customer_profile and customer_profile.dob) else 'N/A'}{age_str}", body_style),
            Paragraph("<b>Occupation:</b>", body_style),
            Paragraph((customer_profile.occupation if customer_profile else "N/A") or "N/A", body_style),
        ],
        [
            Paragraph("<b>Income Range:</b>", body_style),
            Paragraph((customer_profile.income_range if customer_profile else "N/A") or "N/A", body_style),
            Paragraph("<b>Monthly Expenses:</b>", body_style),
            Paragraph(f"₹{(customer_profile.monthly_expenses if customer_profile else 0.0) or 0.0:,.0f}", body_style),
        ],
        [
            Paragraph("<b>Existing Savings:</b>", body_style),
            Paragraph(f"₹{(customer_profile.savings if customer_profile else 0.0) or 0.0:,.0f}", body_style),
            Paragraph("<b>PAN (Masked):</b>", body_style),
            Paragraph(pan_display, body_style),
        ]
    ]
    info_table = Table(info_data, colWidths=[100, 170, 110, 160])
    info_table.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, -1), colors.HexColor("#F8F9FA")),
        ('GRID', (0, 0), (-1, -1), 0.5, colors.HexColor("#E0E0E0")),
        ('TOPPADDING', (0, 0), (-1, -1), 4),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 4),
    ]))
    elements.append(info_table)
    elements.append(Spacer(1, 10))

    # 4. Risk Profile Section
    elements.append(Paragraph("2. Risk Profile & Asset Allocation", section_heading))
    risk_cat = risk_profile.category if risk_profile else "Moderate"
    risk_score = risk_profile.score if risk_profile else 15
    risk_color = "#388E3C" if risk_cat == "Conservative" else ("#1976D2" if risk_cat == "Moderate" else "#D32F2F")

    risk_data = [
        [
            Paragraph(f"<b>Assigned Category:</b> <font color='{risk_color}'><b>{risk_cat}</b></font> (Score: {risk_score})", body_style),
            Paragraph(
                "<b>Conservative:</b> 8% Assumed Return (Emphasis on Debt & Capital Protection)<br/>"
                "<b>Moderate:</b> 10% Assumed Return (Balanced Equity & Debt Blend)<br/>"
                "<b>Aggressive:</b> 12% Assumed Return (Growth Equity Focus for 5-10+ Year Horizons)",
                subtitle_style
            )
        ]
    ]
    risk_table = Table(risk_data, colWidths=[200, 340])
    risk_table.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, -1), colors.HexColor("#F1F8E9")),
        ('BOX', (0, 0), (-1, -1), 1, colors.HexColor("#C8E6C9")),
        ('VALIGN', (0, 0), (-1, -1), 'TOP'),
        ('TOPPADDING', (0, 0), (-1, -1), 6),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 6),
        ('LEFTPADDING', (0, 0), (-1, -1), 8),
        ('RIGHTPADDING', (0, 0), (-1, -1), 8),
    ]))
    elements.append(risk_table)
    elements.append(Spacer(1, 10))

    # 5. Financial Goals Table
    elements.append(Paragraph("3. Financial Goals & SIP Blueprint", section_heading))
    if not goals:
        elements.append(Paragraph("<i>No goals configured yet.</i>", body_style))
    else:
        goal_rows = [
            [
                Paragraph("<b>Goal Name</b>", body_style),
                Paragraph("<b>Today's Cost</b>", body_style),
                Paragraph("<b>Horizon</b>", body_style),
                Paragraph("<b>Future Cost (FV)</b>", body_style),
                Paragraph("<b>Required Monthly SIP</b>", body_style),
                Paragraph("<b>Lumpsum Needed</b>", body_style)
            ]
        ]
        total_sip = 0.0
        total_fv = 0.0
        for g in goals:
            total_sip += g.required_sip
            total_fv += g.future_cost
            goal_rows.append([
                Paragraph(f"<b>{g.name}</b><br/>({g.type})", body_style),
                Paragraph(f"₹{g.current_cost:,.0f}", body_style),
                Paragraph(f"{g.years:.1f} yrs", body_style),
                Paragraph(f"₹{g.future_cost:,.0f}<br/><font size='7' color='#666'>{format_inr_words(g.future_cost)}</font>", body_style),
                Paragraph(f"<b>₹{g.required_sip:,.0f}</b>", body_style),
                Paragraph(f"₹{g.required_lumpsum:,.0f}", body_style)
            ])

        goal_rows.append([
            Paragraph("<b>TOTALS</b>", body_style),
            Paragraph("-", body_style),
            Paragraph("-", body_style),
            Paragraph(f"<b>₹{total_fv:,.0f}</b>", body_style),
            Paragraph(f"<b><font color='#0D47A1'>₹{total_sip:,.0f} / mo</font></b>", body_style),
            Paragraph("-", body_style)
        ])

        goal_table = Table(goal_rows, colWidths=[120, 80, 50, 100, 100, 90])
        goal_table.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor("#E3F2FD")),
            ('GRID', (0, 0), (-1, -1), 0.5, colors.HexColor("#B0BEC5")),
            ('ALIGN', (1, 0), (-1, -1), 'RIGHT'),
            ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
            ('TOPPADDING', (0, 0), (-1, -1), 4),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 4),
            ('BACKGROUND', (0, -1), (-1, -1), colors.HexColor("#ECEFF1")),
        ]))
        elements.append(goal_table)

    elements.append(Spacer(1, 10))

    # 6. Doubts & Areas of Interest Asked
    elements.append(Paragraph("4. Questions & Topics Explored in Chat", section_heading))
    if not doubts:
        elements.append(Paragraph("<i>No doubts asked during session.</i>", body_style))
    else:
        doubt_items = []
        for d in doubts[:5]:  # Show top 5
            doubt_items.append([
                Paragraph(f"• <b>Q: {d.question}</b><br/>&nbsp;&nbsp;<i>A: {d.answer[:140]}...</i>", body_style)
            ])
        doubt_table = Table(doubt_items, colWidths=[540])
        doubt_table.setStyle(TableStyle([
            ('TOPPADDING', (0, 0), (-1, -1), 2),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 4),
        ]))
        elements.append(doubt_table)

    elements.append(Spacer(1, 15))

    # 7. Executive Action & Verification Box
    lead_status = lead.status if lead else "Submitted"
    exec_name = (lead.assigned_executive.name if (lead and lead.assigned_executive) else "Assigned Advisor")
    verification_box = Table([
        [
            Paragraph(f"<b>Lead Status:</b> {lead_status}<br/><b>Assigned Executive:</b> {exec_name}", body_style),
            Paragraph("<b>Executive Sign-off & Scheme Recommendation:</b><br/><br/>________________________________________", body_style)
        ]
    ], colWidths=[270, 270])
    verification_box.setStyle(TableStyle([
        ('BOX', (0, 0), (-1, -1), 1, colors.HexColor("#BDBDBD")),
        ('TOPPADDING', (0, 0), (-1, -1), 8),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 8),
        ('LEFTPADDING', (0, 0), (-1, -1), 8),
        ('RIGHTPADDING', (0, 0), (-1, -1), 8),
    ]))
    elements.append(KeepTogether([verification_box]))

    doc.build(elements)
    buffer.seek(0)
    return buffer.getvalue()
