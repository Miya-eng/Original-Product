from rest_framework import serializers
from ..models import CustomUser  # カスタムユーザーの場合

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = CustomUser
        fields = (
            'id',
            'username',
            'email',
            'residence_prefecture',
            'residence_city',
            # 必要に応じて追加: 'date_joined', 'last_login', など
        )
