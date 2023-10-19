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

# Check if required variables are set
declare -a required_vars=("PROJECT_ID" "DEPLOY_ROLE_NAME" "DEPLOY_ROLE_FILE" "DEPLOY_SA_NAME" "SECRET_NAME")
unset_vars=()

for var in "${required_vars[@]}"; do
    if [[ -z "${!var}" ]]; then
        unset_vars+=("$var")
    fi
done

# Check if the arrays are set and not empty
declare -a required_arrays=("PRIVILEGED_SA_NAMES" "PRIVILEGED_ROLE_NAMES" "PRIVILEGED_ROLE_FILES")
empty_arrays=()

for arr in "${required_arrays[@]}"; do
    eval "len=\${#$arr[@]}"
    if [[ -z "${!arr}" || $len -eq 0 ]]; then
        empty_arrays+=("$arr")
    fi
done

# Check for unset required variables
if [[ ${#unset_vars[@]} -ne 0 ]]; then
    echo "Error: The following variables are not set in the provided .env file: ${unset_vars[@]}"
    exit 1
fi

# Check for empty required arrays
if [[ ${#empty_arrays[@]} -ne 0 ]]; then
    echo "Error: The following arrays are not set or empty in the provided .env file: ${empty_arrays[@]}"
    exit 1
fi

# Set the email for the deploy service account
DEPLOY_SA_EMAIL="${DEPLOY_SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

# Function to create or update a role
create_or_update_role() {
    local ROLE_NAME=$1
    local ROLE_FILE=$2
    local ROLE_EXISTS=$(gcloud iam roles describe $ROLE_NAME --project=$PROJECT_ID 2>&1 | grep "name:")
    
    if [ -z "$ROLE_EXISTS" ]; then
        gcloud iam roles create $ROLE_NAME --project=$PROJECT_ID --file=$ROLE_FILE --quiet
        echo "Custom role $ROLE_NAME has been created in project $PROJECT_ID."
    else
        gcloud iam roles update $ROLE_NAME --project=$PROJECT_ID --file=$ROLE_FILE --quiet
        echo "Custom role $ROLE_NAME has been updated in project $PROJECT_ID."
    fi
}

# Create or update the deploy role
create_or_update_role $DEPLOY_ROLE_NAME $DEPLOY_ROLE_FILE

# Function to create a service account if it doesn't exist
create_service_account_if_not_exists() {
    local SA_NAME=$1
    local SA_EMAIL="$SA_NAME@$PROJECT_ID.iam.gserviceaccount.com"
    local SA_EXISTS=$(gcloud iam service-accounts describe $SA_EMAIL 2>&1 | grep "email:")
    
    if [ -z "$SA_EXISTS" ]; then
        gcloud iam service-accounts create $SA_NAME --display-name $SA_NAME --project=$PROJECT_ID --quiet
        echo "Service account $SA_NAME has been created."
    fi
}

# Create deploy service account if it doesn't exist
create_service_account_if_not_exists $DEPLOY_SA_NAME

# Loop over privileged service accounts, roles, and role files to set them up
for index in "${!PRIVILEGED_SA_NAMES[@]}"; do
    PRIVILEGED_SA_NAME=${PRIVILEGED_SA_NAMES[$index]}
    PRIVILEGED_ROLE_NAME=${PRIVILEGED_ROLE_NAMES[$index]}
    PRIVILEGED_ROLE_FILE=${PRIVILEGED_ROLE_FILES[$index]}
    PRIVILEGED_SA_EMAIL="$PRIVILEGED_SA_NAME@$PROJECT_ID.iam.gserviceaccount.com"

    # Create or update privileged role
    create_or_update_role $PRIVILEGED_ROLE_NAME $PRIVILEGED_ROLE_FILE

    # Create privileged service account if it doesn't exist
    create_service_account_if_not_exists $PRIVILEGED_SA_NAME

    # Bind the deploy service account to impersonate the privileged service account
    gcloud iam service-accounts add-iam-policy-binding $PRIVILEGED_SA_EMAIL --member="serviceAccount:$DEPLOY_SA_EMAIL" --role="roles/iam.serviceAccountTokenCreator" --quiet
    echo "Granted Service Account Token Creator role to $DEPLOY_SA_NAME for impersonating $PRIVILEGED_SA_NAME."

    # Bind roles to privileged service account
    gcloud projects add-iam-policy-binding $PROJECT_ID --member="serviceAccount:$PRIVILEGED_SA_EMAIL" --role="projects/$PROJECT_ID/roles/$PRIVILEGED_ROLE_NAME" --quiet
    echo "Custom role $PRIVILEGED_ROLE_NAME has been bound to service account $PRIVILEGED_SA_EMAIL."
done

# ... [the rest of your script up to secret creation]

# Create the secret if it doesn't exist
SECRET_EXISTS=$(gcloud secrets describe $SECRET_NAME --project=$PROJECT_ID 2>&1 | grep "name:")

if [ -z "$SECRET_EXISTS" ]; then
    gcloud secrets create $SECRET_NAME --replication-policy="automatic" --project=$PROJECT_ID --quiet
    echo "Secret $SECRET_NAME has been created."

    SA_KEY_FILE=$(mktemp /tmp/sa_key.XXXXXX.json)  # Unique temporary file
    chmod 600 $SA_KEY_FILE  # Restrictive permissions

    gcloud iam service-accounts keys create $SA_KEY_FILE --iam-account $DEPLOY_SA_EMAIL --project=$PROJECT_ID --quiet
    echo "Service account key for $DEPLOY_SA_EMAIL has been created."

    gcloud secrets versions add $SECRET_NAME --data-file="$SA_KEY_FILE" --project=$PROJECT_ID --quiet
    echo "Added service account key to the secret $SECRET_NAME."

    rm -f $SA_KEY_FILE
fi

# Grant access to the secret for the deploy service account
gcloud secrets add-iam-policy-binding $SECRET_NAME --project=$PROJECT_ID --role roles/secretmanager.secretAccessor --member serviceAccount:$DEPLOY_SA_EMAIL --quiet
echo "Granted secretAccessor role for secret $SECRET_NAME to $DEPLOY_SA_NAME."
