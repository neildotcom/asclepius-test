#!/bin/bash

# Configure Frontend with CDK Deployment Outputs
set -e

STAGE=${1:-dev}
REGION=${2:-us-east-1}

echo "🔧 Configuring frontend with CDK deployment outputs..."
echo "   Stage: $STAGE"
echo "   Region: $REGION"
echo ""

# Get all outputs from CDK stack
echo "📡 Retrieving configuration from CDK stack..."
STACK_OUTPUTS=$(aws cloudformation describe-stacks \
    --stack-name Asclepius-$STAGE \
    --region $REGION \
    --query 'Stacks[0].Outputs' \
    --output json 2>/dev/null)

if [ -z "$STACK_OUTPUTS" ] || [ "$STACK_OUTPUTS" = "null" ]; then
    echo "❌ ERROR: Could not retrieve outputs from stack Asclepius-$STAGE"
    echo "   Make sure the CDK stack is deployed successfully"
    echo "   Run: cd infrastructure && ./deploy.sh $STAGE --certificate-arn <your-cert-arn>"
    exit 1
fi

# Extract individual values
WEBSOCKET_ENDPOINT=$(echo $STACK_OUTPUTS | jq -r '.[] | select(.OutputKey=="WebSocketEndpoint") | .OutputValue')
VISIT_DATA_TABLE=$(echo $STACK_OUTPUTS | jq -r '.[] | select(.OutputKey=="VisitDataTableName") | .OutputValue')
PATIENT_TABLE=$(echo $STACK_OUTPUTS | jq -r '.[] | select(.OutputKey=="PatientTableName") | .OutputValue')
VISIT_TABLE=$(echo $STACK_OUTPUTS | jq -r '.[] | select(.OutputKey=="VisitTableName") | .OutputValue')
TRANSCRIPT_TABLE=$(echo $STACK_OUTPUTS | jq -r '.[] | select(.OutputKey=="TranscriptTableName") | .OutputValue')

# Validate required outputs
if [ "$WEBSOCKET_ENDPOINT" = "null" ] || [ -z "$WEBSOCKET_ENDPOINT" ]; then
    echo "❌ ERROR: WebSocket endpoint not found in stack outputs"
    exit 1
fi

echo "✅ Configuration retrieved successfully:"
echo "   WebSocket Endpoint: $WEBSOCKET_ENDPOINT"
echo "   Visit Data Table: $VISIT_DATA_TABLE"
echo "   Patient Table: $PATIENT_TABLE"
echo "   Visit Table: $VISIT_TABLE"
echo "   Transcript Table: $TRANSCRIPT_TABLE"

# Create .env.local file with actual values
echo "📝 Creating .env.local with deployment values..."

# Ensure we're in the project root (where package.json exists)
if [ ! -f "package.json" ]; then
    echo "❌ package.json not found. Please run this script from the project root:"
    echo "   ./scripts/configure-frontend.sh dev"
    exit 1
fi

cat > .env.local << EOF
# Asclepius Environment Configuration - Auto-generated
# Generated on: $(date)
# CDK Stack: Asclepius-$STAGE
# Region: $REGION

# WebSocket endpoint from CDK deployment
REACT_APP_WEBSOCKET_ENDPOINT=$WEBSOCKET_ENDPOINT

# AWS Region
REACT_APP_AWS_REGION=$REGION

# Stage/Environment
REACT_APP_STAGE=$STAGE

# DynamoDB Table Names from CDK deployment
REACT_APP_VISIT_DATA_TABLE=$VISIT_DATA_TABLE
REACT_APP_PATIENT_TABLE=$PATIENT_TABLE
REACT_APP_VISIT_TABLE=$VISIT_TABLE
REACT_APP_TRANSCRIPT_TABLE=$TRANSCRIPT_TABLE
EOF

echo "✅ Frontend configuration complete!"
echo ""
echo "📋 Configuration Summary:"
echo "   WebSocket Endpoint: $WEBSOCKET_ENDPOINT"
echo "   AWS Region: $REGION"
echo "   Stage: $STAGE"
echo "   Config File: .env.local (in project root)"
echo ""
echo "📊 DynamoDB Tables:"
echo "   Visit Data: $VISIT_DATA_TABLE"
echo "   Patient: $PATIENT_TABLE"
echo "   Visit: $VISIT_TABLE"
echo "   Transcript: $TRANSCRIPT_TABLE"
echo ""
echo "🚀 Next Steps:"
echo "   1. Deploy Amplify frontend: amplify push"
echo "   2. Test WebSocket connection and database access"
echo ""
echo "💡 Tip: You can also manually edit .env.local if needed"
