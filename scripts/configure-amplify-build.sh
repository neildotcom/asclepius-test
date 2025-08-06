#!/bin/bash

# Configure environment variables during Amplify build process
# This script runs during the Amplify build phase to automatically
# fetch CDK outputs and create environment variables for the build

# Don't exit on error - we want to handle errors gracefully
set +e

echo "🔧 Configuring environment variables from CDK stack outputs..."

# Default region
REGION=${AWS_REGION:-us-east-1}

echo "   Region: $REGION"

# First, try to detect the stage by finding the Asclepius stack and querying its stage output
echo "📡 Detecting deployment stage from CDK stack outputs..."

# Find Asclepius stack and get the stage from its outputs
STACK_NAME=$(aws cloudformation list-stacks \
    --region $REGION \
    --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE \
    --query 'StackSummaries[?starts_with(StackName, `Asclepius-`)].StackName' \
    --output text 2>/dev/null | head -1)

if [ $? -ne 0 ] || [ -z "$STACK_NAME" ]; then
    echo "⚠️  Could not find Asclepius stack - insufficient permissions or stack doesn't exist"
    echo "   Falling back to default stage: dev"
    STAGE="dev"
else
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
    
    echo "✅ Detected stage: $STAGE from stack: $STACK_NAME"
fi

echo "   Stage: $STAGE"
echo ""

# Check for fallback config file
FALLBACK_CONFIG="./amplify-env-config.json"
USE_FALLBACK=false

# Get all outputs from CDK stack
echo "📡 Attempting to retrieve configuration from CDK stack..."
STACK_OUTPUTS=$(aws cloudformation describe-stacks \
    --stack-name Asclepius-$STAGE \
    --region $REGION \
    --query 'Stacks[0].Outputs' \
    --output json 2>/dev/null)

if [ $? -ne 0 ] || [ -z "$STACK_OUTPUTS" ] || [ "$STACK_OUTPUTS" = "null" ]; then
    echo "⚠️  Could not retrieve stack outputs - insufficient permissions or stack doesn't exist"
    echo "   Checking for fallback configuration..."
    USE_FALLBACK=true
fi

# If we couldn't get stack outputs and fallback exists, use it
if [ "$USE_FALLBACK" = true ] && [ -f "$FALLBACK_CONFIG" ]; then
    echo "📄 Using fallback configuration from $FALLBACK_CONFIG"
    
    # Extract values from fallback config
    WEBSOCKET_ENDPOINT=$(cat $FALLBACK_CONFIG | jq -r '.REACT_APP_WEBSOCKET_ENDPOINT')
    VISIT_DATA_TABLE=$(cat $FALLBACK_CONFIG | jq -r '.REACT_APP_VISIT_DATA_TABLE')
    PATIENT_TABLE=$(cat $FALLBACK_CONFIG | jq -r '.REACT_APP_PATIENT_TABLE')
    VISIT_TABLE=$(cat $FALLBACK_CONFIG | jq -r '.REACT_APP_VISIT_TABLE')
    TRANSCRIPT_TABLE=$(cat $FALLBACK_CONFIG | jq -r '.REACT_APP_TRANSCRIPT_TABLE')
    
    echo "✅ Using fallback configuration values"
elif [ "$USE_FALLBACK" = true ]; then
    echo "⚠️  No fallback configuration found - using placeholder values"
    echo "   NOTE: The application will not function correctly with these values!"
    echo "   After first deployment, run: ./scripts/setup-amplify-build-role.sh"
    
    # Use placeholder values to allow build to continue
    WEBSOCKET_ENDPOINT="wss://placeholder-endpoint.example.com"
    VISIT_DATA_TABLE="asclepius-visit-data-$STAGE"
    PATIENT_TABLE="asclepius-patient-$STAGE"
    VISIT_TABLE="asclepius-visit-$STAGE"
    TRANSCRIPT_TABLE="asclepius-transcript-$STAGE"
