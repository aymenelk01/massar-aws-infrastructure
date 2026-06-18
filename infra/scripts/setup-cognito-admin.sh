#!/bin/bash

set -e
export AWS_PAGER=""


USER_POOL_ID=$COGNITO_USER_POOL_ID
REGION="eu-south-1"
GROUP_NAME="admins"
USERNAME="admin"
PASSWORD="Massar2024!" 

# 1. check if the user already exists by running the admin-get-user command and capturing its output and exit code
USER_OUTPUT=$(aws cognito-idp admin-get-user --user-pool-id "$USER_POOL_ID" --username "$USERNAME" 2>&1) || EXIT_CODE=$?

# 2. Process the results based on AWS CLI exit codes
if [ -z "$EXIT_CODE" ]; then
  # Exit code is empty/0, meaning the command succeeded perfectly. The user exists!
  echo "Admin user already exists. Skipping bootstrap creation."
  exit 0

elif [ "$EXIT_CODE" -eq 254 ] && [[ "$USER_OUTPUT" == *"UserNotFoundException"* ]]; then
  # Exit code 254 means an AWS service error occurred. We explicitly check if it's because the user doesn't exist.

echo "Admin user not found. Starting AWS Cognito user provisioning..."

aws cognito-idp admin-create-user \
  --user-pool-id "${USER_POOL_ID}" \
  --username "${USERNAME}" \
  --message-action SUPPRESS \
  --region "${REGION}" || echo "User ${USERNAME} already exists. Skipping user creation."

echo "Setting permanent password for user: ${USERNAME}..."
aws cognito-idp admin-set-user-password \
  --user-pool-id "${USER_POOL_ID}" \
  --username "${USERNAME}" \
  --password "${PASSWORD}" \
  --permanent \
  --region "${REGION}"

echo "Adding user ${USERNAME} to group ${GROUP_NAME}..."
aws cognito-idp admin-add-user-to-group \
  --user-pool-id "${USER_POOL_ID}" \
  --username "${USERNAME}" \
  --group-name "${GROUP_NAME}" \
  --region "${REGION}"

echo "AWS Cognito user provisioning completed successfully."

else
  echo "Error: Failed to check user status due to a critical AWS error:"
  echo "$USER_OUTPUT"
  exit 1 # <--- This kills the pipeline
fi