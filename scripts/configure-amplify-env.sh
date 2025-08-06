#!/bin/bash

# Configure Amplify Environment Variables from CDK Stack Outputs
set -e

STAGE=${1:-dev}
REGION=${2:-us-east-1}

echo "🔧 Configuring Amplify environment variables from CDK stack..."
echo "   Stage: $STAGE"
echo "   Region: $REGION"
echo ""

# Get CDK stack outputs
echo "📡 Retrieving configuration from CDK stack..."
STACK_OUTPUTS=$(aws cloudformation describe-stacks \
    --stack-name Asclepius-$STAGE \
    --region $REGION \
    --query 'Stacks[0].Outputs' \
    --output json 2>/dev/null)

if [ $? -ne 0 ] || [ "$STACK_OUTPUTS" = "null" ]; then
    echo "❌ Failed to retrieve CDK stack outputs"
    echo "   Make sure the CDK stack 'Asclepius-$STAGE' is deployed in region '$REGION'"
    exit 1
fi

# Extract values from CDK outputs
WEBSOCKET_ENDPOINT=$(echo "$STACK_OUTPUTS" | jq -r '.[] | select(.OutputKey=="WebSocketEndpoint") | .OutputValue // empty')
VISIT_DATA_TABLE=$(echo "$STACK_OUTPUTS" | jq -r '.[] | select(.OutputKey=="VisitDataTableName") | .OutputValue // empty')
PATIENT_TABLE=$(echo "$STACK_OUTPUTS" | jq -r '.[] | select(.OutputKey=="PatientTableName") | .OutputValue // empty')
VISIT_TABLE=$(echo "$STACK_OUTPUTS" | jq -r '.[] | select(.OutputKey=="VisitTableName") | .OutputValue // empty')
TRANSCRIPT_TABLE=$(echo "$STACK_OUTPUTS" | jq -r '.[] | select(.OutputKey=="TranscriptTableName") | .OutputValue // empty')

echo "✅ Retrieved CDK outputs:"
echo "   WebSocket: $WEBSOCKET_ENDPOINT"
echo "   Patient Table: $PATIENT_TABLE"
echo "   Visit Table: $VISIT_TABLE"
echo "   Transcript Table: $TRANSCRIPT_TABLE"
echo ""

# Try to find Amplify App ID for AWS CLI approach
echo "🔍 Attempting to configure via AWS CLI..."
AMPLIFY_APP_ID=$(aws amplify list-apps --query 'apps[?name==`asclepius`].appId' --output text 2>/dev/null)

if [ ! -z "$AMPLIFY_APP_ID" ] && [ "$AMPLIFY_APP_ID" != "None" ]; then
    echo "✅ Found Amplify App ID: $AMPLIFY_APP_ID"
    echo "🔧 Setting environment variables via AWS CLI..."
    
    if aws amplify update-app \
        --app-id "$AMPLIFY_APP_ID" \
        --environment-variables \
            REACT_APP_AWS_REGION="$REGION" \
            REACT_APP_STAGE="$STAGE" \
            REACT_APP_WEBSOCKET_ENDPOINT="$WEBSOCKET_ENDPOINT" \
            REACT_APP_PATIENT_TABLE="$PATIENT_TABLE" \
            REACT_APP_VISIT_TABLE="$VISIT_TABLE" \
            REACT_APP_TRANSCRIPT_TABLE="$TRANSCRIPT_TABLE" \
            REACT_APP_VISIT_DATA_TABLE="$VISIT_DATA_TABLE" \
        --region "$REGION" >/dev/null 2>&1; then
        
        echo "✅ Environment variables configured successfully via AWS CLI!"
        echo ""
        echo "🚀 Next steps:"
        echo "1. Go to Amplify Console → Your App → Hosting"
        echo "2. Click 'Redeploy this version' to apply the new environment variables"
        echo "3. Your frontend will now have access to the correct table names"
        exit 0
    else
        echo "⚠️  AWS CLI approach failed, falling back to manual instructions..."
    fi
else
    echo "⚠️  Could not find Amplify app or AWS CLI approach not available"
fi

echo ""
echo "📋 Manual Configuration Required:"
echo "Please configure environment variables manually in the Amplify Console:"
echo ""
echo "1. Go to AWS Amplify Console: https://console.aws.amazon.com/amplify/"
echo "2. Select your app"
echo "3. Go to 'App settings' → 'Environment variables'"
echo "4. Add these environment variables:"
echo ""
echo "   REACT_APP_AWS_REGION = $REGION"
echo "   REACT_APP_STAGE = $STAGE"
echo "   REACT_APP_WEBSOCKET_ENDPOINT = $WEBSOCKET_ENDPOINT"
echo "   REACT_APP_PATIENT_TABLE = $PATIENT_TABLE"
echo "   REACT_APP_VISIT_TABLE = $VISIT_TABLE"
echo "   REACT_APP_TRANSCRIPT_TABLE = $TRANSCRIPT_TABLE"
echo "   REACT_APP_VISIT_DATA_TABLE = $VISIT_DATA_TABLE"
echo ""
echo "5. Save and go to 'Hosting' → 'Redeploy this version'"
echo ""
echo "📋 Environment variables to copy:"
echo "REACT_APP_AWS_REGION=$REGION"
echo "REACT_APP_STAGE=$STAGE"
echo "REACT_APP_WEBSOCKET_ENDPOINT=$WEBSOCKET_ENDPOINT"
echo "REACT_APP_PATIENT_TABLE=$PATIENT_TABLE"
echo "REACT_APP_VISIT_TABLE=$VISIT_TABLE"
echo "REACT_APP_TRANSCRIPT_TABLE=$TRANSCRIPT_TABLE"
echo "REACT_APP_VISIT_DATA_TABLE=$VISIT_DATA_TABLE"
