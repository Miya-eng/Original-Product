#!/bin/bash

# AWS Systems Manager Parameter Store にシークレットを設定するスクリプト
# Usage: ./setup-aws-secrets.sh

set -e

AWS_REGION="ap-northeast-1"

echo "🔐 AWS Parameter Store にシークレットを設定します"

# DATABASE_URL の設定
echo "📋 DATABASE_URL を入力してください:"
echo "形式: postgresql://username:password@endpoint:5432/database_name"
read -r DATABASE_URL

if [ -z "$DATABASE_URL" ]; then
    echo "❌ DATABASE_URL が入力されていません"
    exit 1
fi

echo "🔑 Parameter Store に DATABASE_URL を保存中..."
aws ssm put-parameter \
    --name "/jimotoko/database-url" \
    --value "$DATABASE_URL" \
    --type "SecureString" \
    --description "Jimotoko RDS PostgreSQL connection string" \
    --region $AWS_REGION \
    --overwrite

# SECRET_KEY の設定
echo "📋 Django SECRET_KEY を入力してください (空の場合は自動生成):"
read -r SECRET_KEY

if [ -z "$SECRET_KEY" ]; then
    echo "🔄 SECRET_KEY を自動生成中..."
    SECRET_KEY=$(python3 -c "
import secrets
import string
chars = string.ascii_letters + string.digits + '!@#$%^&*(-_=+)'
print(''.join(secrets.choice(chars) for i in range(50)))
")
    echo "✅ SECRET_KEY を自動生成しました"
fi

echo "🔑 Parameter Store に SECRET_KEY を保存中..."
aws ssm put-parameter \
    --name "/jimotoko/secret-key" \
    --value "$SECRET_KEY" \
    --type "SecureString" \
    --description "Django secret key for Jimotoko" \
    --region $AWS_REGION \
    --overwrite

# Google Geocoding API Key の設定
echo "📋 Google Geocoding API Key を入力してください:"
read -r GOOGLE_API_KEY

if [ -z "$GOOGLE_API_KEY" ]; then
    echo "❌ Google Geocoding API Key が入力されていません"
    exit 1
fi

echo "🔑 Parameter Store に Google API Key を保存中..."
aws ssm put-parameter \
    --name "/jimotoko/google-geocoding-api-key" \
    --value "$GOOGLE_API_KEY" \
    --type "SecureString" \
    --description "Google Geocoding API key for Jimotoko" \
    --region $AWS_REGION \
    --overwrite

echo ""
echo "🎉 AWS Parameter Store へのシークレット設定完了!"
echo ""
echo "📋 設定されたパラメータ:"
echo "  - /jimotoko/database-url"
echo "  - /jimotoko/secret-key"
echo "  - /jimotoko/google-geocoding-api-key"
echo ""
echo "🔧 ECSタスク定義で以下のARNを使用してください:"
echo "  - arn:aws:ssm:$AWS_REGION:162174360270:parameter/jimotoko/database-url"
echo "  - arn:aws:ssm:$AWS_REGION:162174360270:parameter/jimotoko/secret-key"
echo "  - arn:aws:ssm:$AWS_REGION:162174360270:parameter/jimotoko/google-geocoding-api-key"
echo ""
echo "✅ ECSタスクはこれらのパラメータに自動的にアクセスできます"