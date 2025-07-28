#!/bin/bash

# Django Production Test Script (Gunicorn)
set -e

echo "🐳 本番環境テスト（Gunicorn）を開始..."

# Activate virtual environment
echo "🔧 仮想環境を有効化中..."
source .venv/bin/activate

# Install dependencies
echo "📦 依存関係をインストール中..."
pip install -r requirements.txt --quiet

# Set production-like environment
export DEBUG=False
export SECRET_KEY=test-secret-key-for-production-testing
export ALLOWED_HOSTS=localhost,127.0.0.1
export CORS_ALLOWED_ORIGINS=http://localhost:3000

echo "🗄️ データベースマイグレーション..."
python manage.py migrate

echo "📁 静的ファイル収集..."
python manage.py collectstatic --noinput --clear

echo "✅ Django設定チェック（本番モード）..."
python manage.py check --deploy

echo ""
echo "🚀 Gunicornサーバーを起動中..."
echo "📍 ヘルスチェック: http://localhost:8000/api/health/"
echo "📍 API: http://localhost:8000/api/"
echo ""
echo "⏹️ 停止するには Ctrl+C を押してください"

# Start Gunicorn with production-like settings
gunicorn --bind 0.0.0.0:8000 --workers 3 --timeout 120 --access-logfile - --error-logfile - backend.wsgi:application