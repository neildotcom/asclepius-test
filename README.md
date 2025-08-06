# Asclepius Healthcare AI System

A sophisticated AI-powered healthcare system featuring real-time audio transcription, multi-agent medical analysis, and comprehensive care plan generation.

## 🏥 System Overview

Asclepius combines cutting-edge AI technologies to provide:
- **Real-time Audio Transcription** with AWS HealthScribe
- **12 Specialist AI Agents** for comprehensive medical analysis
- **Intelligent Care Plan Generation** with ICD-10 verification
- **Secure Healthcare Data Processing** with HIPAA considerations
- **Modern React Frontend** with AWS Amplify authentication

## 🏗️ Architecture

### Backend Infrastructure (CDK)
- **20 Lambda Functions**: Core pipeline + specialist AI agents
- **Step Functions**: Complex multi-agent workflow orchestration
- **DynamoDB**: Secure visit data storage
- **OpenSearch**: Medical knowledge base
- **ECS Fargate**: WebSocket streaming service
- **Application Load Balancer**: HTTPS/WSS endpoint

### Frontend (Amplify)
- **React + Vite**: Modern web application
- **AWS Amplify**: Authentication and hosting
- **Real-time WebSocket**: Audio streaming interface
- **CloudScape Design**: Professional healthcare UI

### Hybrid Architecture Approach

Asclepius uses a **hybrid architecture** combining CDK and Amplify:

1. **CDK Backend**: Handles core healthcare functionality (WebSocket, HealthScribe, data processing)
2. **Amplify Backend**: Handles user authentication (Cognito User Pool, sign-in/sign-up)
3. **Frontend**: React app that connects to both systems

## 🚀 Deployment Guide

### Prerequisites

After cloning this project to your repository, run the following in local terminal:

1. **AWS CLI and CDK**
   ```bash
   npm install -g aws-cdk
   aws configure
   ```

