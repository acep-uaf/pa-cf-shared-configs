# GCP Service Account Creation Role Binding and Secret Generation for PoLP Impersonation

<br>

Welcome to the GCP Service Account Creation Role Binding and Secret Generation for PoLP Impersonation
 toolkit – a suite of scripts designed for automating the creation, verification, and cleanup of roles, service accounts, and secrets on Google Cloud Platform (GCP). This toolkit epitomizes the principles of streamlined operations and effective permissions management, making it easier to implement the Principle of Least Privilege (PoLP) and maintain a secure and organized GCP environment.


## Overview

These scripts serve a pivotal role in ensuring efficient and consistent configurations across your GCP deployments:

1. **u_backup_iam_policy.sh**: This script safeguards your configurations by capturing and storing a snapshot of your current GCP project's IAM policy.

2. **u_sa_role_create_bind.sh**: This script provides the backbone for initial setup, automating the creation of custom IAM roles, service accounts, their respective bindings, and secrets.
  
3. **u_verify_environment.sh**: Think of this as a diagnostic tool; it cross-references the environment's configurations against the ones specified in your `.env` file to ensure everything's set up correctly.

4. **u_clean_environment.sh**: When you need to reset or tear down configurations, this script steps in to unbind roles, delete service accounts, and remove secrets.

Accompanying these scripts, the `.env` files act as the heart of configuration, containing the necessary directives that guide the scripts in their operations. In combination with the `role.json` files, they allow for a highly modular setup where specific roles with distinct permissions can be curated, providing a flexible, secure, and efficient IAM management system.

For a closer look at how each script functions and how you can maximize their potential, dive into the sections below.

## Pre-requisites

Before utilizing the scripts in this toolkit, please ensure the following:

1. **Google Cloud SDK**: You should have the Google Cloud SDK installed on your machine. This includes the `gcloud` command-line tool, which is used by the scripts to interact with GCP.

2. **Authenticated User**: Make sure you're authenticated to the right GCP account and have set the desired project. You can check your currently authenticated account with `gcloud auth list` and your current project with `gcloud config get-value project`.

3. **Permissions**: Your authenticated account must have sufficient permissions to create and manage IAM roles, service accounts, and secrets in the specified GCP project. 

4. **.env Files**: Prepare your `.env` files with the necessary configurations for the scripts. The scripts will prompt you for the path to these files when they run.

5. **role.json Files**: Ensure that the role definition files (`role.json`) are correctly set up in the specified paths in your `.env` files. These files define the custom roles the scripts will create.

6. **Backup**: Before making changes, especially on a production environment, it's a good practice to backup your current IAM settings. This can be done using the `u_backup_iam_policy.sh` script. It will capture and store a snapshot of your current GCP project's IAM policy.

7. **Safety First**: Always review any script, especially those that make changes to permissions and resources, before executing them. Understand each step it takes and confirm that its actions align with your desired configurations and best practices.

## Configuration: .env File & role.json Files

The efficiency and customizability of the toolkit largely hinge on the `.env` and `role.json` files, which provide the critical configurations guiding the scripts' operations.

### .env File

The `.env` files act as configuration blueprints, containing key-value pairs that dictate various parameters for the scripts. Here's an illustrative example of a `.env` file:

```bash
PROJECT_ID=<value>
DEPLOY_ROLE_NAME=<value>
DEPLOY_ROLE_FILE=<value>
PRIVILEGED_ROLE_NAME=<value>
PRIVILEGED_ROLE_FILE=<value>
DEPLOY_SA_NAME=<value>
PRIVILEGED_SA_NAME=<value>
SECRET_NAME=<value>
```

Replace <value> with the appropriate values for your deployment.

### Environment Variable Descriptions

Below are descriptions for each environment variable used in the deployment script:

**PROJECT_ID**=`<value>`:
- Description: The ID of your Google Cloud Project.

**DEPLOY_ROLE_NAME**=`<value>`:
- Description: Specifies the name for the custom role related to deployments.

**DEPLOY_ROLE_FILE**=`<value>`:
- Description: Path to the JSON file that contains the definition for the custom deployment role.

**PRIVILEGED_ROLE_NAME**=`<value>`:
- Description: Specifies the name for a more privileged custom role.

**PRIVILEGED_ROLE_FILE**=`<value>`:
- Description: Path to the JSON file that contains the definition for the privileged role.

**DEPLOY_SA_NAME**=`<value>`:
- Description: Name for the service account that will be associated with the custom deployment role.

**PRIVILEGED_SA_NAME**=`<value>`:
- Description: Name for the service account that will be associated with the more privileged custom role.

**SECRET_NAME**=`<value>`:
- Description: Specifies the name of the secret for storing service account keys.


## Script Details

### 1. u_backup_iam_policy.sh

Preserving your GCP IAM policy settings is crucial, and this script ensures you have a backup:

- **Backup Creation**: Captures the current IAM policy settings of your GCP project then and saves them in a local file.
- **Safety Net**: Before making significant changes, running this script provides a safety net, ensuring you can revert if needed.

Usage:
```bash
./u_backup_iam_policy.sh
```

### 2. u_sa_role_create_bind.sh

This script automates the foundational IAM setup:

- **IAM Roles**: It either creates or updates custom IAM roles based on the provided JSON role definitions.
- **Service Accounts**: Creates necessary service accounts if they don't already exist.
- **Role Bindings**: It binds the custom roles to the respective service accounts.
- **Secrets**: A GCP secret is created or updated then populated with the deploy service account key which is used for permission elevation for impersonation.

Usage:
```bash
./u_sa_role_create_bind.sh
```

### 3. u_verify_environment.sh
A diagnostic utility to validate your GCP environment:

- **Configuration Checks**: Compares the current GCP environment's IAM settings against the configurations specified in the .env file.
- **Feedback**: Provides feedback on discrepancies or confirms if everything is in order.

Usage:
```bash
./u_verify_environment.sh
```

### 4. u_clean_environment.sh
When a reset is needed, this script steps in to clean up:

- **Unbinding Roles**: Removes the role bindings associated with the service accounts.
- **Service Account Deletion**: Deletes the service accounts specified in the .env file.
- **Secret Removal**: Deletes the secrets created in the setup phase.

Usage:
```bash
./u_clean_environment.sh
```
