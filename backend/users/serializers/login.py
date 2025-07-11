# users/serializers/login.py

from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
from django.contrib.auth import authenticate
from rest_framework import serializers

class CustomTokenObtainPairSerializer(TokenObtainPairSerializer):
    def validate(self, attrs): #attrsはリクエストのデータ(validate()に渡される「検証前の」生データ)
        username_or_email = attrs.get('email') or attrs.get('username')
        password = attrs.get('password')

        if not username_or_email or not password:
            raise serializers.ValidationError('メールアドレスとパスワードを入力してください')

        # Django標準の認証機構を使って認証する
        user = authenticate(request=self.context.get('request'), username=username_or_email, password=password)

        if not user:
            raise serializers.ValidationError('メールアドレスまたはパスワードが正しくありません')

        # SimpleJWT標準のvalidateを使ってトークン生成
        data = super().validate({
            'username': user.username,
            'password': password,
        })

        # 必要ならトークンに追加情報を載せる
        data['username'] = user.username

        return data
