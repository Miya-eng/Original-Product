#!/bin/bash

# RDS PostgreSQL インスタンス作成スクリプト
# Usage: ./setup-rds.sh

set -e

# 設定値
DB_INSTANCE_IDENTIFIER="jimotoko-db"
DB_NAME="jimotoko"
DB_USERNAME="jimotoko_user"
DB_ENGINE="postgres"
DB_ENGINE_VERSION="15.13"
DB_INSTANCE_CLASS="db.t3.micro"  # フリーティア対応
ALLOCATED_STORAGE=20
VPC_SECURITY_GROUP_IDS=""  # 適切なセキュリティグループIDに置き換え
DB_SUBNET_GROUP_NAME=""    # 適切なDBサブネットグループ名に置き換え
AWS_REGION="ap-northeast-1"

echo "🚀 RDS PostgreSQL インスタンスを作成しています..."

# DBパスワードを生成または入力
if [ -z "$DB_PASSWORD" ]; then
    echo "データベースパスワードを入力してください:"
    read -s DB_PASSWORD
    export DB_PASSWORD
fi

# VPCの情報を取得
echo "📋 VPC情報を取得中..."
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=is-default,Values=true" --query "Vpcs[0].VpcId" --output text --region $AWS_REGION)
echo "デフォルトVPC ID: $VPC_ID"

# セキュリティグループを作成
SECURITY_GROUP_NAME="jimotoko-rds-sg"
echo "🔒 RDS用セキュリティグループを作成中..."

# 既存のセキュリティグループをチェック
EXISTING_SG=$(aws ec2 describe-security-groups --filters "Name=group-name,Values=$SECURITY_GROUP_NAME" --query "SecurityGroups[0].GroupId" --output text --region $AWS_REGION 2>/dev/null || echo "None")

if [ "$EXISTING_SG" = "None" ]; then
    SECURITY_GROUP_ID=$(aws ec2 create-security-group \
        --group-name $SECURITY_GROUP_NAME \
        --description "Security group for Jimotoko RDS PostgreSQL" \
        --vpc-id $VPC_ID \
        --query "GroupId" \
        --output text \
        --region $AWS_REGION)
    
    # PostgreSQLポート(5432)を開放
    aws ec2 authorize-security-group-ingress \
        --group-id $SECURITY_GROUP_ID \
        --protocol tcp \
        --port 5432 \
        --cidr 0.0.0.0/0 \
        --region $AWS_REGION
    
    echo "✅ セキュリティグループ作成完了: $SECURITY_GROUP_ID"
else
    SECURITY_GROUP_ID=$EXISTING_SG
    echo "✅ 既存のセキュリティグループを使用: $SECURITY_GROUP_ID"
fi

# DBサブネットグループを作成
DB_SUBNET_GROUP_NAME="jimotoko-db-subnet-group"
echo "🌐 DBサブネットグループを作成中..."

# サブネット情報を取得
SUBNET_IDS=$(aws ec2 describe-subnets \
    --filters "Name=vpc-id,Values=$VPC_ID" \
    --query "Subnets[].SubnetId" \
    --output text \
    --region $AWS_REGION)

# 既存のDBサブネットグループをチェック
EXISTING_SUBNET_GROUP=$(aws rds describe-db-subnet-groups --db-subnet-group-name $DB_SUBNET_GROUP_NAME --query "DBSubnetGroups[0].DBSubnetGroupName" --output text --region $AWS_REGION 2>/dev/null || echo "None")

if [ "$EXISTING_SUBNET_GROUP" = "None" ]; then
    aws rds create-db-subnet-group \
        --db-subnet-group-name $DB_SUBNET_GROUP_NAME \
        --db-subnet-group-description "DB subnet group for Jimotoko" \
        --subnet-ids $SUBNET_IDS \
        --region $AWS_REGION
    
    echo "✅ DBサブネットグループ作成完了: $DB_SUBNET_GROUP_NAME"
else
    echo "✅ 既存のDBサブネットグループを使用: $DB_SUBNET_GROUP_NAME"
fi

# RDSインスタンスの存在確認
EXISTING_DB=$(aws rds describe-db-instances --db-instance-identifier $DB_INSTANCE_IDENTIFIER --query "DBInstances[0].DBInstanceIdentifier" --output text --region $AWS_REGION 2>/dev/null || echo "None")

if [ "$EXISTING_DB" = "None" ]; then
    echo "💾 RDS PostgreSQLインスタンスを作成中..."
    
    aws rds create-db-instance \
        --db-instance-identifier $DB_INSTANCE_IDENTIFIER \
        --db-instance-class $DB_INSTANCE_CLASS \
        --engine $DB_ENGINE \
        --engine-version $DB_ENGINE_VERSION \
        --master-username $DB_USERNAME \
        --master-user-password $DB_PASSWORD \
        --allocated-storage $ALLOCATED_STORAGE \
        --vpc-security-group-ids $SECURITY_GROUP_ID \
        --db-subnet-group-name $DB_SUBNET_GROUP_NAME \
        --db-name $DB_NAME \
        --backup-retention-period 7 \
        --storage-encrypted \
        --no-multi-az \
        --no-publicly-accessible \
        --region $AWS_REGION
    
    echo "⏳ RDSインスタンスの作成を開始しました。完了まで数分かかります..."
    echo "📊 進行状況の確認: aws rds describe-db-instances --db-instance-identifier $DB_INSTANCE_IDENTIFIER --region $AWS_REGION"
    
    # インスタンスが利用可能になるまで待機
    echo "⏳ RDSインスタンスが利用可能になるまで待機中..."
    aws rds wait db-instance-available --db-instance-identifier $DB_INSTANCE_IDENTIFIER --region $AWS_REGION
    
else
    echo "✅ 既存のRDSインスタンスを使用: $EXISTING_DB"
fi

# エンドポイント情報を取得
DB_ENDPOINT=$(aws rds describe-db-instances \
    --db-instance-identifier $DB_INSTANCE_IDENTIFIER \
    --query "DBInstances[0].Endpoint.Address" \
    --output text \
    --region $AWS_REGION)

DB_PORT=$(aws rds describe-db-instances \
    --db-instance-identifier $DB_INSTANCE_IDENTIFIER \
    --query "DBInstances[0].Endpoint.Port" \
    --output text \
    --region $AWS_REGION)

echo ""
echo "🎉 RDS PostgreSQL セットアップ完了!"
echo ""
echo "📋 データベース接続情報:"
echo "  エンドポイント: $DB_ENDPOINT"
echo "  ポート: $DB_PORT"
echo "  データベース名: $DB_NAME"
echo "  ユーザー名: $DB_USERNAME"
echo ""
echo "🔧 環境変数として設定してください:"
echo "  DATABASE_URL=postgresql://$DB_USERNAME:$DB_PASSWORD@$DB_ENDPOINT:$DB_PORT/$DB_NAME"
echo ""
echo "⚠️  セキュリティのため、本番環境では適切なセキュリティグループ設定を行ってください。"
echo "   現在のセキュリティグループID: $SECURITY_GROUP_ID"