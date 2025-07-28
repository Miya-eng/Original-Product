#!/bin/bash

# Local Authentication Test Script
echo "🧪 ローカル認証システムテスト開始..."

# Start backend server in background
echo "🚀 バックエンドサーバーを起動中..."
cd backend
source .venv/bin/activate
python manage.py runserver &
BACKEND_PID=$!
cd ..

# Wait for backend to start
echo "⏳ バックエンドサーバーの起動を待機中..."
sleep 5

# Test signup
echo "📝 サインアップテスト..."
SIGNUP_RESULT=$(curl -s -X POST http://localhost:8000/api/users/register/ \
  -H "Content-Type: application/json" \
  -H "Origin: http://localhost:3000" \
  -d '{
    "username": "localtest",
    "email": "localtest@example.com",
    "password": "testpassword123",
    "residence_prefecture": "神奈川県",
    "residence_city": "横浜市"
  }')

if echo "$SIGNUP_RESULT" | grep -q "username"; then
    echo "✅ サインアップ成功"
else
    echo "❌ サインアップ失敗: $SIGNUP_RESULT"
fi

# Test login
echo "🔐 ログインテスト..."
LOGIN_RESULT=$(curl -s -X POST http://localhost:8000/api/users/login/ \
  -H "Content-Type: application/json" \
  -H "Origin: http://localhost:3000" \
  -d '{
    "username": "localtest@example.com",
    "password": "testpassword123"
  }')

if echo "$LOGIN_RESULT" | grep -q "access"; then
    echo "✅ ログイン成功"
    ACCESS_TOKEN=$(echo "$LOGIN_RESULT" | grep -o '"access":"[^"]*"' | cut -d'"' -f4)
    echo "🎫 アクセストークン取得済み"
else
    echo "❌ ログイン失敗: $LOGIN_RESULT"
fi

# Test authenticated endpoint
if [ ! -z "$ACCESS_TOKEN" ]; then
    echo "👤 認証済みエンドポイントテスト..."
    ME_RESULT=$(curl -s -X GET http://localhost:8000/api/users/me/ \
      -H "Authorization: Bearer $ACCESS_TOKEN" \
      -H "Origin: http://localhost:3000")
    
    if echo "$ME_RESULT" | grep -q "username"; then
        echo "✅ 認証済みエンドポイント成功"
    else
        echo "❌ 認証済みエンドポイント失敗: $ME_RESULT"
    fi
fi

# Test CORS
echo "🌐 CORSテスト..."
CORS_RESULT=$(curl -s -I -H "Origin: http://localhost:3000" \
  -H "Access-Control-Request-Method: POST" \
  http://localhost:8000/api/users/login/)

if echo "$CORS_RESULT" | grep -q "access-control-allow-origin"; then
    echo "✅ CORS設定正常"
else
    echo "❌ CORS設定に問題あり"
fi

# Cleanup
echo "🧹 サーバーを停止中..."
kill $BACKEND_PID 2>/dev/null

echo ""
echo "🎉 ローカル認証システムテスト完了！"
echo ""
echo "📋 手動テスト方法:"
echo "1. バックエンド起動: cd backend && ./run-dev.sh"
echo "2. フロントエンド起動: cd frontend && npm run dev"
echo "3. ブラウザでアクセス: http://localhost:3000/signup"
echo "4. サインアップ後、http://localhost:3000/login でログインテスト"
echo ""
echo "⚠️ 注意: Google Maps API キーが設定されていない場合、マップ機能は動作しません"