#!/bin/bash

# Script to set up the proper project structure for deployment
set -e

echo "🏗️  Setting up Asclepius project structure for deployment..."

# Create main directories
echo "📁 Creating directory structure..."

# Lambda functions directory
mkdir -p lambda/shared

# Infrastructure directory (CDK)
mkdir -p infrastructure/{bin,lib,config,step-functions,assets/policies}

# Scripts directory
mkdir -p scripts

# Documentation directory
mkdir -p docs

# Create placeholder files for Lambda functions
echo "📝 Creating Lambda function templates..."

# Shared utilities for Lambda functions
cat > lambda/shared/aws-clients.js << 'EOF'
// Shared AWS SDK clients for Lambda functions
const AWS = require('aws-sdk');

// Configure AWS SDK
AWS.config.update({
  region: process.env.AWS_REGION || 'us-east-1'
});

// Export configured clients
module.exports = {
  dynamodb: new AWS.DynamoDB.DocumentClient(),
  stepfunctions: new AWS.StepFunctions(),
  bedrock: new AWS.BedrockRuntime(),
  opensearch: new AWS.ES(),
  s3: new AWS.S3()
};
EOF

cat > lambda/shared/utils.js << 'EOF'
// Shared utility functions for Lambda functions

const logger = {
  info: (message, data = {}) => {
    console.log(JSON.stringify({ level: 'INFO', message, ...data }));
  },
  error: (message, error = {}) => {
    console.error(JSON.stringify({ level: 'ERROR', message, error: error.message || error }));
  },
  debug: (message, data = {}) => {
    if (process.env.LOG_LEVEL === 'DEBUG') {
      console.log(JSON.stringify({ level: 'DEBUG', message, ...data }));
    }
  }
};

const response = {
  success: (data = {}) => ({
    statusCode: 200,
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*'
    },
    body: JSON.stringify({ success: true, ...data })
  }),
  
  error: (message, statusCode = 500) => ({
    statusCode,
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*'
    },
    body: JSON.stringify({ success: false, error: message })
  })
};

module.exports = {
  logger,
  response
};
EOF

# Create example Lambda function structure
mkdir -p lambda/ai-processor
cat > lambda/ai-processor/package.json << 'EOF'
{
  "name": "ai-processor",
  "version": "1.0.0",
  "description": "AI processing Lambda function",
  "main": "index.js",
  "dependencies": {
    "aws-sdk": "^2.1400.0"
  }
}
EOF

cat > lambda/ai-processor/index.js << 'EOF'
// AI Processing Lambda Function
const { logger, response } = require('../shared/utils');
const { bedrock, dynamodb } = require('../shared/aws-clients');

exports.handler = async (event) => {
  try {
    logger.info('AI processing started', { event });
    
    // TODO: Add your AI processing logic here
    // This will be replaced with your actual Lambda function code
    
    const result = {
      message: 'AI processing completed',
      timestamp: new Date().toISOString()
    };
    
    logger.info('AI processing completed', result);
    return response.success(result);
    
  } catch (error) {
    logger.error('AI processing failed', error);
    return response.error('AI processing failed');
  }
};
EOF

# Create deployment scripts
echo "📜 Creating deployment scripts..."

cat > scripts/deploy.sh << 'EOF'
#!/bin/bash

# Deployment script for Asclepius
set -e

# Default values
STAGE="dev"
REGION="us-east-1"
PROFILE=""

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --stage)
      STAGE="$2"
      shift 2
      ;;
    --region)
      REGION="$2"
      shift 2
      ;;
    --profile)
      PROFILE="$2"
      shift 2
      ;;
    *)
      echo "Unknown option $1"
      exit 1
      ;;
  esac
done

echo "🚀 Deploying Asclepius to $STAGE environment in $REGION"

# Set AWS profile if provided
if [ ! -z "$PROFILE" ]; then
  export AWS_PROFILE=$PROFILE
fi

# Deploy infrastructure
echo "📦 Deploying infrastructure..."
cd infrastructure
npm run build
cdk deploy --all --require-approval never
cd ..

echo "✅ Deployment completed successfully!"
echo "Next steps:"
echo "1. Deploy frontend with: amplify push"
echo "2. Update frontend configuration with new backend endpoints"
EOF

chmod +x scripts/deploy.sh

cat > scripts/cleanup.sh << 'EOF'
#!/bin/bash

# Cleanup script for Asclepius
set -e

STAGE="dev"
REGION="us-east-1"
PROFILE=""

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --stage)
      STAGE="$2"
      shift 2
      ;;
    --region)
      REGION="$2"
      shift 2
      ;;
    --profile)
      PROFILE="$2"
      shift 2
      ;;
    *)
      echo "Unknown option $1"
      exit 1
      ;;
  esac
done

echo "🧹 Cleaning up Asclepius $STAGE environment in $REGION"

# Set AWS profile if provided
if [ ! -z "$PROFILE" ]; then
  export AWS_PROFILE=$PROFILE
fi

# Destroy infrastructure
echo "💥 Destroying infrastructure..."
cd infrastructure
cdk destroy --all --force
cd ..

