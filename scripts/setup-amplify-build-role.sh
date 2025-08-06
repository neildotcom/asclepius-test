#!/bin/bash

# Script to automatically:
# 1. Modify the existing Amplify service role to add CloudFormation permissions
# 2. Configure DynamoDB permissions for Cognito authenticated user role
#
# Usage: ./setup-amplify-build-role.sh [app_id] [app_name]
# - app_id: (Optional) Amplify app ID
# - app_name: (Optional) Amplify app name to search for (default: asclepius)
#
# Region and stage are automatically detected from the deployed CDK stack

set -e

POLICY_NAME="AsclepiusCloudFormationAccess"

echo "🔧 Setting up Amplify permissions..."

# Auto-detect region and stage from CDK stack
echo "📡 Auto-detecting region and stage from CDK stack..."

# Default region
REGION=${AWS_REGION:-us-east-1}

# Find Asclepius stack and get the stage from its outputs
STACK_NAME=$(aws cloudformation list-stacks \
    --region $REGION \
    --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE \
    --query 'StackSummaries[?starts_with(StackName, `Asclepius-`)].StackName' \
    --output text 2>/dev/null | head -1)

if [ $? -ne 0 ] || [ -z "$STACK_NAME" ]; then
    echo "❌ Could not find Asclepius stack in region $REGION"
    echo "   Make sure you have deployed the CDK stack first with: ./deploy.sh <stage>"
    echo "   And that you have the correct AWS credentials and region configured"
    exit 1
fi

# Get stage from CDK output
STAGE=$(aws cloudformation describe-stacks \
    --stack-name $STACK_NAME \
    --region $REGION \
    --query 'Stacks[0].Outputs[?OutputKey==`DeploymentStage`].OutputValue' \
    --output text 2>/dev/null)

