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
declare -a required_vars=("PROJECT_ID" "DEPLOY_ROLE_NAME" "DEPLOY_ROLE_FILE" "PRIVILEGED_ROLE_NAMES" "PRIVILEGED_ROLE_FILES" "DEPLOY_SA_NAME" "PRIVILEGED_SA_NAMES" "SECRET_NAME")
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

declare -a PRIVILEGED_SA_EMAILS
for idx in "${!PRIVILEGED_SA_NAMES[@]}"; do
    PRIVILEGED_SA_EMAILS+=("${PRIVILEGED_SA_NAMES[$idx]}@${PROJECT_ID}.iam.gserviceaccount.com")
done

# Check for leftover bindings and unbind if needed
# Unbind role from service account
unbind_role_from_service_account() {
    local ROLE_NAME=$1
    local SA_EMAIL=$2
    local FULL_ROLE_NAME="projects/$PROJECT_ID/roles/$ROLE_NAME"
    
    gcloud projects remove-iam-policy-binding "$PROJECT_ID" --member="serviceAccount:$SA_EMAIL" --role="$FULL_ROLE_NAME" &> /dev/null
    if [ $? -eq 0 ]; then
        echo "Removed service account binding for $SA_EMAIL with role $ROLE_NAME."
    else
        echo "Attempted to remove service account binding for $SA_EMAIL with role $ROLE_NAME, but it was already unbound or doesn't exist."
    fi
}

echo "Checking and removing bindings from service accounts..."
unbind_role_from_service_account "$DEPLOY_ROLE_NAME" "$DEPLOY_SA_EMAIL"

# Loop over each privileged service account
for idx in "${!PRIVILEGED_SA_NAMES[@]}"; do
    SA_EMAIL="${PRIVILEGED_SA_NAMES[$idx]}@${PROJECT_ID}.iam.gserviceaccount.com"
    
    # Split the roles for this service account and unbind each one
    IFS=", " read -ra roles_for_sa <<< "${PRIVILEGED_ROLE_NAMES[$idx]}"
    for role in "${roles_for_sa[@]}"; do
        unbind_role_from_service_account "$role" "$SA_EMAIL"
    done
done

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
for PRIVILEGED_SA_EMAIL in "${PRIVILEGED_SA_EMAILS[@]}"; do
    delete_service_account "$PRIVILEGED_SA_EMAIL"
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