echo "✅ Cleanup completed!"
EOF

chmod +x scripts/cleanup.sh

# Create documentation templates
echo "📚 Creating documentation templates..."

cat > docs/DEPLOYMENT_GUIDE.md << 'EOF'
# Asclepius Deployment Guide

## Prerequisites

- AWS CLI configured with appropriate permissions
- Node.js 18+ installed
- Docker installed (for local testing)
- Git installed

## Quick Start

1. Clone the repository
2. Install dependencies
3. Configure environment
4. Deploy infrastructure
5. Deploy frontend

## Detailed Instructions

[To be filled with specific deployment steps]
EOF

cat > docs/ARCHITECTURE.md << 'EOF'
# Asclepius Architecture

## Overview

[Architecture diagram and description to be added]

## Components

- Frontend: React + Vite hosted on Amplify
- Backend: ECS Fargate container
- AI Pipeline: Step Functions + Lambda + Bedrock
- Data Storage: DynamoDB + OpenSearch
- Real-time: WebSocket connections

## Data Flow

[Detailed data flow description to be added]
EOF

# Create environment configuration template
cat > .env.example << 'EOF'
# AWS Configuration
AWS_REGION=us-east-1
AWS_ACCOUNT_ID=123456789012

# Application Configuration
APP_NAME=asclepius
STAGE=dev

# ECS Configuration
CONTAINER_PORT=3000
TASK_CPU=512
TASK_MEMORY=1024

# Database Configuration
DYNAMODB_TABLE_PREFIX=asclepius

# OpenSearch Configuration
OPENSEARCH_DOMAIN=asclepius-knowledge-base

# Bedrock Configuration
BEDROCK_MODEL_ID=anthropic.claude-v2
EOF

# Create deployment configuration
cat > deploy-config.json << 'EOF'
{
  "environments": {
    "dev": {
      "region": "us-east-1",
      "stage": "dev",
      "ecsConfig": {
        "cpu": 512,
        "memory": 1024,
        "desiredCount": 1
      },
      "openSearchConfig": {
        "instanceType": "t3.small.search",
        "instanceCount": 1
      }
    },
    "prod": {
      "region": "us-east-1",
      "stage": "prod",
      "ecsConfig": {
        "cpu": 1024,
        "memory": 2048,
        "desiredCount": 2
      },
      "openSearchConfig": {
        "instanceType": "m6g.large.search",
        "instanceCount": 2
      }
    }
  }
}
EOF

echo ""
echo "✅ Project structure setup complete!"
echo ""
echo "📁 Created directories:"
echo "  - lambda/ (for Lambda function code)"
echo "  - infrastructure/ (for CDK infrastructure code)"
echo "  - scripts/ (for deployment scripts)"
echo "  - docs/ (for documentation)"
echo ""
echo "📝 Created files:"
echo "  - Lambda function templates"
echo "  - Deployment scripts"
echo "  - Documentation templates"
echo "  - Environment configuration"
echo ""
echo "🔄 Next steps:"
echo "1. Run ./extract-lambda-functions.sh to get your current Lambda code"
echo "2. Run ./extract-step-functions.sh to get your Step Functions definitions"
echo "3. Run ./cdk-setup.sh to initialize CDK infrastructure"
echo "4. Update configuration files with your actual values"
EOF

chmod +x setup-project-structure.sh

Perfect! Now I've created a comprehensive solution for you. Here's what I've built:

## What I've Created

1. **`PROJECT_STRUCTURE.md`** - Visual guide showing current vs target structure
2. **`setup-project-structure.sh`** - Script to create the proper directory structure
3. **`extract-lambda-functions.sh`** - Script to download your Lambda code from AWS
4. **`extract-step-functions.sh`** - Script to export your Step Functions definitions

## Key Insights About Your Project Structure

### The Problem You're Facing
Right now your Lambda functions and Step Functions exist only in the AWS Console. Users can't deploy them because the code isn't in your repository.

### The Solution
Bring everything into your local project:
- **Lambda code** → `lambda/` directory
- **Step Functions definitions** → `infrastructure/step-functions/`
- **Infrastructure as Code** → `infrastructure/` (CDK)
- **Deployment scripts** → `scripts/`

## How to Proceed

### Step 1: Set up the structure
```bash
chmod +x setup-project-structure.sh
./setup-project-structure.sh
```

### Step 2: Extract your current AWS resources
```bash
# Get your Lambda functions
chmod +x extract-lambda-functions.sh
./extract-lambda-functions.sh

# Get your Step Functions
chmod +x extract-step-functions.sh
./extract-step-functions.sh
```

### Step 3: Set up CDK infrastructure
```bash
chmod +x cdk-setup.sh
./cdk-setup.sh
```

## The End Result

Users will be able to:
1. Clone your repository
2. Run `./scripts/deploy.sh --stage dev`
3. Get a fully working Asclepius deployment

All your AWS resources (ECS, Lambda, Step Functions, DynamoDB, OpenSearch) will be created from code, not manually in the console.

Would you like to start by running the setup script, or do you have questions about any part of this approach?