if [ $? -ne 0 ] || [ -z "$STAGE" ] || [ "$STAGE" = "None" ]; then
    echo "⚠️  Could not get stage from stack outputs - falling back to parsing stack name"
    # Fallback: extract from stack name (Asclepius-{stage})
    STAGE=${STACK_NAME#Asclepius-}
fi

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

echo "✅ Auto-detected configuration:"
echo "   Region: $REGION"
echo "   Stage: $STAGE"
echo "   Stack: $STACK_NAME"
echo "   Account ID: $ACCOUNT_ID"
echo ""

###########################################
# PART 1: Find and update Amplify service role
###########################################

echo "🔍 Finding Amplify app and service role..."

# Check if app ID was provided as a parameter
if [ ! -z "$1" ]; then
    AMPLIFY_APP_ID=$1
    echo "✅ Using provided Amplify app ID: $AMPLIFY_APP_ID"
else
    # Try to find by name first (default to "asclepius" but this is just a guess)
    APP_NAME=${2:-"asclepius"}
    AMPLIFY_APP_ID=$(aws amplify list-apps --region $REGION --query "apps[?name=='$APP_NAME'].appId" --output text)
    
    # If not found by name, list all apps and let user choose
    if [ -z "$AMPLIFY_APP_ID" ] || [ "$AMPLIFY_APP_ID" == "None" ]; then
        echo "⚠️  No Amplify app found with name '$APP_NAME'"
        echo "📋 Available Amplify apps:"
        
        # Get all apps and their IDs
        APP_LIST=$(aws amplify list-apps --region $REGION --query "apps[].[appId, name]" --output text)
        
        if [ -z "$APP_LIST" ]; then
            echo "❌ No Amplify apps found in region $REGION"
            echo "   Please create an Amplify app first with 'amplify init'"
            echo "   Then run this script again with the app ID as the first parameter:"
            echo "   ./scripts/setup-amplify-build-role.sh YOUR_APP_ID"
            exit 1
        fi
        
        # Display apps with numbers
        echo "$APP_LIST" | nl -w2 -s') '
        
        # Prompt user to select an app
        echo ""
        echo "Please enter the number of the app to use, or press Ctrl+C to cancel:"
        read -p "> " APP_NUMBER
        
        # Validate input
        if ! [[ "$APP_NUMBER" =~ ^[0-9]+$ ]]; then
            echo "❌ Invalid input. Please enter a number."
            exit 1
        fi
        
        # Get the selected app ID
        AMPLIFY_APP_ID=$(echo "$APP_LIST" | sed -n "${APP_NUMBER}p" | awk '{print $1}')
        
        if [ -z "$AMPLIFY_APP_ID" ]; then
            echo "❌ Invalid selection. Please run the script again."
            exit 1
        fi
        
        echo "✅ Selected Amplify app ID: $AMPLIFY_APP_ID"
    else
        echo "✅ Found Amplify app with name '$APP_NAME': $AMPLIFY_APP_ID"
    fi
fi

# Get the current service role ARN for the app
SERVICE_ROLE_ARN=$(aws amplify get-app --app-id $AMPLIFY_APP_ID --region $REGION --query 'app.iamServiceRoleArn' --output text)

if [ -z "$SERVICE_ROLE_ARN" ] || [ "$SERVICE_ROLE_ARN" == "None" ]; then
    echo "⚠️  No service role found for Amplify app"
    echo "   Using default Amplify service role..."
    
    # Use the default Amplify service role
    # This is a special case where Amplify uses a service-managed role
    echo "⚠️  This app is using the default Amplify service role"
    echo "   We need to create a custom role with CloudFormation permissions"
    
    # Create a custom service role
    ROLE_NAME="amplify-service-role-$AMPLIFY_APP_ID"
    
    # Create trust policy document
    cat > /tmp/amplify-trust-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "amplify.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

    # Create the role with trust policy
    SERVICE_ROLE_ARN=$(aws iam create-role \
        --role-name $ROLE_NAME \
        --assume-role-policy-document file:///tmp/amplify-trust-policy.json \
        --query 'Role.Arn' \
        --output text)
    
    echo "✅ Created service role: $SERVICE_ROLE_ARN"
    
    # Attach the Amplify managed policy
    aws iam attach-role-policy \
        --role-name $ROLE_NAME \
        --policy-arn arn:aws:iam::aws:policy/AdministratorAccess-Amplify
    
    echo "✅ Attached AdministratorAccess-Amplify policy"
    
    # Update Amplify app to use the role
    aws amplify update-app \
        --app-id $AMPLIFY_APP_ID \
        --iam-service-role-arn $SERVICE_ROLE_ARN \
        --region $REGION
    
    echo "✅ Updated Amplify app to use the new service role"
else
    echo "✅ Found existing service role: $SERVICE_ROLE_ARN"
fi

# Extract role name from ARN
ROLE_NAME=$(echo $SERVICE_ROLE_ARN | awk -F/ '{print $NF}')
echo "   Role name: $ROLE_NAME"

# Create CloudFormation access policy
echo "🔨 Creating CloudFormation access policy..."

cat > /tmp/amplify-cf-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "cloudformation:DescribeStacks"
            ],
            "Resource": "arn:aws:cloudformation:*:*:stack/Asclepius-*/*"
        }
    ]
}
EOF

# Check if policy exists and update or create as needed
POLICY_EXISTS=$(aws iam list-role-policies --role-name $ROLE_NAME --query "PolicyNames[?contains(@,'$POLICY_NAME')]" --output text)

if [ -z "$POLICY_EXISTS" ]; then
    # Create inline policy
    aws iam put-role-policy \
        --role-name $ROLE_NAME \
        --policy-name $POLICY_NAME \
        --policy-document file:///tmp/amplify-cf-policy.json
    
    echo "✅ Created CloudFormation access policy"
else
    # Update existing policy
    aws iam put-role-policy \
        --role-name $ROLE_NAME \
        --policy-name $POLICY_NAME \
        --policy-document file:///tmp/amplify-cf-policy.json
    
    echo "✅ Updated CloudFormation access policy"
fi

###########################################
# PART 2: Set up Cognito DynamoDB permissions
###########################################

echo ""
echo "🔍 Setting up Cognito authenticated user role with DynamoDB permissions..."

# Find the Amplify authenticated user role
echo "🔍 Looking for Cognito authenticated user role..."

