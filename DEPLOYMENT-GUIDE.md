# Jimotoko Deployment Guide

## 🚀 ECS/ECR デプロイメント完全ガイド

このガイドに従ってJimotokoアプリケーションをAWS ECS/ECRに完璧にデプロイできます。

## 📋 前提条件

### AWS アカウント設定
- AWS アカウントが設定済み
- 適切なIAMロールが設定済み：
  - `ecsTaskExecutionRole`
  - `ecsTaskRole`
- ECRリポジトリ作成済み: `jimotoko-backend`
- ECSクラスター作成済み: `jimotoko-cluster`

### GitHub Secrets 設定
以下のシークレットをGitHub Repositoryに設定してください：

```
AWS_ACCESS_KEY_ID=your-aws-access-key
AWS_SECRET_ACCESS_KEY=your-aws-secret-key
SUBNET_ID=subnet-xxxxxxxxxxxxxxxx
SECURITY_GROUP_ID=sg-xxxxxxxxxxxxxxxx
```

### AWS Systems Manager Parameter Store
以下のパラメータを設定してください：

```bash
# データベース接続文字列
/jimotoko/database-url

# Django シークレットキー
/jimotoko/secret-key

# Google Geocoding API キー（⚠️新しいキーに変更済み）
/jimotoko/google-geocoding-api-key
```

## 🔧 ローカル開発環境セットアップ

### Backend (Django)

```bash
cd backend

# 仮想環境作成・有効化
python -m venv .venv
source .venv/bin/activate  # macOS/Linux
# または .venv\Scripts\activate  # Windows

# 依存関係インストール
pip install -r requirements.txt

# 環境変数設定
cp .env.production.example .env
# .envファイルを編集して適切な値を設定

# データベースマイグレーション
python manage.py migrate

# 開発サーバー起動
python manage.py runserver
```

### Frontend (Next.js)

```bash
cd frontend

# 依存関係インストール
npm install

# 環境変数設定
cp .env.production.example .env.local
# .env.localファイルを編集

# 開発サーバー起動
npm run dev
```

## 🐳 Docker ローカルテスト

### Backend のみテスト
```bash
cd backend
docker build -t jimotoko-backend .
docker run -p 8000:8000 jimotoko-backend
```

### Docker Compose でフルスタックテスト
```bash
# 開発環境
docker-compose -f docker-compose.dev.yml up

# 本番環境テスト
docker-compose up
```

## 🚀 ECS/ECR デプロイメント

### 自動デプロイ（推奨）

コードをmainブランチにプッシュするだけで自動デプロイされます：

```bash
git add .
git commit -m "Deploy to production"
git push origin main
```

### 手動デプロイ

1. **GitHub Actions から手動実行**
   - GitHub > Actions > "Deploy Backend to ECS" > "Run workflow"
   - GitHub > Actions > "Deploy Frontend to S3 + CloudFront" > "Run workflow"

2. **ローカルから手動ビルド・プッシュ**
```bash
# バックエンドのECRプッシュ
./build-for-ecs.sh

# フロントエンドのS3デプロイ
cd frontend
./deploy-frontend.sh
```

## 📊 リソース構成

### Backend (ECS Fargate)
- **CPU**: 512 units (0.5 vCPU)
- **Memory**: 1024 MB (1 GB)
- **Port**: 8000
- **Health Check**: `/api/health/`
- **Auto Scaling**: 設定可能

### Frontend (S3 + CloudFront)
- **S3 Bucket**: `jimotoko-frontend-s3`
- **CloudFront**: 自動設定
- **Domain**: `jimotoko.com`

### Database
- **Type**: RDS PostgreSQL
- **Version**: 15.13
- **Instance**: db.t3.micro (Free Tier対応)

## 🔐 セキュリティ設定

### 実装済みセキュリティ機能
- ✅ HTTPS/SSL リダイレクト
- ✅ セキュアクッキー設定
- ✅ CSRF保護
- ✅ CORS適切設定
- ✅ ファイルアップロード制限（5MB）
- ✅ XSS保護
- ✅ HSTS ヘッダー

### 本番環境での注意事項
- `DEBUG=False` 必須
- シークレットキーは環境変数で管理
- データベースは外部からアクセス不可に設定

## 🚨 重要：即座に対応が必要

### API キーの再生成
現在のGoogle API キーが露出しているため、すぐに以下を実行してください：

1. Google Cloud Console でAPI キーを再生成
2. AWS Systems Manager Parameter Store を更新
3. フロントエンドの環境変数も更新

## 📈 監視・メンテナンス

### ログ監視
- **ECS**: CloudWatch Logs (`/ecs/jimotoko-backend`)
- **Application**: Django のログレベル設定

### ヘルスチェック
- **Backend**: `https://api.jimotoko.com/api/health/`
- **Frontend**: CloudFront 経由でアクセス確認

### バックアップ
- **Database**: RDS 自動バックアップ
- **Media Files**: S3 バケットの定期バックアップ推奨

## 🔄 アップデート手順

### 通常のアップデート
1. コード変更をcommit
2. mainブランチにpush
3. GitHub Actions が自動でデプロイ

### データベースマイグレーション
1. マイグレーションファイル作成
2. GitHub Actions でのデプロイ時に自動実行
3. 失敗時は手動でECSタスク経由実行可能

### ロールバック
1. GitHub Actions の過去のデプロイを再実行
2. または ECS コンソールで前のタスク定義に戻す

## 🆘 トラブルシューティング

### よくある問題

1. **イメージがプルできない**
   - ECR認証情報を確認
   - IAMロールの権限を確認

2. **データベース接続エラー**
   - RDSセキュリティグループ設定を確認
   - DATABASE_URL の値を確認

3. **CORS エラー**
   - CORS_ALLOWED_ORIGINS の設定を確認
   - フロントエンドのURLが正しく設定されているか確認

4. **画像アップロードが失敗**
   - ファイルサイズ制限（5MB）を確認
   - Next.js の remotePatterns 設定を確認

### ログ確認方法

```bash
# ECS ログ確認
aws logs get-log-events \
  --log-group-name /ecs/jimotoko-backend \
  --log-stream-name ecs/jimotoko-backend/TASK_ID

# ECS タスク状態確認
aws ecs describe-tasks \
  --cluster jimotoko-cluster \
  --tasks TASK_ARN
```

## 📞 サポート

デプロイメントに関する問題が発生した場合：

1. まずログを確認
2. GitHub Actions の実行履歴を確認
3. AWS CloudWatch でリソース状況を確認
4. 必要に応じてIssueを作成

---

**注意**: このガイドは現在のAWSアカウント（162174360270）とリージョン（ap-northeast-1）に基づいています。他の環境にデプロイする場合は適切に調整してください。