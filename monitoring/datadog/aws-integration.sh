#!/bin/bash

echo "🔧 Setting up DataDog AWS Integration..."

# Create IAM role for DataDog
aws iam create-role \
  --role-name DatadogAWSIntegrationRole \
  --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "AWS": "arn:aws:iam::464622532012:root"
        },
        "Action": "sts:AssumeRole",
        "Condition": {
          "StringEquals": {
            "sts:ExternalId": "'${DD_EXTERNAL_ID}'"
          }
        }
      }
    ]
  }'

# Attach DataDog policy
aws iam attach-role-policy \
  --role-name DatadogAWSIntegrationRole \
  --policy-arn arn:aws:iam::aws:policy/DatadogAWSIntegrationPolicy

echo "✅ DataDog AWS Integration Role created"
echo "🔗 Add this role ARN to DataDog AWS Integration:"
aws iam get-role --role-name DatadogAWSIntegrationRole --query 'Role.Arn'