#!/bin/bash

# 変数設定
S3_BUCKET="jimotoko-frontend-s3"
CLOUDFRONT_DISTRIBUTION_ID="E1234567890ABC" # 実際のIDに置き換え
BUILD_DIR="./out"  # Next.js export用

# 色付き出力用
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${YELLOW}Starting frontend deployment...${NC}"

# 環境チェック
if ! command -v aws &> /dev/null; then
    echo -e "${RED}AWS CLI is not installed. Please install it first.${NC}"
    exit 1
fi

if ! command -v npm &> /dev/null; then
    echo -e "${RED}npm is not installed. Please install Node.js first.${NC}"
    exit 1
fi

# 1. 依存関係のインストール
echo -e "${GREEN}Installing dependencies...${NC}"
npm ci

# 2. ビルドの実行
echo -e "${GREEN}Building frontend for production...${NC}"
npm run build:prod

if [ ! -d "$BUILD_DIR" ]; then
    echo -e "${RED}Build failed! Build directory not found.${NC}"
    echo -e "${BLUE}Trying with standard build directory...${NC}"
    BUILD_DIR="./.next"
    if [ ! -d "$BUILD_DIR" ]; then
        echo -e "${RED}Build directory still not found. Exiting.${NC}"
        exit 1
    fi
fi

# 3. 現在のファイルをバックアップ（オプション）
echo -e "${GREEN}Creating backup...${NC}"
BACKUP_NAME="${S3_BUCKET}-backup-$(date +%Y%m%d-%H%M%S)"
aws s3 sync s3://${S3_BUCKET} s3://${BACKUP_NAME} --delete

if [ $? -eq 0 ]; then
    echo -e "${GREEN}Backup created: ${BACKUP_NAME}${NC}"
else
    echo -e "${YELLOW}Backup failed or bucket doesn't exist yet. Continuing...${NC}"
fi

# 4. S3への同期
echo -e "${GREEN}Syncing files to S3...${NC}"

# Next.js の場合、静的エクスポートを使用
if [ -d "./out" ]; then
    BUILD_DIR="./out"
    
    # HTMLファイル（キャッシュなし）
    aws s3 sync ${BUILD_DIR} s3://${S3_BUCKET} \
        --exclude "*" \
        --include "*.html" \
        --cache-control "no-cache, no-store, must-revalidate" \
        --content-type "text/html; charset=utf-8" \
        --delete

    # Next.jsの_next/staticディレクトリ（長期キャッシュ）
    if [ -d "${BUILD_DIR}/_next/static" ]; then
        aws s3 sync ${BUILD_DIR}/_next/static s3://${S3_BUCKET}/_next/static \
            --cache-control "public, max-age=31536000, immutable" \
            --delete
    fi

    # CSS/JSファイル（長期キャッシュ）
    aws s3 sync ${BUILD_DIR} s3://${S3_BUCKET} \
        --exclude "*.html" \
        --exclude "_next/static/*" \
        --include "*.css" \
        --include "*.js" \
        --cache-control "public, max-age=31536000, immutable"

    # 画像ファイル
    aws s3 sync ${BUILD_DIR} s3://${S3_BUCKET} \
        --exclude "*" \
        --include "*.png" \
        --include "*.jpg" \
        --include "*.jpeg" \
        --include "*.gif" \
        --include "*.svg" \
        --include "*.webp" \
        --cache-control "public, max-age=31536000, immutable"

    # その他のファイル
    aws s3 sync ${BUILD_DIR} s3://${S3_BUCKET} \
        --exclude "*.html" \
        --exclude "*.css" \
        --exclude "*.js" \
        --exclude "*.png" \
        --exclude "*.jpg" \
        --exclude "*.jpeg" \
        --exclude "*.gif" \
        --exclude "*.svg" \
        --exclude "*.webp" \
        --exclude "_next/static/*" \
        --cache-control "public, max-age=3600" \
        --delete
else
    echo -e "${YELLOW}Static export not found. Using standard build directory...${NC}"
    # 標準的なNext.jsビルドの場合
    aws s3 sync ./.next/static s3://${S3_BUCKET}/_next/static \
        --cache-control "public, max-age=31536000, immutable" \
        --delete
        
    # publicディレクトリの同期
    if [ -d "./public" ]; then
        aws s3 sync ./public s3://${S3_BUCKET} \
            --cache-control "public, max-age=3600" \
            --delete
    fi
fi

# 5. S3バケットの静的ウェブサイトホスティング設定確認
echo -e "${GREEN}Checking S3 static website configuration...${NC}"
aws s3api get-bucket-website --bucket ${S3_BUCKET} > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo -e "${YELLOW}Setting up S3 static website hosting...${NC}"
    aws s3 website s3://${S3_BUCKET} --index-document index.html --error-document error.html
fi

# 6. CloudFrontキャッシュの無効化
if [ "$CLOUDFRONT_DISTRIBUTION_ID" != "E1234567890ABC" ]; then
    echo -e "${GREEN}Invalidating CloudFront cache...${NC}"
    INVALIDATION_ID=$(aws cloudfront create-invalidation \
        --distribution-id ${CLOUDFRONT_DISTRIBUTION_ID} \
        --paths "/*" \
        --query 'Invalidation.Id' \
        --output text)

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Invalidation created: ${INVALIDATION_ID}${NC}"
        
        # 無効化の進行状況を表示
        echo -e "${BLUE}Waiting for invalidation to complete...${NC}"
        aws cloudfront wait invalidation-completed \
            --distribution-id ${CLOUDFRONT_DISTRIBUTION_ID} \
            --id ${INVALIDATION_ID}
        echo -e "${GREEN}Invalidation completed!${NC}"
    else
        echo -e "${RED}Failed to create CloudFront invalidation${NC}"
    fi
else
    echo -e "${YELLOW}CloudFront distribution ID not set. Skipping cache invalidation.${NC}"
    echo -e "${BLUE}Please update CLOUDFRONT_DISTRIBUTION_ID in this script.${NC}"
fi

# 7. デプロイ完了
echo -e "${GREEN}Deployment completed successfully!${NC}"
echo -e "${BLUE}S3 Bucket URL: http://${S3_BUCKET}.s3-website-ap-northeast-1.amazonaws.com${NC}"
if [ "$CLOUDFRONT_DISTRIBUTION_ID" != "E1234567890ABC" ]; then
    echo -e "${BLUE}CloudFront URL: https://jimotoko.com${NC}"
fi

# 8. デプロイ結果の確認
echo -e "${GREEN}Checking deployment...${NC}"
aws s3 ls s3://${S3_BUCKET}/ --human-readable --summarize