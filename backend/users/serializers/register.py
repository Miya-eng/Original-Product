import os
import requests
from rest_framework import serializers
from ..models import CustomUser
from dotenv import load_dotenv

load_dotenv()

class RegisterSerializer(serializers.ModelSerializer):
    residence_prefecture = serializers.CharField()
    residence_city = serializers.CharField()
    class Meta:
        model = CustomUser
        fields = ('username', 'email', 'password', 'residence_prefecture', 'residence_city')
        extra_kwargs = {'password': {'write_only': True}}

    def validate(self, data):
        prefecture = data.get('residence_prefecture')
        city = data.get('residence_city')
        api_key = os.getenv('GOOGLE_GEOCODING_API_KEY')
        
        # 開発環境では住所バリデーションをスキップ
        if os.getenv('DEBUG', 'False').lower() == 'true' and api_key == 'your-google-api-key-here':
            print(f"⚠️ 開発環境: 住所バリデーションをスキップしました ({prefecture}{city})")
            return data
            
        if not api_key or api_key == 'your-google-api-key-here':
            raise serializers.ValidationError("本番環境では有効なGoogle Geocoding API keyが必要です。")
            
        address = f"{prefecture}{city}"
        url = f"https://maps.googleapis.com/maps/api/geocode/json?address={address}&key={api_key}"
        
        try:
            response = requests.get(url, timeout=10)
            result = response.json()

            if result['status'] != 'OK':
                raise serializers.ValidationError("住所が見つかりませんでした。")
        except requests.RequestException:
            raise serializers.ValidationError("住所の検証中にエラーが発生しました。")
        
        return data
        
    def create(self, validated_data):
        user = CustomUser.objects.create_user(
            username=validated_data['username'],
            email=validated_data['email'],
            password=validated_data['password'],
            residence_prefecture=validated_data['residence_prefecture'],
            residence_city=validated_data['residence_city']
        )
        return user