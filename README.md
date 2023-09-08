# GCP Service Account Creation Role Binding and Secret Generation for PoLP Impersonation

This script automates the setup of Google Cloud Platform (GCP) roles, service accounts, and a secret. It allows you to easily configure permissions and resources for deploying a particular cloud function and a privileged service account.

## Pre-requisites

- You must have the Google Cloud SDK (including gcloud CLI) installed and authenticated.
- Ensure you have the necessary permissions to create and manage IAM roles, service accounts, and secrets in the Google Cloud Project.
- A .env file containing all necessary environment variables.

## Role Configuration Files

For the Google Cloud Platform, roles can be custom-tailored to provide specific permissions tailored to your application's needs. These roles are defined in JSON format, as shown in the examples below:

### deploy.json

```
{
  "title": "your_custom_deploy",
  "description": "Base role for deploying a Cloud Function.",
  "stage": "ALPHA",
  "includedPermissions": [
    "cloudfunctions.functions.create",
    "cloudfunctions.functions.update",
    "cloudfunctions.functions.get",
    "cloudfunctions.functions.list",
    "cloudfunctions.operations.get",
    "cloudfunctions.operations.list",
    "run.routes.invoke"
  ]
}
```

### privilege.json

```
{
    "title": "your_custom_role_privileged",
    "description": "Privileged role for a Cloud Function to publish to Pub/Sub, read from GCS, and other tasks.",
    "stage": "ALPHA",
    "includedPermissions": [
      "pubsub.topics.publish",
      "storage.objects.get"
    ]
} 
```

## Storing and Using Role Configurations

1. **Location:** Store these JSON files in the root directory alongside the `.sh` script. This makes them easily accessible by the script and simplifies management.

1. **Sharing Roles:** A unique feature of roles in GCP is that they can be reused across multiple service accounts. For instance, two different cloud functions might have different service accounts, but both could require the same set of permissions for deployment. In such a case, the same `deploy.json` role configuration can be attached to both service accounts. This reduces redundancy and makes permission management more modular.

### Best Practice:
Always ensure that these role configuration files are tracked in version control to maintain a history of changes. However, be cautious not to include any sensitive data in them. This will allow for clear versioning and auditing of permissions granted to various parts of your application over time.

## .env File Configuration

This script sources configurations from a `.env` file. This file contains key-value pairs that define various parameters such as the project ID, service account names, role names, and more.

Given the modular nature of cloud functions, it's likely you'll have different configurations for different cloud functions. As such, you may end up with several `.env` files, each tailored for a specific function, e.g., `cloudfunction_a.env`, `cloudfunction_b.env`, and so on.

### Best Practice:

To keep things organized, it's a good idea to have a dedicated directory, such as `env`, to hold all your `.env` files. This not only helps in easy management but also prevents accidental exposure or overwrites of critical configuration data.

When running the script, you'd specify the path to the particular `.env` file you want to use, ensuring that the correct configurations are applied for each cloud function deployment.

Example `.env` file:

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

**Note:** Do not expose the .env file or commit it to public repositories to maintain the confidentiality of the information.  Always ensure that this directory is included in your `.gitignore` or equivalent to prevent accidental commits to version control.

## Script Workflow

1. Prompt for the path to the .env file.
1. Read the .env file and set the configurations.
1. Create or update custom roles based on provided role names and files.
1. Create service accounts if they do not exist.
1. Grant the Service Account Token Creator role to the deploy service account to allow impersonation.
1. Bind the custom roles to the respective service accounts.
1. Create a GCP secret if it doesn't exist.

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

Follow the on-screen prompts to provide the path to your .env file.

**Important:** Always review any script, especially those that make changes to IAM permissions and resources, before executing it. Ensure you understand each step it takes and that the script's actions are in line with your organization's best practices and guidelines.

## Integrating Service Accounts and Secrets in a Cloud Function Deployment

Once you've set up your roles, service accounts, and secrets using the initial script, you might want to integrate these into the deployment of a Google Cloud Function. This ensures that the cloud function operates with the correct permissions and accesses secrets securely.

## The deploy.sh Script

In the given deploy.sh example, a Cloud Function named pa-cf-gcs-event is deployed. The script specifies various configurations for this deployment. Here's how to integrate the previously generated resources:

### Service Account:

The `--service-account` flag is set to the email address of the deploy service account. This service account is used to deploy and manage the cloud function.

### Environment Variables:

The `--set-env-vars flag` sets environment variables for the Cloud Function's runtime. These are essential configuration values that the function might need to operate:

- `PROJECT_ID`: The GCP project's ID.
- `TOPIC_NAME`: Name of a Pub/Sub topic.
- `IMPERSONATE_SA`: The email address of the privileged service account. The deployed function can use this to impersonate and execute high-privileged operations.
- `TARGET_SCOPES`: The scopes the impersonation should cover.
- `SA_CREDENTIALS_SECRET_NAME`: The name of the secret that holds the credentials for the deploy service account.

## Steps to Integrate:

1. Adjust the `deploy.sh` Script:
Ensure that the values in your `deploy.sh` script (like service account emails and environment variables) match those you've set in your `.env` file and those created by the initial setup script.

1. Run the `deploy.sh` Script:
Once you've adjusted the script, run it to deploy the Cloud Function with the correct configurations:

```
chmod +x deploy.sh
./deploy.sh
```

1. Ensure the Cloud Function Has the Correct Permissions:
The Cloud Function will operate using the deploy service account. Ensure that this service account has the necessary permissions for any GCP resources the function interacts with.

1. Accessing Secrets in Your Cloud Function:
In your Cloud Function code, you'll likely want to access the secret (credentials). Use the Google Secret Manager API to fetch the secret using the secret's name. Ensure the deploy service account has the correct permissions to access the secret (as set up by the initial script).

**Note:** Always test your Cloud Function in a safe environment (like a staging or development project) before deploying it to a production environment. This ensures that it operates correctly, securely, and doesn't inadvertently modify or delete critical data.