2. **Container Runtime (Required for ECS deployment)**
   
   **Option A: Finch (Recommended - AWS's open-source container tool)**
   ```bash
   # Install Finch
   brew install finch
   
   # Initialize Finch
   finch vm init
   
   # Verify installation
   finch version
   ```
   
   **Option B: Docker Desktop**
   ```bash
   # Download from https://www.docker.com/products/docker-desktop/
   # Or install via Homebrew
   brew install --cask docker
   ```

3. **SSL Certificate (Required for HealthScribe streaming)**
   ```bash
   # Request certificate from ACM
   aws acm request-certificate --domain-name yourdomain.com --validation-method DNS
   
   # Get certificate ARN
   aws acm list-certificates
   ```


### Step 1: Deploy Backend Infrastructure

```bash
# Navigate to infrastructure directory
cd infrastructure

# Set CDK to use Finch (if using Finch)
export CDK_DOCKER=finch

# For production with custom domain
./deploy.sh prod \
    --certificate-arn arn:aws:acm:us-east-1:123456789:certificate/your-cert-id \
    --domain-name api.yourdomain.com
```

### Step 2: Setup Amplify

```bash
# Install frontend dependencies
npm install

# Create Amplify backend for authentication
npx ampx sandbox
# This will:
# - Create amplify_outputs.json with auth configuration
# - Set up Cognito User Pool for authentication
# - Deploy authentication resources to AWS

# Force commit amplify_outputs.json to your repository
git add -f amplify_outputs.json
git commit -m "Add amplify_outputs.json"
git push origin <your branch>
```

#### Set Up Repository Integration

In Amplify console, set up CI/CD integration with your repository:

1. Go to the AWS Amplify Console
2. Create a new app by selecting a Git provider 
3. Complete the setup wizard

This will trigger your first build, which will use placeholder values since permissions aren't configured yet.

#### Complete the Setup

```bash
# After the initial deployment completes, set up the build role and permissions by running the following in your project terminal
./scripts/setup-amplify-build-role.sh

# This will:
# - Create/configure an Amplify build role with CloudFormation permissions
# - Configure DynamoDB permissions for Cognito authenticated users
# - Update the Amplify app to use the new role

# After running the setup script, trigger a new build in the Amplify Console or push a new commit to your repository. This build will use the actual values from your CDK stack.
git push origin <your branch>
```

Your application should now be up and running!




## 📊 System Components

### AI Specialist Agents
1. **Diabetes Specialist**: Blood sugar and insulin management
2. **Allergy Specialist**: Allergen identification and management
3. **Kidney Specialist**: Renal function assessment
4. **Insurance Specialist**: Coverage and billing optimization
5. **Nutritionist**: Dietary recommendations
6. **Ophthalmologist**: Eye health assessment
7. **Podiatrist**: Foot and ankle care
8. **Hospital Care Team**: Inpatient coordination
9. **ADA Compliance**: Accessibility recommendations
10. **Social Determinants**: Social health factors
11. **Physical Therapist**: Mobility and rehabilitation
12. **Pharmacist**: Medication management

### Core Pipeline
- **Audio Transcription**: Real-time speech-to-text with HealthScribe
- **Summary Processing**: Medical summary generation
- **ICD-10 Verification**: Diagnostic code validation
- **Care Plan Generation**: Comprehensive treatment planning
- **Orchestrator**: Multi-agent coordination and decision making

## 🔍 Monitoring and Troubleshooting

### Check Deployment Status
```bash
# View CDK stack status
aws cloudformation describe-stacks --stack-name Asclepius-dev

# Check ECS service health
aws ecs describe-services --cluster asclepius-cluster-dev --services asclepius-service-dev

# View Lambda function logs
aws logs describe-log-groups --log-group-name-prefix /aws/lambda/asclepius
```

### Common Issues

1. **Certificate Validation**: Ensure ACM certificate is validated and issued
2. **WebSocket Connection**: Verify ALB security groups allow port 443
3. **Lambda Timeouts**: Check CloudWatch logs for function execution times
4. **Step Functions Errors**: Monitor Step Functions execution history

## 🧹 Cleanup

```bash
# Destroy CDK infrastructure
cd infrastructure
npx cdk destroy Asclepius-dev --force

# Remove Amplify application
amplify delete
```

## 📞 Support

For deployment issues:
1. Check AWS CloudFormation console for stack events
2. Review ECS service and task health
3. Monitor Lambda function logs in CloudWatch
4. Verify Step Functions execution history

## 🔒 Security Considerations

- All data transmission uses HTTPS/WSS encryption
- IAM roles follow least-privilege principles
- VPC isolates resources with proper security groups
- Healthcare data handling follows HIPAA guidelines
- Certificate-based authentication for all endpoints

## 🔧 Troubleshooting

### Common Issues and Solutions

#### 1. "Cannot find module 'commander'" Error
**Problem**: You have the npm version of `jq` installed instead of the native binary.

**Solution**:
```bash
npm uninstall -g jq
brew install jq
jq --version  # Should show "jq-1.8.1" or similar
```

#### 2. "Log group already exists" Error
**Problem**: Previous failed deployment left log groups behind.

**Solution**: The CDK stack now handles this automatically with explicit log group management. If you still encounter this:
```bash
# Delete specific log group
aws logs delete-log-group --log-group-name "/aws/lambda/function-name-dev"

# Or clean up all Asclepius log groups
aws logs describe-log-groups --log-group-name-prefix "/aws/lambda/asclepius" \
  --query 'logGroups[].logGroupName' --output text | \
  xargs -I {} aws logs delete-log-group --log-group-name {}
```

#### 3. Container Runtime Issues
**Problem**: CDK can't find Docker/Finch.

**Solutions**:
```bash
# For Finch
finch vm start
export CDK_DOCKER=finch

# For Docker
# Start Docker Desktop application
export CDK_DOCKER=docker

# Verify
docker ps  # or finch ps
```

#### 4. SSL Certificate Issues
**Problem**: Certificate ARN is invalid or not found.

**Solutions**:
```bash
# List available certificates
aws acm list-certificates --region us-east-1

# Request new certificate
aws acm request-certificate \
  --domain-name yourdomain.com \
  --validation-method DNS \
  --region us-east-1
```

#### 5. No recommendations from AI Agents
**Problem**: No outputs in the AI Experts page during clinical visit

**Solution**: Make sure you have requested Bedrock Model Access in your AWS Console. You should enable Amazon Nova Micro in order to view AI Agent recommendations.

### Getting Help

If you encounter issues not covered here:

1. **Check the AWS CloudFormation console** for detailed error messages
2. **Review CloudWatch logs** for Lambda function errors
3. **Verify your AWS permissions** include all required services
4. **Ensure your AWS account has sufficient limits** for the resources being created

### Clean Deployment

For a completely clean deployment:
```bash
# Delete existing stack (if needed)
aws cloudformation delete-stack --stack-name Asclepius-dev

# Wait for deletion to complete
aws cloudformation wait stack-delete-complete --stack-name Asclepius-dev

# Deploy fresh
cd infrastructure
./deploy.sh dev --certificate-arn <your-cert-arn>
```

---

**Note**: This system processes sensitive healthcare information. Ensure compliance with relevant healthcare regulations (HIPAA, GDPR, etc.) in your deployment and usage.
# asclepius-test
# asclepius-test
# asclepius-test
