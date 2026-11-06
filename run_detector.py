
from detector import analyze_email
from database import save_email_to_db, get_scan_history


def main():
    with open("suspicious_email.txt", "r", encoding="utf-8") as file:
        email_content = file.read()

    result = analyze_email(email_content)

    print("Email Phishing Analysis")
    print("-----------------------")
    print("Suspicious Words:", result["words"])
    print("Suspicious Links:", result["links"])
    print("Spoofed Sender:", result["senders"])
    print("Suspicious Attachments:", result["attachments"])
    print("Risk Score:", result["score"])
    print("Risk Level:", result["risk_level"])

    save_email_to_db(
        result["score"],
        result["risk_level"],
        result["indicators_count"]
    )

    print("\nScan History")
    print("-----------------------")

    for scan in get_scan_history():
        print(scan)


if __name__ == "__main__":
    main()