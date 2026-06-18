import json
import boto3
import os
import logging

# Set up logging so we can see output in CloudWatch
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize clients outside the handler for reuse across warm invocations
ses = boto3.client("ses")
sns = boto3.client("sns")


def lambda_handler(event, context):
    # Environment variables injected by Terraform
    sender_email = os.environ["SES_SENDER_EMAIL"]   # verified SES identity (sender)

    for record in event["Records"]:
        # Parse the SQS message body
        body = json.loads(record["body"])

        email     = body["email"]
        phone     = body["phone"]
        result    = body["result"]
        full_name = body.get("full_name", "Étudiant")
        subjects  = body.get("subjects", [])

        # ── Build shared content ──────────────────────────────────
        result_colour = "#1a6b3c" if result == "Admis" else "#c0392b"

        # HTML subject rows
        subject_rows_html = "".join([
            f"<tr><td style='padding:6px 12px;border-bottom:1px solid #eee'>{s['subject_name']}</td>"
            f"<td style='padding:6px 12px;border-bottom:1px solid #eee;text-align:center'>"
            f"<strong>{s['grade']}/20</strong></td></tr>"
            for s in subjects
        ])

        # Plain-text subject lines
        subject_rows_text = "\n".join([
            f"  - {s['subject_name']} : {s['grade']}/20"
            for s in subjects
        ])

        # ── 1. SES — HTML + plain-text email ─────────────────────
        subject_line = "Résultats Bac 2026 — Massar"

        html_body = f"""<!DOCTYPE html>
<html lang="fr">
<body style="margin:0;padding:0;background:#f4f6f8;font-family:Arial,Helvetica,sans-serif">
  <table width="100%" cellpadding="0" cellspacing="0">
    <tr><td align="center" style="padding:32px 16px">
      <table width="600" cellpadding="0" cellspacing="0"
             style="background:#fff;border-radius:8px;overflow:hidden;box-shadow:0 2px 8px rgba(0,0,0,.08)">

        <!-- Header -->
        <tr><td style="background:#1a6b3c;padding:28px 32px">
          <h1 style="margin:0;color:#fff;font-size:22px">Massar — Résultats Bac 2026</h1>
          <p style="margin:6px 0 0;color:#a8d5b5;font-size:14px">
            Ministère de l'Éducation Nationale, Maroc
          </p>
        </td></tr>

        <!-- Body -->
        <tr><td style="padding:32px">
          <p style="margin:0 0 16px;font-size:16px">Bonjour <strong>{full_name}</strong>,</p>
          <p style="margin:0 0 24px;font-size:15px">
            Votre résultat officiel du Baccalauréat 2026 est disponible :
          </p>

          <!-- Result badge -->
          <div style="text-align:center;margin:0 0 28px">
            <span style="display:inline-block;background:{result_colour};color:#fff;
                         font-size:20px;font-weight:bold;padding:12px 40px;border-radius:6px">
              {result}
            </span>
          </div>

          <!-- Subject grades table -->
          {"<h3 style='margin:0 0 12px;font-size:15px;color:#444'>Notes obtenues :</h3><table width='100%' cellpadding='0' cellspacing='0' style='border:1px solid #eee;border-radius:4px'><tr style='background:#f4f6f8'><th style='padding:8px 12px;text-align:left;font-size:13px'>Matière</th><th style='padding:8px 12px;text-align:center;font-size:13px'>Note</th></tr>" + subject_rows_html + "</table>" if subjects else ""}

          <p style="margin:28px 0 0;font-size:14px;color:#555">
            Connectez-vous sur
            <a href="https://massar.ma" style="color:#1a6b3c">massar.ma</a>
            pour accéder à l'intégralité de votre relevé de notes.
          </p>
        </td></tr>

        <!-- Footer -->
        <tr><td style="background:#f4f6f8;padding:16px 32px;text-align:center">
          <p style="margin:0;font-size:12px;color:#999">
            © 2026 Ministère de l'Éducation Nationale, Préscolaire et Sports — Royaume du Maroc
          </p>
        </td></tr>

      </table>
    </td></tr>
  </table>
</body>
</html>"""

        text_body = (
            f"Résultats Bac 2026 — Massar\n\n"
            f"Bonjour {full_name},\n\n"
            f"Votre résultat : {result}\n"
            + (f"\nNotes obtenues :\n{subject_rows_text}\n" if subjects else "")
            + "\nConnectez-vous sur massar.ma pour plus de détails.\n\n"
            "© 2026 Ministère de l'Éducation Nationale — Royaume du Maroc"
        )

        try:
            ses.send_email(
                Source=sender_email,
                Destination={"ToAddresses": [email]},
                Message={
                    "Subject": {"Data": subject_line, "Charset": "UTF-8"},
                    "Body": {
                        "Text": {"Data": text_body,  "Charset": "UTF-8"},
                        "Html": {"Data": html_body,  "Charset": "UTF-8"},
                    },
                },
            )
            logger.info(f"SES email sent to {email} — result: {result}")
        except Exception as e:
            logger.error(f"SES send_email failed for {email}: {e}")
            raise

        # ── 2. SNS — plain SMS directly to student's phone ───────
        sms_message = (
            f"Massar | Résultats Bac 2026\n"
            f"{full_name} : {result}\n"
            "Détails sur massar.ma"
        )

        try:
            sns.publish(
                PhoneNumber=phone,   # Direct SMS — no topic subscription required
                Message=sms_message,
                MessageAttributes={
                    "AWS.SNS.SMS.SenderID": {
                        "DataType": "String",
                        "StringValue": "Massar"
                    },
                    "AWS.SNS.SMS.SMSType": {
                        "DataType": "String",
                        "StringValue": "Transactional"  # Highest delivery priority
                    }
                }
            )
            logger.info(f"SNS SMS sent to {phone} — result: {result}")
        except Exception as e:
            logger.error(f"SNS publish failed for {phone}: {e}")
            raise