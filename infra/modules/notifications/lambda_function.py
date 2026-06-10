import json
import boto3
import os
import logging

# set up logging so we can see output in CloudWatch
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# initialize SNS client outside the handler for reuse across invocations
sns = boto3.client("sns")

def lambda_handler(event, context):
    # get SNS topic ARN from environment variable injected by Terraform
    sns_topic_arn = os.environ["SNS_TOPIC_ARN"]
    
    # event["Records"] contains the batch of SQS messages
    for record in event["Records"]:
        # parse the message body from JSON string to Python dict
        body = json.loads(record["body"])
        
        email  = body["email"]
        phone  = body["phone"]
        result = body["result"]
        full_name = body.get("full_name", "Étudiant")
        subjects = body.get("subjects", [])
        
        # format subjects & marks
        marks_summary = ""
        if subjects:
            marks_summary = "\n\nNotes obtenues :\n" + "\n".join([f"- {s['subject_name']} : {s['grade']}/20" for s in subjects])
            
        # build the notification message
        message = f"Résultats Bac 2026 pour {full_name} :\nRésultat : {result}{marks_summary}\n\nConnectez-vous sur massar.ma pour plus de détails."
        
        # publish to SNS — SNS delivers to SMS and email simultaneously
        sns.publish(
            TopicArn=sns_topic_arn,
            Message=message,
            Subject="Résultats Bac 2026"
        )
        
        logger.info(f"Notification sent to {email} and {phone} — result: {result}")