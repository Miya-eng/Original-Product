from rest_framework import serializers
from ..models import Comment

class CommentSerializer(serializers.ModelSerializer):
    like_count = serializers.SerializerMethodField()
    is_liked = serializers.SerializerMethodField()
    user = serializers.StringRelatedField(read_only=True)  # ユーザー名表示用

    class Meta:
        model = Comment
        fields = ['id', 'post', 'user', 'text', 'created_at', 'like_count', 'is_liked']
        read_only_fields = ['id', 'user', 'created_at', 'post']

    def get_like_count(self, obj):
        return obj.likes.count()

    def get_is_liked(self, obj):
        user = self.context.get('request').user
        if user.is_authenticated:
            return obj.likes.filter(user=user).exists()
        return False