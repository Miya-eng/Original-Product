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

        # ✅ Google Geocoding APIキーを取得
        api_key = os.getenv('GOOGLE_GEOCODING_API_KEY')
        if not api_key:
            raise serializers.ValidationError("Google APIキーが設定されていません。")

        # ✅ Google Geocoding APIを叩く
        geocode_url = (
            f"https://maps.googleapis.com/maps/api/geocode/json"
            f"?latlng={latitude},{longitude}&key={api_key}&language=ja"
        )
        response = requests.get(geocode_url)
        geocode_result = response.json()

        if geocode_result.get('status') != 'OK':
            raise serializers.ValidationError("位置情報から市区町村を取得できませんでした。")

        # ✅ レスポンスから市区町村（locality）を抽出
        city = None
        for component in geocode_result['results'][0]['address_components']:
            if 'locality' in component['types']:
                city = component['long_name']
                break

        if not city:
            raise serializers.ValidationError("市区町村情報を特定できませんでした。")

        # ✅ ログインユーザーの登録市区町村と比較
        if user.residence_city != city:
            raise serializers.ValidationError(
                f"登録市区町村（{user.residence_city}）と、投稿位置の市区町村（{city}）が一致していません。"
            )

        # 市区町村情報を保存
        attrs['city'] = city
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
    

