# posts/serializers.py

import os
import requests
from rest_framework import serializers
from ..models import Post
from users.serializers.user import UserSerializer
from dotenv import load_dotenv

load_dotenv()

class PostSerializer(serializers.ModelSerializer):

    like_count = serializers.SerializerMethodField()
    is_liked = serializers.SerializerMethodField()
    user = UserSerializer(read_only=True)
    city = serializers.CharField(read_only=True)

    class Meta:
        model = Post
        fields = ['id', 'title', 'body', 'image', 'city', 'user', 'latitude', 'longitude', 'created_at', 'like_count', 'is_liked']
        read_only_fields = ['id', 'created_at', 'user', 'city']

    def validate(self, attrs):
        latitude = attrs.get('latitude')
        longitude = attrs.get('longitude')
        user = self.context['request'].user

        if not latitude or not longitude:
            raise serializers.ValidationError("位置情報（緯度・経度）が必要です。")

        # Google Geocoding APIキーを取得
        api_key = os.getenv('GOOGLE_GEOCODING_API_KEY')
        
        # 開発環境では位置情報バリデーションをスキップ
        if os.getenv('DEBUG', 'False').lower() == 'true' and (not api_key or api_key == 'your-google-api-key-here'):
            print(f"⚠️ 開発環境: 位置情報バリデーションをスキップしました (緯度: {latitude}, 経度: {longitude})")
            # 開発環境では登録市区町村をそのまま使用
            attrs['city'] = user.residence_city
            return attrs
            
        if not api_key or api_key == 'your-google-api-key-here':
            raise serializers.ValidationError("本番環境では有効なGoogle Geocoding API keyが必要です。")

        # Google Geocoding APIを叩く
        geocode_url = (
            f"https://maps.googleapis.com/maps/api/geocode/json"
            f"?latlng={latitude},{longitude}&key={api_key}&language=ja"
        )
        
        try:
            response = requests.get(geocode_url, timeout=10)
            geocode_result = response.json()

            if geocode_result.get('status') != 'OK':
                print(f"⚠️ Geocoding API エラー: {geocode_result.get('status', 'UNKNOWN')}")
                raise serializers.ValidationError("位置情報から市区町村を取得できませんでした。")

            # レスポンスから市区町村（locality）を抽出
            city = None
            results = geocode_result.get('results', [])
            if results:
                for component in results[0].get('address_components', []):
                    if 'locality' in component.get('types', []):
                        city = component['long_name']
                        break

            if not city:
                print(f"⚠️ 市区町村情報が見つかりませんでした。レスポンス: {results[0] if results else 'No results'}")
                raise serializers.ValidationError("市区町村情報を特定できませんでした。")

            # ログインユーザーの登録市区町村と比較
            if user.residence_city != city:
                raise serializers.ValidationError(
                    f"登録市区町村（{user.residence_city}）と、投稿位置の市区町村（{city}）が一致していません。"
                )

            # 市区町村情報を保存
            attrs['city'] = city
            
        except requests.RequestException as e:
            print(f"⚠️ Geocoding API リクエストエラー: {e}")
            raise serializers.ValidationError("位置情報の検証中にエラーが発生しました。")
            
        return attrs
    
    def create(self, validated_data):
        validated_data['user'] = self.context['request'].user
        return super().create(validated_data)
    
    def get_like_count(self, obj):
        return obj.likes.count()

    def get_is_liked(self, obj):
        user = self.context.get('request').user
        if user.is_authenticated:
            return obj.likes.filter(user=user).exists()
        return False
    

