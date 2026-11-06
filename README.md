
# Email Phishing Detector

A Python based application for detecting common phishing  indicators in email text files.

## Features

- Upload and analyze email text files through a web interface
- Detect suspicious keywords and phrases
- Detect suspicious links, IP addresses, and lookalike domains
- Identify potentially suspicious sender domains
- Identify suspicious attachment filenames
- Calculate risk score from 0 to 100 depends on the suspicious type
- Display Low, Medium, or High risk levels
- Store scan summaries in PostgreSQL
- Display recent scan history
- Handle file validation and database connection errors

## Technologies

- Python
- Flask
- PostgreSQL
- Psycopg
- HTML and CSS
- unittest

## Project Structure

- app.py: Flask web application
- detector.py: Phishing detection logic
- database.py: PostgreSQL access
- run_detector.py: Command-line entry point
- templates/: HTML pages
- tests/: Automated tests
- schema.sql: Database table definition

## Setup

Requirements:
- Python
- PostgreSQL

1. Create a Python virtual environment:

   python -m venv .venv

2. Activate the virtual environment on Windows:

   .\.venv\Scripts\Activate.ps1

3. Install dependencies:

   python -m pip install -r requirements.txt

4. Create a PostgreSQL database named phishing_detector.

5. Execute schema.sql in that database using a database
   administrator or another role with schema creation privileges.

6. Create an application database user with permission to connect
   to the database and SELECT and INSERT into the scans table.
   Grant the required schema and identity-sequence permissions.

7. Copy .env.example to .env and fill in your database credentials.

## Run the Web Application

python app.py

Open:
http://127.0.0.1:5000

## Run the Command-Line Script

python run_detector.py

The script analyzes suspicious_email.txt and stores
the scan summary in PostgreSQL.

## Run Automated Tests

python -m unittest discover -s tests -v

## Limitations

- Detection is based on predefined rules, not machine learning.
- A low score does not guarantee that an email is safe.
- Attachment analysis checks filenames, not attachment contents.
- URL analysis does not visit external websites.
- Sender spoofing detection does not perform SPF, DKIM,
  or DMARC verification.
- The built-in Flask server is intended for development,
  not production deployment.
