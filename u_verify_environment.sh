#!/bin/bash

# Check if gcloud command is available
if ! command -v gcloud &> /dev/null; then
    echo "Error: gcloud command not found. Please install the Google Cloud SDK and ensure 'gcloud' is in your PATH."
    exit 1
fi

# Check gcloud authentication
gcloud auth list &> /dev/null
if [ $? -ne 0 ]; then
    echo "Error: Not authenticated to gcloud. Please authenticate using 'gcloud auth login' and ensure you have the necessary permissions."
    exit 1
fi

# Prompt for the .env file to use
echo "Enter the path to the .env file to use (e.g. ./myenvfile.env):"
read ENV_FILE

# Check if the provided .env file exists and is readable
if [[ ! -f "$ENV_FILE" || ! -r "$ENV_FILE" ]]; then
    echo "Error: .env file either does not exist or is not readable."
    exit 1
fi

# Source the .env file
source $ENV_FILE

# Set the email for the deploy service account
DEPLOY_SA_EMAIL="${DEPLOY_SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

# Check for IAM Role for deploy
echo "Checking for IAM Roles..."
if gcloud iam roles list --project=$PROJECT_ID | grep -q $DEPLOY_ROLE_NAME; then
    echo "Role $DEPLOY_ROLE_NAME exists."
else
    echo "Role $DEPLOY_ROLE_NAME does not exist."
fi

# Check for Service Account for deploy
echo "Checking for Service Accounts..."
if gcloud iam service-accounts list --project=$PROJECT_ID | grep -q $DEPLOY_SA_EMAIL; then
    echo "Service account $DEPLOY_SA_NAME exists."
else
    echo "Service account $DEPLOY_SA_NAME does not exist."
fi

# Check for IAM Bindings for deploy
echo "Checking for IAM Bindings..."
DEPLOY_BINDINGS=$(gcloud projects get-iam-policy $PROJECT_ID --flatten="bindings[].members" --format='table(bindings.role,bindings.members)' | grep $DEPLOY_SA_EMAIL || echo "")
[ -z "$DEPLOY_BINDINGS" ] && echo "No bindings found for $DEPLOY_SA_NAME." || { echo "Bindings exist for $DEPLOY_SA_NAME:"; echo "$DEPLOY_BINDINGS"; }

# Iterate over each privileged service account and its role
for index in "${!PRIVILEGED_SA_NAMES[@]}"; do
    PRIVILEGED_SA_EMAIL="${PRIVILEGED_SA_NAMES[$index]}@${PROJECT_ID}.iam.gserviceaccount.com"
    PRIVILEGED_ROLE_NAME="${PRIVILEGED_ROLE_NAMES[$index]}"

    # Check for IAM Role
    if gcloud iam roles list --project=$PROJECT_ID | grep -q $PRIVILEGED_ROLE_NAME; then
        echo "Role $PRIVILEGED_ROLE_NAME exists."
    else
        echo "Role $PRIVILEGED_ROLE_NAME does not exist."
    fi

    # Check for Service Account
    if gcloud iam service-accounts list --project=$PROJECT_ID | grep -q $PRIVILEGED_SA_EMAIL; then
        echo "Service account ${PRIVILEGED_SA_NAMES[$index]} exists."
    else
        echo "Service account ${PRIVILEGED_SA_NAMES[$index]} does not exist."
    fi

    # Check for IAM Bindings
    PRIVILEGED_BINDINGS=$(gcloud projects get-iam-policy $PROJECT_ID --flatten="bindings[].members" --format='table(bindings.role,bindings.members)' | grep $PRIVILEGED_SA_EMAIL || echo "")
    [ -z "$PRIVILEGED_BINDINGS" ] && echo "No bindings found for ${PRIVILEGED_SA_NAMES[$index]}." || { echo "Bindings exist for ${PRIVILEGED_SA_NAMES[$index]}:"; echo "$PRIVILEGED_BINDINGS"; }
done

# Check for Secrets
echo "Checking for Secrets..."
if gcloud secrets list --project=$PROJECT_ID | grep -q $SECRET_NAME; then
    echo "Secret $SECRET_NAME exists."
else
    echo "Secret $SECRET_NAME does not exist."
fi

echo "Environment verification completed."
