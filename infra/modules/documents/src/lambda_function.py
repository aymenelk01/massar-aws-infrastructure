import os
import json
import boto3
import logging
from fpdf import FPDF

logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize AWS S3 Client
s3_client = boto3.client("s3")
BUCKET_NAME = os.environ.get("DOCUMENTS_BUCKET_NAME")

class BacDiplomaPDF(FPDF):
    def draw_certificate_border(self):
        """Draws a professional, premium Moroccan double border (Green and Gold)."""
        # A4 Landscape dimensions are 297mm x 210mm
        self.set_line_width(2.0)
        self.set_draw_color(26, 107, 60) # Moroccan Green (RGB)
        self.rect(10, 10, 277, 190)
        
        self.set_line_width(0.8)
        self.set_draw_color(212, 175, 55) # Gold (RGB)
        self.rect(13, 13, 271, 184)

def calculate_mention(average):
    """Calculates French Baccalaureate mentions based on average grade."""
    if average >= 16.0:
        return "Très Bien"
    elif average >= 14.0:
        return "Bien"
    elif average >= 12.0:
        return "Assez Bien"
    else:
        return "Passable"

def generate_diploma(student):
    """Creates a beautifully formatted PDF of the Moroccan Baccalaureate Diploma."""
    pdf = BacDiplomaPDF(orientation="landscape", unit="mm", format="a4")
    pdf.add_page()
    pdf.draw_certificate_border()
    
    # ── Header Section ───────────────────────────────────────────
    pdf.set_y(22)
    pdf.set_font("helvetica", "B", 18)
    pdf.set_text_color(26, 107, 60) # Moroccan Green
    pdf.cell(0, 8, "ROYAUME DU MAROC", align="C", new_x="LMARGIN", new_y="NEXT")
    
    pdf.set_font("helvetica", "B", 11)
    pdf.set_text_color(100, 110, 120)
    pdf.cell(0, 6, "Ministère de l'Éducation Nationale, du Préscolaire et des Sports", align="C", new_x="LMARGIN", new_y="NEXT")
    
    # ── Main Title ───────────────────────────────────────────────
    pdf.set_y(52)
    pdf.set_font("helvetica", "B", 28)
    pdf.set_text_color(212, 175, 55) # Gold
    pdf.cell(0, 12, "DIPLÔME DU BACCALAURÉAT", align="C", new_x="LMARGIN", new_y="NEXT")
    
    pdf.set_y(68)
    pdf.set_font("times", "I", 14)
    pdf.set_text_color(50, 50, 50)
    pdf.cell(0, 8, "Décerné officiellement à l'étudiant(e) :", align="C", new_x="LMARGIN", new_y="NEXT")
    
    # ── Recipient Name ───────────────────────────────────────────
    pdf.set_y(82)
    pdf.set_font("helvetica", "B", 24)
    pdf.set_text_color(30, 41, 59) # Slate Dark
    pdf.cell(0, 10, student["full_name"], align="C", new_x="LMARGIN", new_y="NEXT")
    
    # ── Details Block ────────────────────────────────────────────
    pdf.set_y(102)
    pdf.set_font("helvetica", "", 12)
    pdf.set_text_color(70, 70, 70)
    pdf.cell(0, 6, f"Identifiant Unique (Code Massar) : {student['code_massar']}", align="C", new_x="LMARGIN", new_y="NEXT")
    
    # Average and Mention calculation
    average = float(student.get("average", 10.00))
    mention = calculate_mention(average)
    
    pdf.set_y(114)
    pdf.set_font("helvetica", "B", 13)
    pdf.set_text_color(26, 107, 60) # Green
    pdf.cell(0, 8, f"Moyenne Générale : {average:.2f}/20    |    Mention : {mention}", align="C", new_x="LMARGIN", new_y="NEXT")
    
    # ── Footnote / Verification ──────────────────────────────────
    pdf.set_y(140)
    pdf.set_font("times", "I", 11)
    pdf.set_text_color(110, 110, 110)
    pdf.cell(0, 6, "Ce diplôme électronique est signé numériquement et stocké de manière sécurisée sur la plateforme Massar.", align="C", new_x="LMARGIN", new_y="NEXT")
    
    # ── Signature Blocks ─────────────────────────────────────────
    pdf.set_y(160)
    pdf.set_font("helvetica", "B", 10)
    pdf.set_text_color(50, 50, 50)
    
    pdf.set_x(30)
    pdf.cell(100, 6, "Le Directeur du Centre des Examens", align="L")
    
    pdf.set_x(170)
    pdf.cell(100, 6, "Le Ministre de l'Éducation Nationale", align="R")
    
    return pdf.output()

def lambda_handler(event, context):
    logger.info(f"Received SQS Event: {json.dumps(event)}")
    
    for record in event["Records"]:
        try:
            student = json.loads(record["body"])
            
            # Message verification
            code_massar = student.get("code_massar")
            full_name = student.get("full_name")
            
            if not code_massar or not full_name:
                logger.error("Invalid message format: missing 'code_massar' or 'full_name'")
                continue
                
            # Verify result is Admis
            result = student.get("result", "Ajourné")
            if result != "Admis":
                logger.info(f"Skipping diploma generation for student {code_massar} - Status is '{result}'")
                continue
            
            # Generate the PDF bytearray
            pdf_bytes = generate_diploma(student)
            
            # Upload PDF bytearray directly to the private S3 documents bucket
            s3_key = f"diplomas/{code_massar}_bac_diploma.pdf"
            logger.info(f"Uploading diploma for {code_massar} to S3 bucket '{BUCKET_NAME}'...")
            
            s3_client.put_object(
                Bucket=BUCKET_NAME,
                Key=s3_key,
                Body=pdf_bytes,
                ContentType="application/pdf"
            )
            
            logger.info(f"Successfully generated and stored diploma: {s3_key}")
            
        except Exception as e:
            logger.error(f"Failed to process record: {e}", exc_info=True)
            raise e