else
    # Extract individual values from stack outputs
    WEBSOCKET_ENDPOINT=$(echo $STACK_OUTPUTS | jq -r '.[] | select(.OutputKey=="WebSocketEndpoint") | .OutputValue')
    VISIT_DATA_TABLE=$(echo $STACK_OUTPUTS | jq -r '.[] | select(.OutputKey=="VisitDataTableName") | .OutputValue')
    PATIENT_TABLE=$(echo $STACK_OUTPUTS | jq -r '.[] | select(.OutputKey=="PatientTableName") | .OutputValue')
    VISIT_TABLE=$(echo $STACK_OUTPUTS | jq -r '.[] | select(.OutputKey=="VisitTableName") | .OutputValue')
    TRANSCRIPT_TABLE=$(echo $STACK_OUTPUTS | jq -r '.[] | select(.OutputKey=="TranscriptTableName") | .OutputValue')

    # Validate required outputs
    if [ "$WEBSOCKET_ENDPOINT" = "null" ] || [ -z "$WEBSOCKET_ENDPOINT" ]; then
        echo "⚠️  WebSocket endpoint not found in stack outputs - using placeholder"
        WEBSOCKET_ENDPOINT="wss://placeholder-endpoint.example.com"
    fi
    
    # Save current values to fallback config for future use
    echo "📝 Saving configuration to fallback file for future builds..."
    cat > $FALLBACK_CONFIG << EOF
{
    "REACT_APP_WEBSOCKET_ENDPOINT": "$WEBSOCKET_ENDPOINT",
    "REACT_APP_AWS_REGION": "$REGION",
    "REACT_APP_STAGE": "$STAGE",
    "REACT_APP_VISIT_DATA_TABLE": "$VISIT_DATA_TABLE",
    "REACT_APP_PATIENT_TABLE": "$PATIENT_TABLE",
    "REACT_APP_VISIT_TABLE": "$VISIT_TABLE",
    "REACT_APP_TRANSCRIPT_TABLE": "$TRANSCRIPT_TABLE"
}
EOF
fi

echo "✅ Configuration values:"
echo "   WebSocket Endpoint: $WEBSOCKET_ENDPOINT"
echo "   Visit Data Table: $VISIT_DATA_TABLE"
echo "   Patient Table: $PATIENT_TABLE"
echo "   Visit Table: $VISIT_TABLE"
echo "   Transcript Table: $TRANSCRIPT_TABLE"

# Create .env file for the build
echo "📝 Creating .env file with deployment values..."

cat > .env << EOF
# Asclepius Environment Configuration - Auto-generated for Amplify build
# Generated on: $(date)
# CDK Stack: Asclepius-$STAGE
# Region: $REGION

# WebSocket endpoint from CDK deployment
VITE_WEBSOCKET_ENDPOINT=$WEBSOCKET_ENDPOINT
REACT_APP_WEBSOCKET_ENDPOINT=$WEBSOCKET_ENDPOINT

# AWS Region
VITE_AWS_REGION=$REGION
REACT_APP_AWS_REGION=$REGION

# Stage/Environment
VITE_STAGE=$STAGE
REACT_APP_STAGE=$STAGE

# DynamoDB Table Names from CDK deployment
VITE_VISIT_DATA_TABLE=$VISIT_DATA_TABLE
REACT_APP_VISIT_DATA_TABLE=$VISIT_DATA_TABLE

VITE_PATIENT_TABLE=$PATIENT_TABLE
REACT_APP_PATIENT_TABLE=$PATIENT_TABLE

VITE_VISIT_TABLE=$VISIT_TABLE
REACT_APP_VISIT_TABLE=$VISIT_TABLE

VITE_TRANSCRIPT_TABLE=$TRANSCRIPT_TABLE
REACT_APP_TRANSCRIPT_TABLE=$TRANSCRIPT_TABLE
EOF

# Export environment variables for the current build process
export VITE_WEBSOCKET_ENDPOINT=$WEBSOCKET_ENDPOINT
export REACT_APP_WEBSOCKET_ENDPOINT=$WEBSOCKET_ENDPOINT

export VITE_AWS_REGION=$REGION
export REACT_APP_AWS_REGION=$REGION

export VITE_STAGE=$STAGE
export REACT_APP_STAGE=$STAGE

export VITE_VISIT_DATA_TABLE=$VISIT_DATA_TABLE
export REACT_APP_VISIT_DATA_TABLE=$VISIT_DATA_TABLE

export VITE_PATIENT_TABLE=$PATIENT_TABLE
export REACT_APP_PATIENT_TABLE=$PATIENT_TABLE

export VITE_VISIT_TABLE=$VISIT_TABLE
export REACT_APP_VISIT_TABLE=$VISIT_TABLE

export VITE_TRANSCRIPT_TABLE=$TRANSCRIPT_TABLE
export REACT_APP_TRANSCRIPT_TABLE=$TRANSCRIPT_TABLE

echo "✅ Environment variables configured successfully for build!"
echo "   Variables are available in .env file and as environment variables"

if [ "$USE_FALLBACK" = true ] && [ ! -f "$FALLBACK_CONFIG" ]; then
    echo ""
    echo "⚠️  IMPORTANT: Using placeholder values because permissions are not configured"
    echo "   After first deployment, run: ./scripts/setup-amplify-build-role.sh"
    echo "   Then trigger a new build in the Amplify Console"
fi
