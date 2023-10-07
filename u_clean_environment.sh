#!/bin/bash
set -e

echo "Enter the path to the .env file to use (e.g. ./myenvfile.env):"
read ENV_FILE

# Source the .env file
source $ENV_FILE
echo "Loaded environment variables from $ENV_FILE"

# Set the emails for the service accounts
DEPLOY_SA_EMAIL="${DEPLOY_SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"
PRIVILEGED_SA_EMAIL="${PRIVILEGED_SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

# Check for leftover bindings and unbind if needed *IMPORTANT NOTE: unbinding the roles prior to 
# service account deletion insures the roles are not left bound to a service account in a deleted state.
 of the service 
#account *
unbind_role_from_service_account() {
    local ROLE_NAME=$1
    local SA_EMAIL=$2
    local FULL_ROLE_NAME="projects/$PROJECT_ID/roles/$ROLE_NAME"
    local BINDING_EXISTS=$(gcloud projects get-iam-policy "$PROJECT_ID" --flatten="bindings[].members" --format='table(bindings.role,bindings.members)' | grep "$SA_EMAIL" | grep "$FULL_ROLE_NAME")
    
    if echo "$BINDING_EXISTS" | grep -q "$SA_EMAIL"; then
        gcloud projects remove-iam-policy-binding "$PROJECT_ID" --member="serviceAccount:$SA_EMAIL" --role="$FULL_ROLE_NAME"
        echo "Removed service account binding for $SA_EMAIL."
    fi
}

echo "Checking and removing bindings from service accounts..."
unbind_role_from_service_account "$DEPLOY_ROLE_NAME" "$DEPLOY_SA_EMAIL"
unbind_role_from_service_account "$PRIVILEGED_ROLE_NAME" "$PRIVILEGED_SA_EMAIL"

# Check if service accounts exist and delete them if they do
delete_service_account() {
    local SA_EMAIL=$1

    if gcloud iam service-accounts list --project=$PROJECT_ID | grep -q $SA_EMAIL; then
        gcloud iam service-accounts delete $SA_EMAIL --quiet
        echo "Deleted service account: $SA_EMAIL"
    else
        echo "Service account $SA_EMAIL does not exist."
    fi
}

echo "Deleting service accounts..."
delete_service_account "$DEPLOY_SA_EMAIL"
delete_service_account "$PRIVILEGED_SA_EMAIL"

# Delete secret if it exists
echo "Deleting secret..."
if gcloud secrets describe $SECRET_NAME &>/dev/null; then
    gcloud secrets delete $SECRET_NAME --quiet
    echo "Deleted secret: $SECRET_NAME"
else
    echo "Secret $SECRET_NAME does not exist."
fi

echo "Cleanup completed!"
