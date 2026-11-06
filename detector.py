#import necessary libraries for email content analysis
import re
import ipaddress 
from urllib.parse import urlsplit
from email.utils import parseaddr

# Checks for suspicious words in an email content and returns a list of detected words
def check_suspicious_words(email_content):
    suspicious_words = ["lottery", "prize", "winner", "urgent","click here", "free", "offer","password", "bank account", "limited time", "risk-free", "guaranteed", "act now", "exclusive deal","verify your account", "claim your reward", "investment opportunity", "get rich quick", "work from home", "no risk", "instant access", "confidential information", "personal information", "sensitive data"]
    
    detected_words = []
    #create a list of suspicious words in the email content
    for word in suspicious_words:
        if word in email_content.lower():
            detected_words.append(word)
    return detected_words


# Checks for suspicious links in an email content and returns a list of detected links

def check_suspicious_links(email_content):
    links = re.findall(r'https?://[^\s<>"]+', email_content)

    suspicious_links = []

    trusted_domains = [
        "paypal.com",
        "google.com",
        "microsoft.com",
        "amazon.com",
        "apple.com"
    ]

    for link in links:
        clean_link = link.rstrip(".,);!?")

        try:
            parsed_url = urlsplit(clean_link)
            hostname = parsed_url.hostname
        except ValueError:
            continue

        if hostname is None:
            continue

        hostname = hostname.lower().removeprefix("www.")

        is_suspicious = False

        # Rule 1: Direct IP address
        try:
            ipaddress.ip_address(hostname)
            is_suspicious = True
        except ValueError:
            pass

        # Rule 2: Domain similar to a trusted domain
        for trusted_domain in trusted_domains:
            if len(hostname) != len(trusted_domain):
                continue

            differences = sum(
                char1 != char2
                for char1, char2 in zip(hostname, trusted_domain)
            )

            if differences == 1:
                is_suspicious = True
                break

        # Rule 3: Username information inside the URL
        if parsed_url.username is not None:
            is_suspicious = True

        if is_suspicious:
            suspicious_links.append(clean_link)

    return suspicious_links


# Extracts the sender's email address from the email content and returns the domain
def extract_email_sender(email_content):
    for line in email_content.splitlines():
        if line.lower().startswith("from:"):
            sender_text = line.split(":", 1)[1].strip()

            sender_email = parseaddr(sender_text)[1]

            if "@" not in sender_email:
                return None

            domain = sender_email.rsplit("@", 1)[1].lower()
            return domain

#helper function to detect if two domains differ by only one character
def is_one_char_diff(domain1, domain2):
    if len(domain1) != len(domain2):
        return False

    differences = 0
    for char1, char2 in zip(domain1, domain2):
        if char1 != char2:
            differences += 1
    return differences == 1


# Checks for suspicious sender domains in an email content and returns a list of detected suspicious domains
def check_suspicious_sender(email_content):
    trusted_domains = ["amazon.com", "microsoft.com", "paypal.com", "gmail.com", "yahoo.com", "outlook.com", "hotmail.com", "icloud.com"]
    sender_domain = extract_email_sender(email_content)

    if sender_domain is None:
        return []

    detected_suspicious_domains = []

    for trusted_domain in trusted_domains:
        if sender_domain == trusted_domain:
            continue
        if is_one_char_diff(sender_domain, trusted_domain):
            detected_suspicious_domains.append(f"Suspicious sender: {sender_domain} resembles {trusted_domain}")

    return detected_suspicious_domains


# Calculates a risk score based different factors
def calculate_risk(words,links,senders,attachments):
    score = 0

    
    score += len(words) * 10
    score += len(links) * 30
    score += len(senders) * 40
    score += len(attachments) * 25

    score = min(score, 100)

    if score >= 60:
        risk_level = "High"
    elif score >= 30:
        risk_level = "Medium"
    else:
        risk_level = "Low"
    return score, risk_level

# Checks for suspicious attachments in an email content and returns a list of detected attachments
def check_suspicious_attachments(email_content):
    dangerous_extensions = [".exe", ".bat", ".cmd", ".scr", ".pif", ".js", ".vbs", ".jar", ".com", ".cpl"]
    suspicious_attachments = []

    for line in email_content.splitlines():
        if line.lower().startswith("attachment:"):
            filename = line.split(":", 1)[1].strip()

            for extension in dangerous_extensions:
                if filename.lower().endswith(extension):
                    suspicious_attachments.append(filename)
                    break
    return suspicious_attachments


def analyze_email(email_content):
    detected_words = check_suspicious_words(email_content)
    detected_links = check_suspicious_links(email_content)
    detected_senders = check_suspicious_sender(email_content)
    detected_attachments = check_suspicious_attachments(email_content)

    score, risk_level = calculate_risk(
        detected_words,
        detected_links,
        detected_senders,
        detected_attachments
    )

    indicators_count = (
        len(detected_words)
        + len(detected_links)
        + len(detected_senders)
        + len(detected_attachments)
    )

    return {
        "words": detected_words,
        "links": detected_links,
        "senders": detected_senders,
        "attachments": detected_attachments,
        "indicators_count": indicators_count,
        "score": score,
        "risk_level": risk_level
    }

