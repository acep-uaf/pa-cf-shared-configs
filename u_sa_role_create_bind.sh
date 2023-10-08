#!/bin/bash

# Prompt for the .env file to use
echo "Enter the path to the .env file to use (e.g. ./myenvfile.env):"
read ENV_FILE

# Source the .env file
source $ENV_FILE

# Set the emails for the service accounts
DEPLOY_SA_EMAIL="${DEPLOY_SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"
PRIVILEGED_SA_EMAIL="${PRIVILEGED_SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

# Function to create or update a role
create_or_update_role() {
    local ROLE_NAME=$1
    local ROLE_FILE=$2
    local ROLE_EXISTS=$(gcloud iam roles describe $ROLE_NAME --project=$PROJECT_ID 2>&1 | grep "name:")
    
    if [ -z "$ROLE_EXISTS" ]; then
        # Create the custom role
        gcloud iam roles create $ROLE_NAME --project=$PROJECT_ID --file=$ROLE_FILE --quiet
        echo "Custom role $ROLE_NAME has been created in project $PROJECT_ID."
    else
        # Update the custom role
        gcloud iam roles update $ROLE_NAME --project=$PROJECT_ID --file=$ROLE_FILE --quiet
        echo "Custom role $ROLE_NAME has been updated in project $PROJECT_ID."
    fi
}

# Function to create a service account if it doesn't exist
create_service_account_if_not_exists() {
    local SA_NAME=$1
    local SA_EMAIL=$2
    local SA_EXISTS=$(gcloud iam service-accounts describe $SA_EMAIL 2>&1 | grep "email:")
    
    if [ -z "$SA_EXISTS" ]; then
        # Create the service account
        gcloud iam service-accounts create $SA_NAME --display-name $SA_NAME --project=$PROJECT_ID --quiet
        echo "Service account $SA_NAME has been created."
    fi
}

# Function to check if a service account exists
does_service_account_exist() {
    local SA_EMAIL=$1
    local SA_EXISTS=$(gcloud iam service-accounts describe $SA_EMAIL 2>&1 | grep "email:")
    [ ! -z "$SA_EXISTS" ] && return 0 || return 1
}

# Function to create and populate the secret if needed
create_and_populate_secret_if_needed() {
    local SECRET_NAME=$1
    local SA_NAME=$2
    local SA_EMAIL=$3

    # Create the secret
    gcloud secrets create $SECRET_NAME --replication-policy="automatic" --project=$PROJECT_ID --quiet
    echo "Secret $SECRET_NAME has been created."

    # Create a key for the service account and write it to a temporary file
    TMP_KEY_FILE=$(mktemp)
    gcloud iam service-accounts keys create $TMP_KEY_FILE --iam-account $SA_EMAIL --project=$PROJECT_ID
    echo "Key for service account $SA_EMAIL created and written to temporary file."

    # Add the key data to the secret
    gcloud secrets versions add $SECRET_NAME --data-file=$TMP_KEY_FILE --project=$PROJECT_ID
    echo "Key data from $SA_EMAIL added to the secret $SECRET_NAME."

    # Clean up by removing the temporary key file
    rm -f $TMP_KEY_FILE
}

# Create or update roles
create_or_update_role $DEPLOY_ROLE_NAME $DEPLOY_ROLE_FILE
create_or_update_role $PRIVILEGED_ROLE_NAME $PRIVILEGED_ROLE_FILE

# Create service accounts if they don't exist
create_service_account_if_not_exists $DEPLOY_SA_NAME $DEPLOY_SA_EMAIL
create_service_account_if_not_exists $PRIVILEGED_SA_NAME $PRIVILEGED_SA_EMAIL

# Grant the Service Account Token Creator role to the deploy service account so it can impersonate the privileged service account
gcloud iam service-accounts add-iam-policy-binding $PRIVILEGED_SA_EMAIL --member="serviceAccount:$DEPLOY_SA_EMAIL" --role="roles/iam.serviceAccountTokenCreator" --quiet
echo "Granted Service Account Token Creator role to $DEPLOY_SA_NAME for impersonating $PRIVILEGED_SA_NAME."

# Check if the DEPLOY service account exists
does_service_account_exist $DEPLOY_SA_EMAIL
if [ $? -eq 0 ]; then
    # Check if the secret exists
    SECRET_EXISTS=$(gcloud secrets describe $SECRET_NAME --project=$PROJECT_ID 2>&1 | grep "name:")
    if [ -z "$SECRET_EXISTS" ]; then
        # If service account exists but the secret does not, create and populate the secret
        create_and_populate_secret_if_needed $SECRET_NAME $DEPLOY_SA_NAME $DEPLOY_SA_EMAIL
    fi
fi

echo "Script execution completed."
