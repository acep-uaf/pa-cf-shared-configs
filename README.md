# GCP Service Account Creation Role Binding and Secret Generation for PoLP Impersonation

<br>

Welcome to the GCP Role Binding, Service Account Creation, and Secret Generation Toolkit for PoLP Impersonation. This collection of scripts is crafted to simplify the processes of creating, verifying, and managing roles, service accounts, and secrets on the Google Cloud Platform (GCP). Emphasizing streamlined operations and robust permission oversight, this toolkit assists in efficiently upholding the Principle of Least Privilege (PoLP) for a safer and well-ordered GCP setup.

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
DEPLOY_SA_NAME=<value>
DEPLOY_ROLE_NAME=<value>
DEPLOY_ROLE_FILE=<value>
SECRET_NAME=<value>

PRIVILEGED_SA_NAMES=("<value>" "<value>")
PRIVILEGED_ROLE_NAMES=("<value>, <value>" "<value>")
PRIVILEGED_ROLE_FILES=("<value>, <value>" "<value>")
```

Replace `<value>` with the appropriate values for your deployment.

### Explaining the Array Syntax

**Array Representation:**
  - Arrays are enclosed in parentheses `()` and each element is enclosed in double quotes `"`.

**Role Associations:**
  - Multiple roles associated with a single service account are represented as comma-separated values within the same double quotes `"`.

**Ordering:**
  - Ensure that the order of elements within `PRIVILEGED_SA_NAMES`, `PRIVILEGED_ROLE_NAMES`, and `PRIVILEGED_ROLE_FILES` are consistent. The ith service account will be associated with the ith set of roles defined using the ith set of JSON files.

### Environment Variable Descriptions

Below are descriptions for each environment variable used in the deployment script:

**PROJECT_ID**=`<value>`:
- Description: The ID of your Google Cloud Project.

**DEPLOY_SA_NAME**=`<value>`:
- Description: Name for the service account that will be associated with the custom deployment role.

**DEPLOY_ROLE_NAME**=`<value>`:
- Description: Specifies the name for the custom role related to deployments.

**DEPLOY_ROLE_FILE**=`<value>`:
- Description: Path to the JSON file that contains the definition for the custom deployment role.

**PRIVILEGED_SA_NAMES**=`("<value>" "<value>")`:
- Description: Array of privileged service account names..

**PRIVILEGED_ROLE_NAMES**=`("<value>, <value>" "<value>")`:
- Description: Array of comma-separated role names, corresponding to each privileged service account.

**PRIVILEGED_ROLE_FILES**=`("<value>, <value>" "<value>")`:
- Description: Array of paths to the JSON files containing the definitions for each set of privileged roles.

**SECRET_NAME**=`<value>`:
- Description: Specifies the name of the secret for storing service account keys.

Given the modular nature of cloud functions and various GCP resources, you might have multiple .env files, each tailored for distinct configurations. Remember to provide the appropriate .env file path when prompted by the scripts.

## Role Configuration Files

Roles in GCP are sets of permissions that can be granted to specific Google Cloud resources. The role.json files allow you to define custom roles with granular permissions tailored to your application's needs. Here are illustrative examples of role configurations:

### deploy-role.json:

```bash
{
    "title": "custom_role_pa_cf_ea_deploy",
    "description": "Role for deploying a Cloud Function dependent on eventarc for triggers.",
    "stage": "ALPHA",
    "includedPermissions": [
      "eventarc.events.receiveEvent",
      "run.routes.invoke"
    ]
}
```

### privileged-role.json:

```bash
{
    "title": "custom_role_bq_gcs_privileged",
    "description": "Role for BigQuery operations.",
    "stage": "ALPHA",
    "includedPermissions": [
      "bigquery.datasets.create",
      "bigquery.datasets.get",
      "bigquery.datasets.getIamPolicy",
      "bigquery.jobs.create",
      "storage.objects.get",
      "storage.objects.list"
    ]
 }
```

Make sure the role files are located in the same directory as the scripts, or adjust the paths in the `.env` file accordingly.

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

