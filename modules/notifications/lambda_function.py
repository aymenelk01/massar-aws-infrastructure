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
        
        # build the notification message
        message = f"Résultats Bac 2026: Votre résultat est: {result}. Connectez-vous sur massar.ma pour les détails."
        
        # publish to SNS — SNS delivers to SMS and email simultaneously
        sns.publish(
            TopicArn=sns_topic_arn,
            Message=message,
            Subject="Résultats Bac 2026"
        )
        
        logger.info(f"Notification sent to {email} and {phone} — result: {result}")