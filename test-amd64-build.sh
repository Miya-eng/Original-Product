#!/bin/bash

# ローカルでAMD64ビルドをテストするスクリプト

echo "=== Backend AMD64プラットフォーム向けのローカルビルドテスト ==="

# Docker Buildxを使用してAMD64イメージをビルド
echo "Backendイメージをビルド中..."
docker buildx build --platform linux/amd64 -t jimotoko-backend:amd64 ./backend

echo "ビルドしたイメージ:"
docker images | grep "jimotoko-backend.*amd64"

echo ""
echo "イメージのアーキテクチャを確認:"
docker inspect jimotoko-backend:amd64 | grep -A 2 "Architecture"

echo ""
echo "フロントエンドはS3 + CloudFrontで配信するため、Dockerイメージは作成しません。"
echo "フロントエンドのビルドは: cd frontend && npm run build"