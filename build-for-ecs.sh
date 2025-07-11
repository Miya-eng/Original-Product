#!/bin/bash

# ECS用のBackend Dockerイメージビルドスクリプト
# ARM64 (Apple Silicon) から AMD64 (ECS) 向けにビルド
# Note: フロントエンドはS3 + CloudFrontで配信するため、このスクリプトには含まれません

# 色付き出力用
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# ECRリポジトリ設定（実際の値に置き換えてください）
AWS_REGION="ap-northeast-1"
AWS_ACCOUNT_ID="162174360270"
ECR_BACKEND_REPO="jimotoko-backend"

echo -e "${YELLOW}=== Backend用ECSマルチプラットフォームビルドを開始 ===${NC}"

# 1. Docker Buildxの設定確認
echo -e "${BLUE}Docker Buildxの設定を確認中...${NC}"
if ! docker buildx version &> /dev/null; then
    echo -e "${RED}Docker Buildxがインストールされていません。${NC}"
    exit 1
fi

# 2. Buildxビルダーの作成（存在しない場合）
BUILDER_NAME="multiplatform-builder"
if ! docker buildx ls | grep -q $BUILDER_NAME; then
    echo -e "${GREEN}新しいBuildxビルダーを作成中...${NC}"
    docker buildx create --name $BUILDER_NAME --use
    docker buildx inspect --bootstrap
else
    echo -e "${GREEN}既存のBuildxビルダーを使用: $BUILDER_NAME${NC}"
    docker buildx use $BUILDER_NAME
fi

# 3. AWS ECRへのログイン
echo -e "${BLUE}AWS ECRにログイン中...${NC}"
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

if [ $? -ne 0 ]; then
    echo -e "${RED}ECRログインに失敗しました。AWS認証情報を確認してください。${NC}"
    exit 1
fi

# 4. Backendイメージのビルドとプッシュ
echo -e "${GREEN}=== Backendイメージをビルド中 ===${NC}"
cd backend

# タグの設定
BACKEND_TAG="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_BACKEND_REPO:latest"

# マルチプラットフォームビルド（AMD64専用）
docker buildx build \
    --platform linux/amd64 \
    --tag $BACKEND_TAG \
    --push \
    .

if [ $? -ne 0 ]; then
    echo -e "${RED}Backendイメージのビルドに失敗しました。${NC}"
    exit 1
fi

echo -e "${GREEN}Backendイメージのビルドとプッシュが完了しました。${NC}"

# 5. ビルド結果の確認
echo -e "${BLUE}=== ビルド結果 ===${NC}"
echo -e "${GREEN}Backend: $BACKEND_TAG${NC}"

# 6. イメージの詳細確認
echo -e "${BLUE}=== イメージの詳細 ===${NC}"
aws ecr describe-images --repository-name $ECR_BACKEND_REPO --region $AWS_REGION --query 'imageDetails[0]' --output json

echo -e "${GREEN}=== Backend ECS用ビルドが正常に完了しました！ ===${NC}"
echo -e "${YELLOW}注意: ECSタスク定義でこのイメージURIを使用してください。${NC}"
echo -e "${BLUE}フロントエンドはS3 + CloudFrontで配信します。${NC}"
echo -e "${BLUE}フロントエンドのデプロイは ./frontend/deploy-frontend.sh を使用してください。${NC}"