- **IAM Roles**: It either creates or updates custom IAM roles based on the provided JSON role definitions. Both deploy roles and privileged roles are managed.
- **Service Accounts**: Creates necessary service accounts if they don't already exist, including both deploy service accounts and privileged service accounts.
- **Role Bindings**:
  - **One-to-Many Relationship**: The script is designed to bind multiple roles to a single service account, allowing for the aggregation of necessary permissions.
  - The script binds the custom roles to the respective service accounts. Additionally, it grants the deploy service account permission to impersonate privileged service accounts.
- **Secrets**: A GCP secret is created or updated. If the secret does not exist, a new service account key is generated and added to the secret. This secret is used for permission elevation during impersonation.
- **Error Handling**: The script checks for the presence of necessary variables and files, ensuring proper authentication and availability of the .env file. Errors are gracefully reported to the user with informative messages.
- **Input**: The script prompts the user to enter the path to the `.env` file containing necessary environment variables.
- **Idempotency**: The script is designed to be idempotent, meaning it can be run multiple times without causing unintended side effects. If a role, service account, or secret already exists, the script ensures they are updated as needed without creating duplicates.


Usage:
```bash
./u_sa_role_create_bind.sh
```

### 3. u_verify_environment.sh
A diagnostic utility to validate your GCP environment:

- **Configuration Checks**: Compares the current GCP environment's IAM settings against the configurations specified in the .env file.
  - **gcloud Command**: Verifies if the `gcloud` command is available.
  - **Authentication**: Checks for valid gcloud authentication.
  - **.env File**: Prompts the user for the path to the `.env` file and validates its existence and readability.
  - **IAM Roles**: Checks for the existence of the necessary IAM roles for the deploy service account and privileged service accounts.
  - **Service Accounts**: Checks for the existence of the deploy and privileged service accounts.
  - **IAM Bindings**: Validates the IAM bindings for the deploy and privileged service accounts.
  - **Secrets**: Checks for the existence of specific secrets.
- **Feedback**: Provides feedback on discrepancies or confirms if everything is in order. Alerts if a required component like an IAM role or service account is missing or not correctly bound.


Usage:
```bash
./u_verify_environment.sh
```

### 4. u_clean_environment.sh
When a reset is needed, this script steps in to clean up:

- **Pre-checks**:
  - **gcloud Command**: Ensures the `gcloud` command is available and executable.
  - **Authentication**: Verifies if the user is authenticated to `gcloud`.
  - **.env File**: Prompts the user for the path to the `.env` file and ensures it exists and is readable.
  - **Required Variables**: Checks if all required variables are set in the `.env` file.

- **Unbinding Roles**: Removes the role bindings associated with the service accounts.
  - **Thorough Unbinding**: Iterates over each privileged service account and meticulously removes each role binding.
  - **Feedback**: Provides feedback on whether bindings were already unbound or don't exist.

- **Service Account Deletion**: Deletes the service accounts specified in the `.env` file.
  - **Existence Check**: Prior to deletion, checks if the service account exists.
  - **Feedback**: Informs if a service account was deleted or didn't exist.

- **Secret Removal**: Deletes the secrets created in the setup phase.
  - **Existence Check**: Confirms if the secret exists before attempting deletion.
  - **Feedback**: Informs if a secret was deleted or didn't exist.

- **Cleanup Completion**: Notifies upon successful completion of the cleanup process.


Usage:
```bash
./u_clean_environment.sh
```

## Troubleshooting

Encountering issues while deploying or using the toolkit? Below are some common problems and their solutions:

1. **Script Execution Failure**:
    - **Symptom**: You get a "Permission Denied" error when trying to run a script.
    - **Solution**: Ensure the script has execute permissions. Run `chmod +x <script_name>.sh` to grant execute permissions.

2. **Authentication Issues**:
    - **Symptom**: Errors related to insufficient permissions or unauthorized access.
    - **Solution**: Confirm you're authenticated to the correct GCP account, and you've set the desired project. Double-check the permissions associated with your authenticated account.

3. **Role/Service Account Creation Failure**:
    - **Symptom**: The script is unable to create a role or service account.
    - **Solution**: Ensure your authenticated GCP account has necessary permissions to create roles and service accounts. Verify the role or service account names in the `.env` file do not already exist.

4. **Secret Creation Issues**:
    - **Symptom**: Errors related to secret creation or update.
    - **Solution**: Double-check the `SECRET_NAME` variable in the `.env` file for any typos. Ensure you have permissions to create and manage secrets in GCP.

