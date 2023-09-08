# GCP Service Account Creation Role Binding and Secret Generation for PoLP Impersonation

This script automates the setup of Google Cloud Platform (GCP) roles, service accounts, and a secret. It allows you to easily configure permissions and resources for deploying a particular cloud function and a privileged service account.

## Pre-requisites

- You must have the Google Cloud SDK (including gcloud CLI) installed and authenticated.
- Ensure you have the necessary permissions to create and manage IAM roles, service accounts, and secrets in the Google Cloud Project.
- A .env file containing all necessary environment variables.

## .env File

This script sources configurations from a .env file. This file contains key-value pairs that define various parameters such as the project ID, service account names, role names, and more.

Example .env file:

```# The ID of your Google Cloud Project
PROJECT_ID="your-gcp-project-id"

# The name of the custom role for deploying the Cloud Function
DEPLOY_ROLE_NAME="your-custom-role-for-deploying-cloud-function"

# The path to the JSON file defining the permissions for the deployment role
DEPLOY_ROLE_FILE="path-to-your-deployment-role-definition.json"

# The name of the custom role for privileged operations, like publishing messages
PRIVILEGED_ROLE_NAME="your-custom-role-for-privileged-operations"

# The path to the JSON file defining the permissions for the privileged role
PRIVILEGED_ROLE_FILE="path-to-your-privileged-role-definition.json"

# The name of the service account used to deploy the Cloud Function
DEPLOY_SA_NAME="your-deploy-service-account-name"

# The name of the privileged service account used for high-privileged operations
PRIVILEGED_SA_NAME="your-privileged-service-account-name"

# The name of the secret that holds the credentials for the deploy service account
SECRET_NAME="name-of-your-secret-for-deploy-service-account-credentials"
```

Note: Do not expose the .env file or commit it to public repositories to maintain the confidentiality of the information.

## Script Workflow

- Prompt for the path to the .env file.
- Read the .env file and set the configurations.
- Create or update custom roles based on provided role names and files.
- Create service accounts if they do not exist.
- Grant the Service Account Token Creator role to the deploy service account to allow impersonation.
- Bind the custom roles to the respective service accounts.
- Create a GCP secret if it doesn't exist.

### Important Next Step After Script Execution:

After running the script, a key from the created deploy service account needs to be added to the newly created secret. This step is essential to complete the configuration process.

You can achieve this using the gcloud CLI as follows:

```
gcloud secrets versions add $SECRET_NAME --data-file=<PATH_TO_SERVICE_ACCOUNT_KEY_JSON>
```

Make sure to replace `<PATH_TO_SERVICE_ACCOUNT_KEY_JSON>` with the correct path to your service account key JSON file.

## Running the Script

Ensure the script is executable:

```
chmod +x sa_role_create_bind.sh
```

Run the script:

```
./sa_role_create_bind.sh
```
