#!/bin/bash

# Post Functionality Test Script
echo "📝 投稿機能テスト開始..."

cd backend

# Check if servers are running
echo "🔍 サーバー状態確認..."
if ! curl -s http://localhost:8000/api/health/ > /dev/null; then
    echo "❌ バックエンドサーバーが起動していません"
    echo "🚀 バックエンドサーバーを起動中..."
    source .venv/bin/activate
    python manage.py runserver &
    BACKEND_PID=$!
    sleep 5
fi

if ! curl -s http://localhost:3000 > /dev/null; then
    echo "❌ フロントエンドサーバーが起動していません"
    echo "🚀 フロントエンドサーバーを起動中..."
    cd ../frontend
    npm run dev &
    FRONTEND_PID=$!
    cd ../backend
    sleep 5
fi

echo "✅ サーバー起動確認完了"
echo ""

# Get access token
echo "🔐 認証トークン取得中..."
LOGIN_RESULT=$(curl -s -X POST http://localhost:8000/api/users/login/ \
  -H "Content-Type: application/json" \
  -H "Origin: http://localhost:3000" \
  -d '{"username": "test@example.com", "password": "testpassword123"}')

if echo "$LOGIN_RESULT" | grep -q "access"; then
    ACCESS_TOKEN=$(echo "$LOGIN_RESULT" | grep -o '"access":"[^"]*"' | cut -d'"' -f4)
    echo "✅ 認証成功"
else
    echo "❌ 認証失敗: $LOGIN_RESULT"
    exit 1
fi

echo ""

# Test post creation
echo "📝 投稿作成テスト..."

# Test 1: Valid post in user's city (Shibuya)
echo "テスト 1: 渋谷区での投稿（正常系）"
POST_RESULT_1=$(curl -s -X POST http://localhost:8000/api/posts/ \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Origin: http://localhost:3000" \
  -F "title=渋谷カフェ" \
  -F "body=素敵なカフェを見つけました" \
  -F "latitude=35.6598" \
  -F "longitude=139.7006")

if echo "$POST_RESULT_1" | grep -q "id"; then
    echo "✅ 渋谷区での投稿成功"
    POST_ID_1=$(echo "$POST_RESULT_1" | grep -o '"id":[0-9]*' | cut -d':' -f2)
    echo "   投稿ID: $POST_ID_1"
else
    echo "❌ 渋谷区での投稿失敗: $POST_RESULT_1"
fi

echo ""

# Test 2: Post in different city (should fail with validation)
echo "テスト 2: 新宿区での投稿（エラー系）"
POST_RESULT_2=$(curl -s -X POST http://localhost:8000/api/posts/ \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Origin: http://localhost:3000" \
  -F "title=新宿テスト" \
  -F "body=これは失敗するはず" \
  -F "latitude=35.6896" \
  -F "longitude=139.6917")

if echo "$POST_RESULT_2" | grep -q "一致していません"; then
    echo "✅ 市区町村不一致エラーが正常に動作"
else
    echo "❌ 期待されるエラーが発生しませんでした: $POST_RESULT_2"
fi

echo ""

# Test 3: Get posts
echo "テスト 3: 投稿一覧取得"
POSTS_RESULT=$(curl -s -X GET http://localhost:8000/api/posts/ \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Origin: http://localhost:3000")

if echo "$POSTS_RESULT" | grep -q "results"; then
    echo "✅ 投稿一覧取得成功"
    POST_COUNT=$(echo "$POSTS_RESULT" | grep -o '"count":[0-9]*' | cut -d':' -f2)
    echo "   投稿数: $POST_COUNT"
else
    echo "❌ 投稿一覧取得失敗: $POSTS_RESULT"
fi

echo ""

# Check Google Maps API functionality
echo "🗺️ Google Maps API テスト..."
API_KEY=$(grep NEXT_PUBLIC_GOOGLE_MAPS_API_KEY ../frontend/.env.local | cut -d'=' -f2)
if [ ! -z "$API_KEY" ] && [ "$API_KEY" != "your-google-api-key-here" ]; then
    echo "✅ フロントエンド Google Maps API キー設定済み: ${API_KEY:0:20}..."
else
    echo "❌ フロントエンド Google Maps API キーが設定されていません"
fi

BACKEND_API_KEY=$(grep GOOGLE_GEOCODING_API_KEY .env | cut -d'=' -f2)
if [ ! -z "$BACKEND_API_KEY" ] && [ "$BACKEND_API_KEY" != "your-google-api-key-here" ]; then
    echo "✅ バックエンド Google Geocoding API キー設定済み: ${BACKEND_API_KEY:0:20}..."
else
    echo "❌ バックエンド Google Geocoding API キーが設定されていません"
fi

echo ""
echo "🎉 投稿機能テスト完了！"
echo ""
echo "📋 手動テスト方法:"
echo "1. ブラウザで http://localhost:3000/login にアクセス"
echo "2. test@example.com / testpassword123 でログイン"
echo "3. http://localhost:3000/posts/new で投稿作成"
echo "4. 場所は渋谷区内のスポットを選択してください"
echo ""
echo "⚠️ 注意事項:"
echo "- 投稿は登録した市区町村内でのみ可能です"
echo "- Google Places Autocompleteで場所を選択する必要があります"
echo "- 画像は5MB以下のファイルのみアップロード可能です"

# Cleanup (optional)
if [ ! -z "$BACKEND_PID" ]; then
    echo "🧹 起動したバックエンドサーバーを停止中..."
    kill $BACKEND_PID 2>/dev/null
fi

if [ ! -z "$FRONTEND_PID" ]; then
    echo "🧹 起動したフロントエンドサーバーを停止中..."
    kill $FRONTEND_PID 2>/dev/null
fi