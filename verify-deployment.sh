#!/bin/bash

# Jimotoko Deployment Verification Script
# このスクリプトでローカル環境とデプロイメント準備状況を確認

set -e

echo "🔍 Jimotoko デプロイメント検証を開始..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Functions
check_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

check_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

check_error() {
    echo -e "${RED}❌ $1${NC}"
}

echo "📋 必要なファイルの存在確認..."

# Check essential files
files_to_check=(
    "backend/Dockerfile"
    "backend/requirements.txt"
    "backend/manage.py"
    "backend/backend/settings.py"
    "frontend/package.json"
    "frontend/next.config.ts"
    "docker-compose.yml"
    "ecs-task-definition.json"
    ".github/workflows/deploy-backend-to-ecs.yml"
    ".github/workflows/deploy-frontend.yml"
)

for file in "${files_to_check[@]}"; do
    if [ -f "$file" ]; then
        check_success "$file が存在します"
    else
        check_error "$file が見つかりません"
        exit 1
    fi
done

echo ""
echo "🔧 バックエンド環境確認..."

# Check Python environment
cd backend

if [ ! -d ".venv" ]; then
    check_warning "仮想環境が見つかりません。作成します..."
    python -m venv .venv
fi

# Activate virtual environment
source .venv/bin/activate

# Check if requirements are installed
if pip show django > /dev/null 2>&1; then
    check_success "Django がインストールされています"
else
    check_warning "依存関係をインストールします..."
    pip install -r requirements.txt
fi

# Check Django configuration
if python manage.py check --deploy > /dev/null 2>&1; then
    check_success "Django 設定確認 OK"
else
    check_warning "Django設定に注意点があります（本番環境変数が設定されていない可能性）"
fi

# Check for development database
if [ -f "db.sqlite3" ]; then
    check_warning "開発用データベースファイルが存在します（本番では不要）"
fi

# Check for Python cache files
if find . -name "__pycache__" -type d -not -path "*/.venv/*" | grep -q .; then
    check_warning "Python キャッシュファイルが存在します"
    echo "クリーンアップを実行..."
    find . -name "__pycache__" -type d -not -path "*/.venv/*" -exec rm -rf {} + 2>/dev/null || true
    check_success "Python キャッシュファイルをクリーンアップしました"
fi

cd ..

echo ""
echo "🎨 フロントエンド環境確認..."

cd frontend

# Check Node.js and npm
if command -v node > /dev/null 2>&1; then
    NODE_VERSION=$(node --version)
    check_success "Node.js $NODE_VERSION がインストールされています"
else
    check_error "Node.js がインストールされていません"
    exit 1
fi

# Check if node_modules exists
if [ -d "node_modules" ]; then
    check_success "node_modules が存在します"
else
    check_warning "依存関係をインストールします..."
    npm install
fi

# Check if build works
if npm run build > /dev/null 2>&1; then
    check_success "フロントエンドビルド OK"
    
    # Check if out directory exists (Next.js static export)
    if [ -d "out" ]; then
        check_success "静的エクスポート用 out/ ディレクトリが生成されました"
    fi
else
    check_error "フロントエンドビルドに失敗しました"
fi

cd ..

echo ""
echo "🐳 Docker 設定確認..."

# Check Docker
if command -v docker > /dev/null 2>&1; then
    check_success "Docker がインストールされています"
    
    # Check if Docker is running
    if docker info > /dev/null 2>&1; then
        check_success "Docker が実行中です"
    else
        check_warning "Docker が実行されていません"
    fi
else
    check_warning "Docker がインストールされていません（ローカル開発時のみ必要）"
fi

# Check Dockerfile
if [ -f "backend/Dockerfile" ]; then
    # Check for multi-platform build support
    if grep -q "platform=linux/amd64" backend/Dockerfile; then
        check_success "Dockerfile はECS用プラットフォーム指定済み"
    else
        check_warning "Dockerfile にプラットフォーム指定がありません"
    fi
fi

echo ""
echo "🚀 GitHub Actions ワークフロー確認..."

# Check workflow files
workflow_files=(
    ".github/workflows/deploy-backend-to-ecs.yml"
    ".github/workflows/deploy-frontend.yml"
)

for workflow in "${workflow_files[@]}"; do
    if [ -f "$workflow" ]; then
        if grep -q "workflow_dispatch" "$workflow"; then
            check_success "$workflow は手動実行可能です"
        fi
        
        if grep -q "push:" "$workflow" && ! grep -q "# push:" "$workflow"; then
            check_success "$workflow は自動デプロイ有効です"
        else
            check_warning "$workflow は自動デプロイが無効です"
        fi
    fi
done

echo ""
echo "📊 ECS タスク定義確認..."

if [ -f "ecs-task-definition.json" ]; then
    # Check CPU and Memory allocation
    CPU=$(grep -o '"cpu": "[^"]*"' ecs-task-definition.json | cut -d'"' -f4)
    MEMORY=$(grep -o '"memory": "[^"]*"' ecs-task-definition.json | cut -d'"' -f4)
    
    check_success "ECS リソース設定: CPU=$CPU, Memory=${MEMORY}MB"
    
    # Check health check
    if grep -q "healthCheck" ecs-task-definition.json; then
        check_success "ヘルスチェック設定済み"
    else
        check_warning "ヘルスチェック設定がありません"
    fi
fi

echo ""
echo "🔐 セキュリティ設定確認..."

# Check for hardcoded secrets
echo "機密情報チェック中..."

# Check for exposed API keys (except in example files)
if grep -r "AIzaSy" . --exclude-dir=.git --exclude="*.example" --exclude="*.md" | grep -v "your-new-google" > /dev/null 2>&1; then
    check_error "APIキーがハードコードされている可能性があります"
    grep -r "AIzaSy" . --exclude-dir=.git --exclude="*.example" --exclude="*.md" | head -5
else
    check_success "ハードコードされたAPIキーは見つかりませんでした"
fi

# Check Django SECRET_KEY
if grep -q "django-insecure" backend/backend/settings.py; then
    check_warning "Django のデフォルトSECRET_KEYが使用されています（本番では環境変数で上書き必要）"
fi

echo ""
echo "📁 不要なファイル確認..."

# Check for unnecessary files
unnecessary_files=(
    "backend/db.sqlite3"
    "backend/db.sqlite3-journal"
)

found_unnecessary=false
for file in "${unnecessary_files[@]}"; do
    if [ -f "$file" ]; then
        check_warning "不要なファイル: $file"
        found_unnecessary=true
    fi
done

if [ "$found_unnecessary" = false ]; then
    check_success "不要なファイルは見つかりませんでした"
fi

echo ""
echo "✨ 検証完了！"

echo ""
echo "📋 デプロイメント前チェックリスト:"
echo "   □ AWS認証情報がGitHub Secretsに設定済み"
echo "   □ AWS Systems Manager Parameter Storeにシークレット設定済み"
echo "   □ ECRリポジトリ 'jimotoko-backend' が作成済み"
echo "   □ ECSクラスター 'jimotoko-cluster' が作成済み"
echo "   □ RDSデータベースが設定済み"
echo "   □ S3バケット 'jimotoko-frontend-s3' が作成済み"
echo "   □ Google API キーを新しいものに再生成済み"

echo ""
echo "🚀 準備完了！mainブランチにpushするとデプロイが開始されます。"
echo "   または GitHub Actions から手動でワークフローを実行してください。"

echo ""
echo "📖 詳細な手順は DEPLOYMENT-GUIDE.md を確認してください。"