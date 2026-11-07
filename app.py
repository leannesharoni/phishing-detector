from flask import Flask, request, render_template
from werkzeug.exceptions import RequestEntityTooLarge
from detector import analyze_email
from database import save_email_to_db, get_scan_history
import psycopg

app = Flask(__name__)

app.config['MAX_CONTENT_LENGTH'] = 1024 * 1024  # Limit file size 

@app.route('/', methods=['GET', 'POST'])
def home():
    result = None
    error_message = None

    if request.method == 'POST':
        uploaded_file = request.files.get('email_file')

        if uploaded_file is None or uploaded_file.filename == "":
            error_message = "No file selected. Please choose a file to upload."
        elif not uploaded_file.filename.lower().endswith(".txt"):
            error_message = "Invalid file type. Please upload a .txt file."
        else:
            try:
                email_content = uploaded_file.read().decode('utf-8')

                if not email_content.strip():
                    error_message = "The uploaded file is empty. Please provide a valid email content." 
                else:
                    result = analyze_email(email_content)
                    try:
                        save_email_to_db(result['score'], result['risk_level'], result['indicators_count'])
                    except psycopg.Error:
                        app.logger.exception("Database error occurred while saving the scan result.")
                        error_message = "Analysis completed, but saving the scan failed."
            except UnicodeDecodeError:
                error_message = "Error decoding the file. Please ensure it is a valid UTF-8 encoded text file."

    return render_template('index.html', result=result, error_message=error_message)

@app.errorhandler(RequestEntityTooLarge)


def handle_file_too_large(error):
    return "File is too large. Please upload a file smaller than 1MB.", 413

@app.route('/history', methods=['GET'])
def history():
    scan_history = []
    error_message = None
    try:
        scan_history = get_scan_history()
    except psycopg.Error:
        app.logger.exception("Database error occurred while fetching scan history.")
        error_message = "Unable to retrieve scan history at this time. Please try again later."
    return render_template('history.html', scans=scan_history, error_message=error_message)



@app.route("/health", methods=["GET"])
def health():
    return {"status": "ok"}, 200

if __name__ == '__main__':
    app.run(debug=False)