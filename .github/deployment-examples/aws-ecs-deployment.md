# AWS ECS Deployment Guide

This guide shows how to deploy your Hummingbird application to AWS ECS (Elastic Container Service).

## Prerequisites

- AWS Account with appropriate permissions
- AWS CLI installed and configured
- Docker image pushed to GitHub Container Registry (done automatically by the workflow)

## Setup Steps

### 1. Create RDS PostgreSQL Database

```bash
# Create a security group for RDS
aws ec2 create-security-group \
  --group-name hummingbird-rds-sg \
  --description "Security group for Hummingbird RDS"

# Get the security group ID
RDS_SG_ID=$(aws ec2 describe-security-groups \
  --group-names hummingbird-rds-sg \
  --query 'SecurityGroups[0].GroupId' \
  --output text)

# Create RDS instance
aws rds create-db-instance \
  --db-instance-identifier hummingbird-db \
  --db-instance-class db.t3.micro \
  --engine postgres \
  --engine-version 16 \
  --master-username hummingbird \
  --master-user-password YourSecurePassword123! \
  --allocated-storage 20 \
  --vpc-security-group-ids $RDS_SG_ID \
  --backup-retention-period 7 \
  --publicly-accessible
```

### 2. Create ECS Cluster

```bash
# Create ECS cluster
aws ecs create-cluster \
  --cluster-name hummingbird-cluster \
  --capacity-providers FARGATE FARGATE_SPOT \
  --default-capacity-provider-strategy \
    capacityProvider=FARGATE,weight=1,base=1 \
    capacityProvider=FARGATE_SPOT,weight=4
```

### 3. Create Task Definition

Create `task-definition.json`:

```json
{
  "family": "hummingbird-app",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "512",
  "memory": "1024",
  "executionRoleArn": "arn:aws:iam::YOUR_ACCOUNT_ID:role/ecsTaskExecutionRole",
  "taskRoleArn": "arn:aws:iam::YOUR_ACCOUNT_ID:role/ecsTaskRole",
  "containerDefinitions": [
    {
      "name": "hummingbird-app",
      "image": "ghcr.io/your-username/your-repo:latest",
      "essential": true,
      "portMappings": [
        {
          "containerPort": 8080,
          "protocol": "tcp"
        }
      ],
      "environment": [
        {
          "name": "DATABASE_HOST",
          "value": "your-rds-endpoint.rds.amazonaws.com"
        },
        {
          "name": "DATABASE_PORT",
          "value": "5432"
        },
        {
          "name": "DATABASE_NAME",
          "value": "hummingbird"
        },
        {
          "name": "DATABASE_USER",
          "value": "hummingbird"
        }
      ],
      "secrets": [
        {
          "name": "DATABASE_PASSWORD",
          "valueFrom": "arn:aws:secretsmanager:region:account-id:secret:db-password"
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/hummingbird-app",
          "awslogs-region": "us-east-1",
          "awslogs-stream-prefix": "ecs"
        }
      },
      "healthCheck": {
        "command": ["CMD-SHELL", "curl -f http://localhost:8080/health || exit 1"],
        "interval": 30,
        "timeout": 5,
        "retries": 3,
        "startPeriod": 60
      }
    }
  ]
}
```

Register the task definition:

```bash
aws ecs register-task-definition --cli-input-json file://task-definition.json
```

### 4. Create Application Load Balancer

```bash
# Create security group for ALB
aws ec2 create-security-group \
  --group-name hummingbird-alb-sg \
  --description "Security group for Hummingbird ALB"

ALB_SG_ID=$(aws ec2 describe-security-groups \
  --group-names hummingbird-alb-sg \
  --query 'SecurityGroups[0].GroupId' \
  --output text)

# Allow HTTP and HTTPS traffic
aws ec2 authorize-security-group-ingress \
  --group-id $ALB_SG_ID \
  --protocol tcp \
  --port 80 \
  --cidr 0.0.0.0/0

aws ec2 authorize-security-group-ingress \
  --group-id $ALB_SG_ID \
  --protocol tcp \
  --port 443 \
  --cidr 0.0.0.0/0

# Create load balancer
aws elbv2 create-load-balancer \
  --name hummingbird-alb \
  --subnets subnet-xxxxx subnet-yyyyy \
  --security-groups $ALB_SG_ID \
  --scheme internet-facing \
  --type application

# Create target group
aws elbv2 create-target-group \
  --name hummingbird-tg \
  --protocol HTTP \
  --port 8080 \
  --vpc-id vpc-xxxxx \
  --target-type ip \
  --health-check-path /health \
  --health-check-interval-seconds 30

# Create listener
aws elbv2 create-listener \
  --load-balancer-arn arn:aws:elasticloadbalancing:... \
  --protocol HTTP \
  --port 80 \
  --default-actions Type=forward,TargetGroupArn=arn:aws:elasticloadbalancing:...
```

### 5. Create ECS Service

