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

if gcloud iam service-accounts list --project=$PROJECT_ID | grep -q $DEPLOY_SA_EMAIL; then
    gcloud iam service-accounts delete $DEPLOY_SA_EMAIL --quiet
    echo "Deleted service account: $DEPLOY_SA_EMAIL"
else
    echo "Service account $DEPLOY_SA_EMAIL does not exist."
fi

if gcloud iam service-accounts list --project=$PROJECT_ID | grep -q $PRIVILEGED_SA_EMAIL; then
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
    BINDINGS_JSON=$(gcloud projects get-iam-policy $PROJECT_ID --format=json)
    EMAIL_BINDINGS=$(echo "$BINDINGS_JSON" | jq -r --arg ROLE "$ROLE" --arg EMAIL1 "$DEPLOY_SA_EMAIL" --arg EMAIL2 "$PRIVILEGED_SA_EMAIL" '.bindings[] | select(.role == $ROLE and (.members[] == ("deleted:serviceAccount:" + $EMAIL1 + "?uid=" + .members[] | split("?uid=")[1] ) or (.members[] == ("deleted:serviceAccount:" + $EMAIL2 + "?uid=" + .members[] | split("?uid=")[1])) ) | .members[] | split("?uid=")[0] | ltrimstr("deleted:serviceAccount:")')

    for EMAIL in $EMAIL_BINDINGS; do
        if ! gcloud projects remove-iam-policy-binding $PROJECT_ID --role=$ROLE --member=serviceAccount:$EMAIL; then
            echo "Failed to remove binding of $EMAIL to $ROLE."
        else
            echo "Successfully removed binding of $EMAIL to $ROLE."
        fi
    done
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