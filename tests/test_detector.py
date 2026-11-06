
import unittest

from detector import (
    analyze_email,
    check_suspicious_words,
    check_suspicious_links
)


class TestPhishingDetector(unittest.TestCase):

    def test_safe_email(self):
        email = """
From: friend@example.com
Subject: Lunch tomorrow

Hi!
Are we still meeting for lunch tomorrow?
See you soon!
"""

        result = analyze_email(email)

        self.assertEqual(result["score"], 0)
        self.assertEqual(result["risk_level"], "Low")
        self.assertEqual(result["indicators_count"], 0)

    def test_duplicate_words(self):
        email = "Urgent! Click here to verify your account."

        detected = check_suspicious_words(email)

        self.assertEqual(len(detected), len(set(detected)))

    def test_ip_address_link(self):
        email = "Visit http://192.0.2.15/login"

        links = check_suspicious_links(email)

        self.assertIn(
            "http://192.0.2.15/login",
            links
        )

    def test_risk_score_limit(self):
        email = """
From: security@paypa1.com
Subject: Urgent Account Verification

Your account has been suspended.
Click here immediately to verify your account:
http://192.0.2.15/login

Attachment: invoice.exe
"""

        result = analyze_email(email)

        self.assertGreaterEqual(result["score"], 0)
        self.assertLessEqual(result["score"], 100)
        self.assertEqual(result["risk_level"], "High")

    
    def test_spoofed_link(self):
        email = "Visit https://paypa1.com/login"

        links = check_suspicious_links(email)

        self.assertIn(
            "https://paypa1.com/login",
            links
        )

    def test_trusted_link_not_flagged(self):
        email = "Visit https://paypal.com/login"

        links = check_suspicious_links(email)

        self.assertEqual(links, [])

    def test_url_with_username(self):
        email = "Visit https://paypal.com@fake.example/login"

        links = check_suspicious_links(email)

        self.assertIn(
            "https://paypal.com@fake.example/login",
            links
        )


if __name__ == "__main__":
    unittest.main()