```bash
# Create security group for ECS tasks
aws ec2 create-security-group \
  --group-name hummingbird-ecs-sg \
  --description "Security group for Hummingbird ECS tasks"

ECS_SG_ID=$(aws ec2 describe-security-groups \
  --group-names hummingbird-ecs-sg \
  --query 'SecurityGroups[0].GroupId' \
  --output text)

# Allow traffic from ALB
aws ec2 authorize-security-group-ingress \
  --group-id $ECS_SG_ID \
  --protocol tcp \
  --port 8080 \
  --source-group $ALB_SG_ID

# Allow ECS tasks to reach RDS
aws ec2 authorize-security-group-ingress \
  --group-id $RDS_SG_ID \
  --protocol tcp \
  --port 5432 \
  --source-group $ECS_SG_ID

# Create ECS service
aws ecs create-service \
  --cluster hummingbird-cluster \
  --service-name hummingbird-service \
  --task-definition hummingbird-app:1 \
  --desired-count 2 \
  --launch-type FARGATE \
  --platform-version LATEST \
  --network-configuration "awsvpcConfiguration={subnets=[subnet-xxxxx,subnet-yyyyy],securityGroups=[$ECS_SG_ID],assignPublicIp=ENABLED}" \
  --load-balancers "targetGroupArn=arn:aws:elasticloadbalancing:...,containerName=hummingbird-app,containerPort=8080" \
  --health-check-grace-period-seconds 60
```

### 6. Setup Auto Scaling

```bash
# Register scalable target
aws application-autoscaling register-scalable-target \
  --service-namespace ecs \
  --scalable-dimension ecs:service:DesiredCount \
  --resource-id service/hummingbird-cluster/hummingbird-service \
  --min-capacity 2 \
  --max-capacity 10

# Create scaling policy (CPU)
aws application-autoscaling put-scaling-policy \
  --policy-name cpu-scaling-policy \
  --service-namespace ecs \
  --scalable-dimension ecs:service:DesiredCount \
  --resource-id service/hummingbird-cluster/hummingbird-service \
  --policy-type TargetTrackingScaling \
  --target-tracking-scaling-policy-configuration '{
    "TargetValue": 70.0,
    "PredefinedMetricSpecification": {
      "PredefinedMetricType": "ECSServiceAverageCPUUtilization"
    },
    "ScaleInCooldown": 60,
    "ScaleOutCooldown": 60
  }'

# Create scaling policy (Memory)
aws application-autoscaling put-scaling-policy \
  --policy-name memory-scaling-policy \
  --service-namespace ecs \
  --scalable-dimension ecs:service:DesiredCount \
  --resource-id service/hummingbird-cluster/hummingbird-service \
  --policy-type TargetTrackingScaling \
  --target-tracking-scaling-policy-configuration '{
    "TargetValue": 80.0,
    "PredefinedMetricSpecification": {
      "PredefinedMetricType": "ECSServiceAverageMemoryUtilization"
    },
    "ScaleInCooldown": 60,
    "ScaleOutCooldown": 60
  }'
```

### 7. Configure GitHub Actions Deployment

Add these secrets to GitHub:

```
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
AWS_REGION
ECS_CLUSTER_NAME=hummingbird-cluster
ECS_SERVICE_NAME=hummingbird-service
ECS_TASK_DEFINITION=hummingbird-app
```

Update the deploy job in `.github/workflows/release.yml`:

```yaml
deploy:
  name: Deploy Application
  runs-on: ubuntu-latest
  needs: [version, build-and-push, create-release]
  if: true

  steps:
    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v4
      with:
        aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
        aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        aws-region: ${{ secrets.AWS_REGION }}

    - name: Download task definition
      run: |
        aws ecs describe-task-definition \
          --task-definition ${{ secrets.ECS_TASK_DEFINITION }} \
          --query taskDefinition > task-definition.json

    - name: Update task definition image
      id: task-def
      uses: aws-actions/amazon-ecs-render-task-definition@v1
      with:
        task-definition: task-definition.json
        container-name: hummingbird-app
        image: ghcr.io/${{ github.repository }}:${{ needs.version.outputs.new_version }}

    - name: Deploy to Amazon ECS
      uses: aws-actions/amazon-ecs-deploy-task-definition@v1
      with:
        task-definition: ${{ steps.task-def.outputs.task-definition }}
        service: ${{ secrets.ECS_SERVICE_NAME }}
        cluster: ${{ secrets.ECS_CLUSTER_NAME }}
        wait-for-service-stability: true
```

## Monitoring

### View Logs

```bash
# Stream logs
aws logs tail /ecs/hummingbird-app --follow

# Get service events
aws ecs describe-services \
  --cluster hummingbird-cluster \
  --services hummingbird-service \
  --query 'services[0].events[:5]'
```

### Check Service Status

```bash
aws ecs describe-services \
  --cluster hummingbird-cluster \
  --services hummingbird-service
```

## Cost Optimization

1. Use Fargate Spot for non-production workloads
2. Enable container insights selectively
3. Use appropriate task sizes (don't over-provision)
4. Set up CloudWatch alarms for cost anomalies

## Cleanup

```bash
# Delete service
aws ecs delete-service \
  --cluster hummingbird-cluster \
  --service hummingbird-service \
  --force

# Delete cluster
aws ecs delete-cluster --cluster hummingbird-cluster

# Delete RDS instance
aws rds delete-db-instance \
  --db-instance-identifier hummingbird-db \
  --skip-final-snapshot
```
