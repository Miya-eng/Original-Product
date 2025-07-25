#!/bin/bash

# データベースマイグレーション実行スクリプト
# Usage: ./migrate-database.sh [local|production]

set -e

ENVIRONMENT=${1:-local}

echo "🚀 データベースマイグレーションを開始します (環境: $ENVIRONMENT)"

# 環境に応じた設定
if [ "$ENVIRONMENT" = "production" ]; then
    # 本番環境の場合、環境変数が設定されているかチェック
    if [ -z "$DATABASE_URL" ]; then
        echo "❌ エラー: DATABASE_URL 環境変数が設定されていません"
        echo "例: export DATABASE_URL=postgresql://user:password@host:5432/dbname"
        exit 1
    fi
    
    if [ -z "$SECRET_KEY" ]; then
        echo "❌ エラー: SECRET_KEY 環境変数が設定されていません"
        exit 1
    fi
    
    echo "✅ 本番環境変数の確認完了"
    
    # 本番環境設定
    export DEBUG=False
    export ALLOWED_HOSTS="api.jimotoko.com,localhost"
    export CORS_ALLOWED_ORIGINS="https://jimotoko.com,http://localhost:3000"
    
elif [ "$ENVIRONMENT" = "local" ]; then
    echo "✅ ローカル開発環境で実行します"
    # ローカル環境では SQLite を使用
    unset DATABASE_URL
else
    echo "❌ エラー: 無効な環境指定です。'local' または 'production' を指定してください"
    exit 1
fi

# Djangoプロジェクトのディレクトリに移動
cd backend

echo "📋 現在のデータベース設定を確認中..."
python manage.py showmigrations --verbosity=1

echo "🔄 マイグレーションファイルを作成中..."
python manage.py makemigrations

echo "📊 マイグレーション計画を表示中..."
python manage.py showmigrations

echo "⚡ マイグレーションを実行中..."
python manage.py migrate --verbosity=2

if [ "$ENVIRONMENT" = "production" ]; then
    echo "📦 静的ファイルを収集中..."
    python manage.py collectstatic --noinput --verbosity=1
fi

echo "👤 スーパーユーザーを作成しますか? (y/N)"
read -r CREATE_SUPERUSER

if [ "$CREATE_SUPERUSER" = "y" ] || [ "$CREATE_SUPERUSER" = "Y" ]; then
    echo "👤 スーパーユーザーを作成中..."
    python manage.py createsuperuser
fi

echo "🧪 データベース接続テストを実行中..."
python manage.py check --database default

echo ""
echo "🎉 データベースマイグレーション完了!"
echo ""

if [ "$ENVIRONMENT" = "production" ]; then
    echo "📋 本番環境セットアップ完了チェックリスト:"
    echo "  ✅ RDS PostgreSQL接続確認"
    echo "  ✅ マイグレーション実行"
    echo "  ✅ 静的ファイル収集"
    echo ""
    echo "🔧 次のステップ:"
    echo "  1. ECSタスク定義に環境変数を設定"
    echo "  2. アプリケーションをデプロイ"
    echo "  3. ヘルスチェックの確認"
else
    echo "📋 ローカル環境セットアップ完了!"
    echo "  データベース: SQLite (db.sqlite3)"
    echo ""
    echo "🚀 開発サーバーを起動:"
    echo "  python manage.py runserver"
fi