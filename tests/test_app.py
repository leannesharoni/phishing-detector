
import unittest
from io import BytesIO
from unittest.mock import patch

import psycopg

from app import app


class TestFlaskApp(unittest.TestCase):

    def setUp(self):
        app.config["TESTING"] = True
        self.client = app.test_client()

    def test_home_page(self):
        response = self.client.get("/")

        self.assertEqual(response.status_code, 200)
        self.assertIn(b"Email Phishing Detector", response.data)

    def test_no_file_selected(self):
        response = self.client.post(
            "/",
            data={},
            content_type="multipart/form-data"
        )

        self.assertEqual(response.status_code, 200)
        self.assertIn(b"No file selected", response.data)

    def test_invalid_file_type(self):
        response = self.client.post(
            "/",
            data={
                "email_file": (BytesIO(b"hello"), "test.py")
            }
        )

        self.assertIn(b"Invalid file type", response.data)

    def test_empty_file(self):
        response = self.client.post(
            "/",
            data={
                "email_file": (BytesIO(b""), "empty.txt")
            }
        )

        self.assertIn(b"The uploaded file is empty", response.data)

    def test_file_too_large(self):
        large_content = b"A" * (1024 * 1024 + 1)

        response = self.client.post(
            "/",
            data={
                "email_file": (BytesIO(large_content), "large.txt")
            }
        )

        self.assertEqual(response.status_code, 413)

    @patch("app.save_email_to_db")
    def test_successful_scan(self, mock_save):
        email = b"""
From: security@paypa1.com
Subject: Urgent Account Verification

Your account has been suspended.
Click here to verify your account:
http://192.0.2.15/login

Attachment: invoice.exe
"""

        response = self.client.post(
            "/",
            data={
                "email_file": (BytesIO(email), "email.txt")
            }
        )

        self.assertEqual(response.status_code, 200)
        self.assertIn(b"Risk Score", response.data)
        self.assertIn(b"High", response.data)
        mock_save.assert_called_once()

    @patch("app.save_email_to_db")
    def test_database_failure(self, mock_save):
        mock_save.side_effect = psycopg.OperationalError(
            "Database unavailable"
        )

        response = self.client.post(
            "/",
            data={
                "email_file": (
                    BytesIO(b"Urgent! Click here"),
                    "email.txt"
                )
            }
        )

        self.assertEqual(response.status_code, 200)
        self.assertIn(
            b"Analysis completed, but saving the scan failed.",
            response.data
        )


if __name__ == "__main__":
    unittest.main()