# List all roles and find the one that matches the Amplify auth pattern
AUTH_ROLES=$(aws iam list-roles --query "Roles[?contains(RoleName, 'amplify') && contains(RoleName, 'auth') && contains(RoleName, 'authenticated')].RoleName" --output text)

if [ -z "$AUTH_ROLES" ]; then
    echo "⚠️  No Amplify authenticated user roles found"
    echo "   You'll need to manually add DynamoDB permissions to the Cognito authenticated user role"
    echo "   See README.md Step 4 for instructions"
else
    # There might be multiple roles if multiple Amplify apps exist
    # We'll process each one that looks like it belongs to our app
    for AUTH_ROLE in $AUTH_ROLES; do
        echo "✅ Found authenticated user role: $AUTH_ROLE"
        
        # Create DynamoDB access policy
        echo "🔨 Creating DynamoDB access policy for $AUTH_ROLE..."
        
        DYNAMO_POLICY_NAME="AsclepiusDynamoDBAccess"
        
        cat > /tmp/dynamo-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "dynamodb:PutItem",
                "dynamodb:GetItem",
                "dynamodb:UpdateItem",
                "dynamodb:DeleteItem",
                "dynamodb:Query",
                "dynamodb:Scan"
            ],
            "Resource": [
                "arn:aws:dynamodb:$REGION:$ACCOUNT_ID:table/asclepius-patient-$STAGE",
                "arn:aws:dynamodb:$REGION:$ACCOUNT_ID:table/asclepius-visit-$STAGE",
                "arn:aws:dynamodb:$REGION:$ACCOUNT_ID:table/asclepius-transcript-$STAGE",
                "arn:aws:dynamodb:$REGION:$ACCOUNT_ID:table/asclepius-visit-data-$STAGE",
                "arn:aws:dynamodb:$REGION:$ACCOUNT_ID:table/asclepius-patient-$STAGE/index/*",
                "arn:aws:dynamodb:$REGION:$ACCOUNT_ID:table/asclepius-visit-$STAGE/index/*",
                "arn:aws:dynamodb:$REGION:$ACCOUNT_ID:table/asclepius-transcript-$STAGE/index/*",
                "arn:aws:dynamodb:$REGION:$ACCOUNT_ID:table/asclepius-visit-data-$STAGE/index/*"
            ]
        }
    ]
}
EOF

        # Check if policy already exists for this role
        EXISTING_POLICY=$(aws iam list-role-policies --role-name $AUTH_ROLE --query "PolicyNames[?contains(@,'$DYNAMO_POLICY_NAME')]" --output text)
        
        if [ -z "$EXISTING_POLICY" ]; then
            # Create inline policy
            aws iam put-role-policy \
                --role-name $AUTH_ROLE \
                --policy-name $DYNAMO_POLICY_NAME \
                --policy-document file:///tmp/dynamo-policy.json
            
            echo "✅ Created DynamoDB access policy for $AUTH_ROLE"
        else
            # Update existing policy
            aws iam put-role-policy \
                --role-name $AUTH_ROLE \
                --policy-name $DYNAMO_POLICY_NAME \
                --policy-document file:///tmp/dynamo-policy.json
            
            echo "✅ Updated DynamoDB access policy for $AUTH_ROLE"
        fi
    done
fi

echo ""
echo "🎉 Setup complete!"
echo ""
echo "✅ Amplify service role updated with CloudFormation access"
if [ ! -z "$AUTH_ROLES" ]; then
    echo "✅ Cognito authenticated user role(s) configured with DynamoDB access"
fi
echo ""
echo "🚀 Next steps:"
echo "   1. Go to the Amplify Console and trigger a new build:"
echo "      - Select your app"
echo "      - Go to 'Hosting environments'"
echo "      - Click 'Redeploy this version'"
echo "   2. Or push a small change to your repository to trigger a new build"
echo "   3. The build will now have access to CloudFormation stack outputs"
echo "   4. Environment variables will be automatically configured during build"
echo "   5. Authenticated users will have access to DynamoDB tables"

# Clean up temporary files
rm -f /tmp/amplify-trust-policy.json /tmp/amplify-cf-policy.json /tmp/dynamo-policy.json
