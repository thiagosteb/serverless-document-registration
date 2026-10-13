import json
import uuid
import boto3

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table("DocRegistration")
s3 = boto3.client("s3")


def lambda_handler(event, context):

    document_id = str(uuid.uuid4())

    user_id = event["user_id"]
    filename = event["filename"]

    metadata = {
        "document_id": document_id,
        "user_id": user_id,
        "filename": filename,
        "status": "TEST",
        "s3_key": f"documents/{user_id}/{document_id}.pdf"
    }

    table.put_item(
        Item=metadata
    )

    return {
        "statusCode": 200,
        "body": json.dumps(metadata)

        
    }

import boto3

s3 = boto3.client("s3")

s3.put_object(
    Bucket="document-registration-and-upload-fpt",
    Key="test/test-file.txt",
    Body="Hello from Lambda"
)

def lambda_handler(event, context):

    body = json.loads(event["body"])

    user_id = body["user_id"]
    filename = body["filename"]

        