#!/bin/bash

# Django Development Server Script
set -e

echo "🚀 Django開発サーバーを起動中..."

# Check if virtual environment exists
if [ ! -d ".venv" ]; then
    echo "⚠️ 仮想環境が見つかりません。作成中..."
    python -m venv .venv
fi

# Activate virtual environment
echo "🔧 仮想環境を有効化中..."
source .venv/bin/activate

# Install dependencies if needed
echo "📦 依存関係をチェック中..."
pip install -r requirements.txt --quiet

# Check if .env file exists
if [ ! -f ".env" ]; then
    echo "⚠️ .envファイルが見つかりません。開発用設定を作成中..."
    cat > .env << EOF
# Development Environment Variables
DEBUG=True
SECRET_KEY=django-insecure-dev-key-for-local-only
ALLOWED_HOSTS=localhost,127.0.0.1
CORS_ALLOWED_ORIGINS=http://localhost:3000

# Leave DATABASE_URL empty to use SQLite for development
# DATABASE_URL=

# Use a placeholder for local development
GOOGLE_GEOCODING_API_KEY=your-google-api-key-here
EOF
fi

# Run migrations
echo "🗄️ データベースマイグレーションを実行中..."
python manage.py migrate

# Collect static files
echo "📁 静的ファイルを収集中..."
python manage.py collectstatic --noinput --clear

# Check Django configuration
echo "✅ Django設定をチェック中..."
python manage.py check

echo ""
echo "🌟 すべての準備が完了しました！"
echo "📍 ヘルスチェック: http://localhost:8000/api/health/"
echo "📍 Admin: http://localhost:8000/admin/"
echo ""
echo "🚀 開発サーバーを起動中..."

# Start development server
python manage.py runserver 0.0.0.0:8000