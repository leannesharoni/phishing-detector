import json
import os

import boto3
import psycopg

# Establishes a connection to the PostgreSQL database.
def get_cloud_connection():
    secret_arn = os.environ["DB_SECRET_ARN"]
    region = os.environ.get("AWS_REGION", "eu-north-1")

    client = boto3.client(
        "secretsmanager",
        region_name=region
    )

    response = client.get_secret_value(
        SecretId=secret_arn
    )

    credentials = json.loads(
        response["SecretString"]
    )

    return psycopg.connect(
        host=os.environ["DB_HOST"],
        dbname=os.environ.get(
            "DB_NAME", "phishing_detector"
        ),
        user=credentials["username"],
        password=credentials["password"],
        port=5432,
        sslmode="require",
        connect_timeout=5
    )
