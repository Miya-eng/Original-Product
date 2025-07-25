# Jimotoko 本番環境データベースセットアップガイド

## 概要
このガイドでは、JimotokoアプリケーションのためのRDS PostgreSQLデータベースの設定方法を説明します。

## 前提条件
- AWS CLI が設定済みであること
- 適切なIAM権限があること（RDS, ECS, Parameter Store, EC2へのアクセス）
- Docker がインストールされていること

## セットアップ手順

### 1. RDS PostgreSQLインスタンスの作成

```bash
# RDSインスタンスとセキュリティグループを作成
./setup-rds.sh
```

このスクリプトは以下を実行します：
- デフォルトVPCの取得
- RDS用セキュリティグループの作成
- DBサブネットグループの作成
- RDS PostgreSQLインスタンス（db.t3.micro）の作成

### 2. AWS Parameter Storeへのシークレット設定

```bash
# データベース接続情報とAPIキーを設定
./setup-aws-secrets.sh
```

以下の情報を入力する必要があります：
- `DATABASE_URL`: PostgreSQL接続文字列
- `SECRET_KEY`: Django秘密キー（自動生成可能）
- `GOOGLE_GEOCODING_API_KEY`: Google APIキー

### 3. データベースマイグレーションの実行

#### ローカル環境でのテスト
```bash
# ローカル環境（SQLite）でマイグレーション
./migrate-database.sh local
```

#### 本番環境でのマイグレーション
```bash
# 環境変数を設定
export DATABASE_URL="postgresql://username:password@endpoint:5432/database"
export SECRET_KEY="your-secret-key"

# 本番環境でマイグレーション
./migrate-database.sh production
```

### 4. ECSタスク定義の更新

`ecs-task-definition.json` ファイルが用意されています。このファイルには以下が含まれます：
- Parameter Storeからのシークレット取得設定
- 適切な環境変数
- ヘルスチェック設定

### 5. GitHub Actionsによる自動デプロイ

GitHub Actionsワークフローが更新され、以下を自動実行します：
- データベースマイグレーション
- ECSタスク定義の登録/更新
- アプリケーションのデプロイ

## データベース設定詳細

### Django設定の変更
`backend/backend/settings.py` が更新され、以下の機能が追加されました：
- 環境変数ベースの設定管理
- 開発環境（SQLite）と本番環境（PostgreSQL）の自動切り替え
- セキュリティ設定の環境変数化

### 依存関係の追加
`requirements.txt` に以下が追加されました：
- `dj-database-url==2.1.0`: DATABASE_URL解析用

### ヘルスチェック機能
新しいヘルスチェックエンドポイント `/api/health/` が追加されました：
- データベース接続確認
- アプリケーション状態確認
- ECSでの活用

## セキュリティ考慮事項

### ネットワークセキュリティ
- RDSインスタンスはプライベートサブネットに配置
- セキュリティグループでアクセス制限
- ECSタスクからのみアクセス可能

### 認証情報管理
- AWS Parameter Store（暗号化）でシークレット管理
- 環境変数へのハードコーディング禁止
- IAMロールベースのアクセス制御

## トラブルシューティング

### よくある問題

#### 1. データベース接続エラー
```bash
# 接続確認
psql "postgresql://username:password@endpoint:5432/database"

# セキュリティグループ確認
aws ec2 describe-security-groups --group-ids sg-xxxxxxxxx
```

#### 2. マイグレーションエラー
```bash
# マイグレーション状態確認
python manage.py showmigrations

# 手動マイグレーション実行
python manage.py migrate --verbosity=2
```

#### 3. ECSデプロイエラー
```bash
# ECSサービス状態確認
aws ecs describe-services --cluster jimotoko-cluster --services jimotoko-backend-service

# タスクログ確認
aws logs get-log-events --log-group-name /ecs/jimotoko-backend
```

## 監視とメンテナンス

### ヘルスチェック
- ECS: `http://localhost:8000/api/health/`
- 外部: `https://api.jimotoko.com/api/health/`

### バックアップ
- RDSの自動バックアップ: 7日間保持
- 手動スナップショット推奨

### パフォーマンス監視
- CloudWatch メトリクス
- RDS Performance Insights
- ECS コンテナ洞察

## コスト最適化

### 現在の設定
- **RDS**: db.t3.micro（フリーティア対象）
- **ストレージ**: 20GB gp2
- **バックアップ**: 7日間

### 月額コスト見積もり
- RDS PostgreSQL (db.t3.micro): 約$15-20
- ストレージ (20GB): 約$2-3
- **合計**: 約$17-23/月

## 次のステップ

1. **本番環境でのテスト実行**
   ```bash
   ./setup-rds.sh
   ./setup-aws-secrets.sh
   ```

2. **GitHub Actionsでのデプロイ**
   - ワークフローを手動実行
   - デプロイ状況の確認

3. **監視設定**
   - CloudWatch アラームの設定
   - ログ監視の確認

4. **セキュリティ監査**
   - IAM権限の最小化
   - ネットワーク設定の確認