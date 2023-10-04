#!/bin/bash
set -ex

echo "Enter the path to the .env file to use (e.g. ./myenvfile.env):"
read ENV_FILE

# Source the .env file
source $ENV_FILE
echo "Loaded environment variables from $ENV_FILE"

# Set the emails for the service accounts
DEPLOY_SA_EMAIL="${DEPLOY_SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"
PRIVILEGED_SA_EMAIL="${PRIVILEGED_SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

# Check if service accounts exist and delete them if they do
echo "Checking and deleting service accounts..."
if gcloud iam service-accounts describe $DEPLOY_SA_EMAIL &>/dev/null; then
    gcloud iam service-accounts delete $DEPLOY_SA_EMAIL --quiet
    echo "Deleted service account: $DEPLOY_SA_EMAIL"
else
    echo "Service account $DEPLOY_SA_EMAIL does not exist."
fi

if gcloud iam service-accounts describe $PRIVILEGED_SA_EMAIL &>/dev/null; then
    gcloud iam service-accounts delete $PRIVILEGED_SA_EMAIL --quiet
    echo "Deleted service account: $PRIVILEGED_SA_EMAIL"
else
    echo "Service account $PRIVILEGED_SA_EMAIL does not exist."
fi

# Check for leftover bindings and unbind if needed
for ROLE in $DEPLOY_ROLE_NAME $PRIVILEGED_ROLE_NAME; do
    echo "Checking for bindings of $ROLE to service accounts..."
    echo "DEBUG: Current ROLE being checked: $ROLE"

    # Get bindings for the role
    BINDINGS=$(gcloud projects get-iam-policy $PROJECT_ID \
        --flatten="bindings[].members[]" \
        --filter="bindings.role:$ROLE AND (bindings.members:$DEPLOY_SA_EMAIL OR bindings.members:$PRIVILEGED_SA_EMAIL)" \
        --format="value(bindings.members)")
    
    echo "DEBUG: Retrieved bindings: $BINDINGS"

    # Unbind if the deleted service accounts are still bound to the role
    if [[ ! -z $BINDINGS ]]; then
        for MEMBER in $BINDINGS; do
            # Extract the actual email from the MEMBER
            ACTUAL_EMAIL=$(echo $MEMBER | awk -F'\\?uid=' '{print $1}' | sed 's/deleted:serviceAccount://')
            
            if ! gcloud projects remove-iam-policy-binding $PROJECT_ID \
                --role=$ROLE \
                --member=serviceAccount:$ACTUAL_EMAIL; then
                echo "Failed to remove binding of $ACTUAL_EMAIL to $ROLE."
            else
                echo "Successfully removed binding of $ACTUAL_EMAIL to $ROLE."
            fi
        done
    else
        echo "No leftover bindings found for $ROLE."
    fi

done

# Delete secret if it exists
echo "Deleting secret..."
if gcloud secrets describe $SECRET_NAME &>/dev/null; then
    gcloud secrets delete $SECRET_NAME --quiet
    echo "Deleted secret: $SECRET_NAME"
else
    echo "Secret $SECRET_NAME does not exist."
fi

echo "Cleanup completed!"
