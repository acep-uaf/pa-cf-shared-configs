#!/bin/bash

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

# Check if required variables are set
declare -a required_vars=("PROJECT_ID" "DEPLOY_ROLE_NAME" "DEPLOY_ROLE_FILE" "PRIVILEGED_ROLE_NAME" "PRIVILEGED_ROLE_FILE" "DEPLOY_SA_NAME" "PRIVILEGED_SA_NAME" "SECRET_NAME")
unset_vars=()

for var in "${required_vars[@]}"; do
    if [[ -z "${!var}" ]]; then
        unset_vars+=("$var")
    fi
done

if [[ ${#unset_vars[@]} -ne 0 ]]; then
    echo "Error: The following variables are not set in the provided .env file: ${unset_vars[@]}"
    exit 1
fi

# Set the emails for the service accounts
DEPLOY_SA_EMAIL="${DEPLOY_SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"
PRIVILEGED_SA_EMAIL="${PRIVILEGED_SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

# Check for IAM Roles
echo "Checking for IAM Roles..."
if gcloud iam roles list --project=$PROJECT_ID | grep -q $DEPLOY_ROLE_NAME; then
    echo "Role $DEPLOY_ROLE_NAME exists."
else
    echo "Role $DEPLOY_ROLE_NAME does not exist."
fi

if gcloud iam roles list --project=$PROJECT_ID | grep -q $PRIVILEGED_ROLE_NAME; then
    echo "Role $PRIVILEGED_ROLE_NAME exists."
else
    echo "Role $PRIVILEGED_ROLE_NAME does not exist."
fi

# Check for Service Accounts
echo "Checking for Service Accounts..."
if gcloud iam service-accounts list --project=$PROJECT_ID | grep -q $DEPLOY_SA_EMAIL; then
    echo "Service account $DEPLOY_SA_NAME exists."
else
    echo "Service account $DEPLOY_SA_NAME does not exist."
fi

if gcloud iam service-accounts list --project=$PROJECT_ID | grep -q $PRIVILEGED_SA_EMAIL; then
    echo "Service account $PRIVILEGED_SA_NAME exists."
else
    echo "Service account $PRIVILEGED_SA_NAME does not exist."
fi

# Check for IAM Bindings
echo "Checking for IAM Bindings..."
DEPLOY_BINDINGS=$(gcloud projects get-iam-policy $PROJECT_ID --flatten="bindings[].members" --format='table(bindings.role,bindings.members)' | grep $DEPLOY_SA_EMAIL || echo "")
PRIVILEGED_BINDINGS=$(gcloud projects get-iam-policy $PROJECT_ID --flatten="bindings[].members" --format='table(bindings.role,bindings.members)' | grep $PRIVILEGED_SA_EMAIL || echo "")

[ -z "$DEPLOY_BINDINGS" ] && echo "No bindings found for $DEPLOY_SA_NAME." || { echo "Bindings exist for $DEPLOY_SA_NAME:"; echo "$DEPLOY_BINDINGS"; }
[ -z "$PRIVILEGED_BINDINGS" ] && echo "No bindings found for $PRIVILEGED_SA_NAME." || { echo "Bindings exist for $PRIVILEGED_SA_NAME:"; echo "$PRIVILEGED_BINDINGS"; }

# Check for Secrets
echo "Checking for Secrets..."
if gcloud secrets list --project=$PROJECT_ID | grep -q $SECRET_NAME; then
    echo "Secret $SECRET_NAME exists."
else
    echo "Secret $SECRET_NAME does not exist."
fi

echo "Environment verification completed."
