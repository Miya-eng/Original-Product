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
        if not api_key:
            raise serializers.ValidationError("API keyが見つかりません。")
        address = f"{prefecture}{city}"
        url = f"https://maps.googleapis.com/maps/api/geocode/json?address={address}&key={api_key}"
        response = requests.get(url)
        result = response.json()

        if result['status'] != 'OK':
            raise serializers.ValidationError("住所が見つかりませんでした。")
        
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