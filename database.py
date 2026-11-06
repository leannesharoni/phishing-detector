import os
import psycopg
from dotenv import load_dotenv
from datetime import datetime,timezone

load_dotenv()

def get_db_connection():
    connection = psycopg.connect(
        host=os.getenv("DB_HOST"),
        port=os.getenv("DB_PORT"),
        dbname=os.getenv("DB_NAME"),
        user=os.getenv("DB_USER"),
        password=os.getenv("DB_PASSWORD"),
        connect_timeout=5
    )

    return connection


def save_email_to_db(score, risk_level, indicators_count):
    scan_time = datetime.now(timezone.utc)

    with get_db_connection() as connection:
        with connection.cursor() as cursor:
            cursor.execute(
                """
                INSERT INTO scans (scan_time, risk_score, risk_level, indicators_count)
                VALUES (%s, %s, %s, %s)
                """,
                (scan_time, score, risk_level, indicators_count)
            )




def get_scan_history():
        with get_db_connection() as connection:
            with connection.cursor() as cursor:
                cursor.execute(
                    """
                    SELECT id, scan_time, risk_score, risk_level, indicators_count
                    FROM scans
                    ORDER BY id DESC
                    LIMIT 20
                    """
                )
                return cursor.fetchall()


            
if __name__ == "__main__":
    try:
        with get_db_connection() as connection:
            print("Database connection successful")
    except psycopg.OperationalError:
        print("Database connection failed. Please check your database configuration.")