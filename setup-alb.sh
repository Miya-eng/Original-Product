#!/bin/bash

# Application Load Balancer Setup Script for Jimotoko Backend
# This script creates ALB, Target Group, and configures DNS for api.jimotoko.com

set -e

echo "🚀 Application Load Balancer セットアップ開始..."

# Variables
REGION="ap-northeast-1"
CLUSTER_NAME="jimotoko-cluster"
SERVICE_NAME="jimotoko-backend-service"
ALB_NAME="jimotoko-backend-alb"
TARGET_GROUP_NAME="jimotoko-backend-tg"
DOMAIN="api.jimotoko.com"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

error() {
    echo -e "${RED}❌ $1${NC}"
    exit 1
}

# Check AWS CLI
if ! command -v aws &> /dev/null; then
    error "AWS CLI がインストールされていません"
fi

echo "📋 現在のリソース確認..."

# Get VPC information
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=is-default,Values=true" --query 'Vpcs[0].VpcId' --output text --region $REGION)
if [ "$VPC_ID" = "None" ] || [ -z "$VPC_ID" ]; then
    error "デフォルトVPCが見つかりません"
fi
success "VPC ID: $VPC_ID"

# Get subnets (need at least 2 for ALB)
SUBNET_IDS=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" "Name=default-for-az,Values=true" --query 'Subnets[].SubnetId' --output text --region $REGION)
SUBNET_ARRAY=($SUBNET_IDS)
if [ ${#SUBNET_ARRAY[@]} -lt 2 ]; then
    error "ALBには最低2つのサブネットが必要です（現在: ${#SUBNET_ARRAY[@]}個）"
fi
success "サブネット: ${SUBNET_ARRAY[@]}"

# Check if ALB already exists
ALB_ARN=$(aws elbv2 describe-load-balancers --names $ALB_NAME --query 'LoadBalancers[0].LoadBalancerArn' --output text --region $REGION 2>/dev/null || echo "None")

if [ "$ALB_ARN" != "None" ] && [ -n "$ALB_ARN" ]; then
    warning "ALB '$ALB_NAME' は既に存在します"
    ALB_DNS=$(aws elbv2 describe-load-balancers --load-balancer-arns $ALB_ARN --query 'LoadBalancers[0].DNSName' --output text --region $REGION)
    success "既存のALB DNS: $ALB_DNS"
else
    echo "🔧 Application Load Balancer 作成中..."
    
    # Create security group for ALB
    ALB_SG_ID=$(aws ec2 create-security-group \
        --group-name "jimotoko-alb-sg" \
        --description "Security group for Jimotoko ALB" \
        --vpc-id $VPC_ID \
        --query 'GroupId' \
        --output text \
        --region $REGION 2>/dev/null || \
        aws ec2 describe-security-groups \
        --filters "Name=group-name,Values=jimotoko-alb-sg" "Name=vpc-id,Values=$VPC_ID" \
        --query 'SecurityGroups[0].GroupId' \
        --output text \
        --region $REGION)
    
    success "ALB Security Group: $ALB_SG_ID"
    
    # Configure ALB security group rules
    aws ec2 authorize-security-group-ingress \
        --group-id $ALB_SG_ID \
        --protocol tcp \
        --port 80 \
        --cidr 0.0.0.0/0 \
        --region $REGION 2>/dev/null || true
    
    aws ec2 authorize-security-group-ingress \
        --group-id $ALB_SG_ID \
        --protocol tcp \
        --port 443 \
        --cidr 0.0.0.0/0 \
        --region $REGION 2>/dev/null || true
    
    success "ALB セキュリティグループ設定完了"
    
    # Create ALB
    ALB_ARN=$(aws elbv2 create-load-balancer \
        --name $ALB_NAME \
        --subnets ${SUBNET_ARRAY[@]} \
        --security-groups $ALB_SG_ID \
        --scheme internet-facing \
        --type application \
        --ip-address-type ipv4 \
        --query 'LoadBalancers[0].LoadBalancerArn' \
        --output text \
        --region $REGION)
    
    success "ALB 作成完了: $ALB_NAME"
    
    # Get ALB DNS name
    ALB_DNS=$(aws elbv2 describe-load-balancers --load-balancer-arns $ALB_ARN --query 'LoadBalancers[0].DNSName' --output text --region $REGION)
    success "ALB DNS: $ALB_DNS"
fi

# Check if Target Group exists
TG_ARN=$(aws elbv2 describe-target-groups --names $TARGET_GROUP_NAME --query 'TargetGroups[0].TargetGroupArn' --output text --region $REGION 2>/dev/null || echo "None")

if [ "$TG_ARN" != "None" ] && [ -n "$TG_ARN" ]; then
    warning "Target Group '$TARGET_GROUP_NAME' は既に存在します"
else
    echo "🎯 Target Group 作成中..."
    
    # Create Target Group
    TG_ARN=$(aws elbv2 create-target-group \
        --name $TARGET_GROUP_NAME \
        --protocol HTTP \
        --port 8000 \
        --vpc-id $VPC_ID \
        --target-type ip \
        --health-check-path "/api/health/" \
        --health-check-interval-seconds 30 \
        --health-check-timeout-seconds 5 \
        --healthy-threshold-count 2 \
        --unhealthy-threshold-count 5 \
        --query 'TargetGroups[0].TargetGroupArn' \
        --output text \
        --region $REGION)
    
    success "Target Group 作成完了: $TARGET_GROUP_NAME"
fi

# Create listener if it doesn't exist
LISTENER_ARN=$(aws elbv2 describe-listeners --load-balancer-arn $ALB_ARN --query 'Listeners[?Port==`80`].ListenerArn' --output text --region $REGION)

if [ -z "$LISTENER_ARN" ] || [ "$LISTENER_ARN" = "None" ]; then
    echo "👂 Listener 作成中..."
    
    aws elbv2 create-listener \
        --load-balancer-arn $ALB_ARN \
        --protocol HTTP \
        --port 80 \
        --default-actions Type=forward,TargetGroupArn=$TG_ARN \
        --region $REGION > /dev/null
    
    success "HTTP Listener 作成完了"
else
    success "HTTP Listener は既に存在します"
fi

echo ""
echo "🔄 ECS Service を Target Group に登録中..."

# Update ECS service to use ALB
aws ecs update-service \
    --cluster $CLUSTER_NAME \
    --service $SERVICE_NAME \
    --load-balancers targetGroupArn=$TG_ARN,containerName=jimotoko-backend,containerPort=8000 \
    --region $REGION > /dev/null

success "ECS Service を ALB に接続しました"

echo ""
echo "📊 デプロイ状況確認..."

# Wait for service to stabilize
echo "⏳ ECS Service の安定化を待機中..."
aws ecs wait services-stable --cluster $CLUSTER_NAME --services $SERVICE_NAME --region $REGION

success "ECS Service が安定しました"

echo ""
echo "🌐 DNS 設定情報..."
echo "次のステップ:"
echo "1. Route 53 で $DOMAIN の A レコードを作成"
echo "2. ALB DNS名を設定: $ALB_DNS"
echo "3. SSL証明書を設定（ACM）"
echo ""
echo "一時的なテスト URL: http://$ALB_DNS"
echo ""
echo "✅ ALB セットアップ完了！"