5. **Discrepancies in Verification**:
    - **Symptom**: The `u_verify_environment.sh` script indicates discrepancies between your environment and `.env` file configurations.
    - **Solution**: Double-check your `.env` file's configurations and ensure they align with your intended setup. Confirm you are authenticated to the correct project. Re-run the setup script if needed.

6. **Unable to Delete Resources with Cleanup Script**:
    - **Symptom**: The `u_clean_environment.sh` script is unable to delete certain resources.
    - **Solution**: Manually check if the resources (roles, service accounts, secrets) exist in your GCP environment. Ensure you have necessary permissions to delete the resources and confirm you are authenticated to the correct project.

Remember to check for typos, errors in file paths, or missing configurations in the `.env` file as they can be the root of many issues.


## FAQ (Frequently Asked Questions)

1. **What is the purpose of the `.env` file in this toolkit?**
    - The `.env` file acts as a configuration blueprint, containing key-value pairs that dictate various parameters for the scripts. It provides an easy way to set and modify configurations without altering the scripts themselves.

2. **Can I use this toolkit for multiple GCP projects simultaneously?**
    - Yes, you can. Create separate `.env` files for each project and specify the path to the appropriate file when prompted by the scripts.

3. **Is there a risk of overwriting existing IAM roles or service accounts?**
    - The toolkit is designed to either create or update roles and service accounts based on the configurations in the `.env` file. Always ensure the names specified in the `.env` file are unique to avoid overwriting existing resources.

4. **Why do I need to backup my IAM settings?**
    - Taking a backup provides a safety net. In case of any unexpected changes or errors during setup, you can revert to the previous IAM settings. It's a good practice, especially in production environments.

5. **How often should I run the `u_verify_environment.sh` script?**
    - Run it whenever you make changes to the IAM settings or after executing other scripts in the toolkit. It helps ensure your environment aligns with your intended configurations.

6. **What should I do if I accidentally deleted my backup IAM policy file?**
    - If the backup is lost and you haven't made changes yet, you can re-run the `u_backup_iam_policy.sh` script. If changes have been made, review them carefully and consider manually reverting undesired changes.

7. **Is this toolkit compatible with other cloud providers, like AWS or Azure?**
    - This toolkit is specifically designed for Google Cloud Platform (GCP). While some concepts might be similar, you'd need different toolkits or scripts for other cloud providers.

8. **Does this toolkit handle multi-region deployments?**
    - The toolkit is designed to work at the GCP project level. Multi-region considerations, like data residency, are based on individual GCP service configurations and are outside the scope of this toolkit.

9. **Do I incur any charges using this toolkit on GCP?**
    - While the toolkit itself is free, some operations, like creating secrets or service accounts, might have associated costs on GCP. Always check GCP's pricing documentation to understand potential charges.

10. **Can I bind (use) the same role with different `.env` files and service accounts?**
    - Yes, you can. Roles in GCP define a set of permissions, and these roles can be bound to multiple service accounts across different `.env` configurations. However, ensure that the `role.json` file defining the role remains consistent across your different configurations to maintain uniform permissions.

<br>

## Conclusion

---

GCP's IAM system is designed with granularity and flexibility in mind, and the scripts in this toolkit leverage these characteristics to ensure that permissions are finely-tuned, following the Principle of Least Privilege (PoLP). The scripts adhere to the principle of granting only the essential permissions necessary for deployment, ensuring a secure environment. Through the use of impersonation, they facilitate controlled permission elevation, allowing tasks to be performed without permanently granting elevated rights.

Moreover, the ability to save your project's IAM policy provides a safety net, ensuring that configurations can be reverted if required. The `u_verify_environment.sh` script provides the sanity check for cross-referencing your current configurations against desired states, helping you catch discrepancies before they turn problematic. Lastly, with `u_clean_environment.sh`, you have the convenience of effortlessly tearing down configurations, ensuring a clean slate when needed.

By integrating these scripts into your workflow, not only do you bolster your GCP environment's security, but you also streamline the management of roles, service accounts, and bindings. Ultimately, the toolkit epitomizes efficiency, security, and the ease of IAM management on Google Cloud Platform.

---
