#!/bin/bash

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    echo "Error: gcloud could not be found. Please install the Google Cloud SDK."
    exit 1
fi

# Prompt the user for PROJECT_ID
read -p "Enter your GCP Project ID: " PROJECT_ID

# Check if PROJECT_ID is provided
if [ -z "$PROJECT_ID" ]; then
    echo "Error: Project ID must be provided."
    exit 1
fi

# Create a backup directory if it doesn't exist
BACKUP_DIR="iam-backups"
mkdir -p $BACKUP_DIR

# Define the backup file name
TIMESTAMP=$(date +%Y%m%d%H%M%S)
BACKUP_FILE="$BACKUP_DIR/backup-iam-policy-$PROJECT_ID-$TIMESTAMP.json"

# Fetch and backup the IAM policy
gcloud projects get-iam-policy $PROJECT_ID > $BACKUP_FILE

# Check if the backup was successful
if [ $? -eq 0 ]; then
    echo "IAM policy backup was successful. Backup stored in $BACKUP_FILE."
else
    echo "Error: Failed to backup IAM policy."
    exit 1
fi
