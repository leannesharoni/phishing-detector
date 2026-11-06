#!/bin/bash
set -euo pipefail

# Save installation output to a log file
exec > >(tee -a /var/log/phishing-setup.log) 2>&1

echo "Starting Phishing Detector setup"

# Install tools needed by our application
dnf install -y python3.11 unzip awscli amazon-cloudwatch-agent

# Create the application error log file
touch /var/log/phishing-error.log
chown ec2-user:ec2-user /var/log/phishing-error.log

# Install the CloudWatch Agent configuration
echo "${cwagent_config_b64}" | base64 -d \
  > /opt/aws/amazon-cloudwatch-agent/etc/phishing-agent.json

# Start collecting logs
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -s \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/phishing-agent.json
# Create the application folder
mkdir -p /opt/phishing-detector

# Download our private deployment package from S3
for attempt in 1 2 3 4 5; do
  if aws s3 cp \
    "s3://${bucket_name}/app.zip" \
    /tmp/app.zip \
    --region "${aws_region}"; then
    break
  fi

  if [ "$attempt" -eq 5 ]; then
    echo "Failed to download app.zip"
    exit 1
  fi

  sleep 10
done

# Extract our Python application
unzip -o /tmp/app.zip -d /opt/phishing-detector

# Create an isolated Python environment
python3.11 -m venv /opt/phishing-detector/.venv

# Install application dependencies
/opt/phishing-detector/.venv/bin/python -m pip install \
  --no-cache-dir \
  -r /opt/phishing-detector/requirements-cloud.txt

# Give the application user ownership
chown -R ec2-user:ec2-user /opt/phishing-detector

# Install the systemd service definition
echo "${service_content_b64}" | base64 -d \
  > /etc/systemd/system/phishing-detector.service

# Start the application and enable startup on reboot
systemctl daemon-reload
systemctl enable --now phishing-detector

echo "Phishing Detector installation completed"
