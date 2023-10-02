#!/bin/bash
set -e

# Prompt for the .env file to use
echo "Enter the path to the .env file to use (e.g. ./myenvfile.env):"
read ENV_FILE

# Source the .env file
source $ENV_FILE
echo "Loaded environment variables from $ENV_FILE"

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
        gcloud iam roles create $ROLE_NAME --project=$PROJECT_ID --file=$ROLE_FILE
        echo "Custom role $ROLE_NAME has been created in project $PROJECT_ID."
    else
        # Update the custom role
        gcloud iam roles update $ROLE_NAME --project=$PROJECT_ID --file=$ROLE_FILE
        echo "Custom role $ROLE_NAME has been updated in project $PROJECT_ID."
    fi
}

echo "Creating or updating IAM roles..."
create_or_update_role $DEPLOY_ROLE_NAME $DEPLOY_ROLE_FILE
create_or_update_role $PRIVILEGED_ROLE_NAME $PRIVILEGED_ROLE_FILE

# Function to create a service account if it doesn't exist
create_service_account_if_not_exists() {
    local SA_NAME=$1
    local SA_EMAIL=$2
    local SA_EXISTS=$(gcloud iam service-accounts describe $SA_EMAIL 2>&1 | grep "email:")
    
    if [ -z "$SA_EXISTS" ]; then
        # Create the service account
        gcloud iam service-accounts create $SA_NAME --display-name $SA_NAME --project=$PROJECT_ID
        echo "Service account $SA_NAME has been created."
    fi
}

echo "Checking and creating service accounts if they don't exist..."
create_service_account_if_not_exists $DEPLOY_SA_NAME $DEPLOY_SA_EMAIL
create_service_account_if_not_exists $PRIVILEGED_SA_NAME $PRIVILEGED_SA_EMAIL

# Grant the Service Account Token Creator role to the deploy service account so it can impersonate the privileged service account
gcloud iam service-accounts add-iam-policy-binding $PRIVILEGED_SA_EMAIL --member="serviceAccount:$DEPLOY_SA_EMAIL" --role="roles/iam.serviceAccountTokenCreator"
echo "Granted Service Account Token Creator role to $DEPLOY_SA_NAME for impersonating $PRIVILEGED_SA_NAME."

# Function to bind a role to a service account
bind_role_to_service_account() {
    local ROLE_NAME=$1
    local SA_EMAIL=$2
    local ROLE_BOUND=$(gcloud projects get-iam-policy $PROJECT_ID --flatten="bindings[].members" --format='table(bindings.role,bindings.members)' | grep $SA_EMAIL | grep $ROLE_NAME)
    
    if [ -z "$ROLE_BOUND" ]; then
        # Bind the role to the service account
        gcloud projects add-iam-policy-binding $PROJECT_ID --member="serviceAccount:$SA_EMAIL" --role="projects/$PROJECT_ID/roles/$ROLE_NAME"
        echo "Custom role $ROLE_NAME has been bound to service account $SA_EMAIL."
    fi
}

echo "Binding IAM roles to service accounts..."
bind_role_to_service_account $DEPLOY_ROLE_NAME $DEPLOY_SA_EMAIL
bind_role_to_service_account $PRIVILEGED_ROLE_NAME $PRIVILEGED_SA_EMAIL

# Create the secret if it doesn't exist
SECRET_EXISTS=$(gcloud secrets describe $SECRET_NAME --project=$PROJECT_ID 2>&1 | grep "name:")

echo "Checking and creating secret if it doesn't exist..."
if [ -z "$SECRET_EXISTS" ]; then
    # Create the secret (note: actual key data needs to be added in a separate command, e.g., through gcloud secrets versions add)
    gcloud secrets create $SECRET_NAME --replication-policy="automatic" --project=$PROJECT_ID
    echo "Secret $SECRET_NAME has been created."
fi

# Grant access to the secret for the deploy service account
echo "Granting access to the secret for the deploy service account..."
gcloud secrets add-iam-policy-binding $SECRET_NAME --project=$PROJECT_ID --role roles/secretmanager.secretAccessor --member serviceAccount:$DEPLOY_SA_EMAIL
echo "Granted secretAccessor role for secret $SECRET_NAME to $DEPLOY_SA_NAME." 
