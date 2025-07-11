from django.shortcuts import render
# posts/views.py

from rest_framework import generics, permissions, serializers, status
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.parsers import MultiPartParser, FormParser
from .models import Post, Comment, PostLike, CommentLike
from .serializers.post import PostSerializer
from .serializers.comment import CommentSerializer

class PostCreateView(generics.CreateAPIView):
    queryset = Post.objects.all()
    serializer_class = PostSerializer
    permission_classes = [permissions.IsAuthenticated]
    parser_classes = (MultiPartParser, FormParser)

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)

# 投稿一覧取得API（誰でも見れる）
class PostListView(generics.ListAPIView):
    queryset = Post.objects.all().order_by('-created_at')  # 最新順
    serializer_class = PostSerializer
    permission_classes = [permissions.AllowAny]  # 認証不要

# 自分の投稿一覧API（認証必須）
class MyPostListView(generics.ListAPIView):
    serializer_class = PostSerializer
    permission_classes = [permissions.IsAuthenticated]  # ログイン必須

    def get_queryset(self):
        return Post.objects.filter(user=self.request.user).order_by('-created_at')
    
# 投稿編集・削除API（本人のみ）
class PostDetailView(generics.RetrieveUpdateDestroyAPIView):
    queryset = Post.objects.all()
    serializer_class = PostSerializer
    permission_classes = [permissions.IsAuthenticated]

    def perform_update(self, serializer):
        if self.request.user != self.get_object().user:
            raise serializers.ValidationError("あなた自身の投稿だけ編集できます。")
        serializer.save()

    def perform_destroy(self, instance):
        if self.request.user != instance.user:
            raise serializers.ValidationError("あなた自身の投稿だけ削除できます。")
        instance.delete()

# 特定投稿に対するコメント一覧取得
class CommentListView(generics.ListAPIView):
    serializer_class = CommentSerializer
    permission_classes = [permissions.AllowAny]

    def get_queryset(self):
        post_id = self.kwargs['post_id']
        return Comment.objects.filter(post_id=post_id).order_by('-created_at')

# コメント作成（認証必須）
class CommentCreateView(generics.CreateAPIView):
    serializer_class = CommentSerializer
    permission_classes = [permissions.IsAuthenticated]

    def perform_create(self, serializer):
        post_id = self.kwargs['post_id']
        serializer.save(user=self.request.user, post_id=post_id)

# コメント詳細（編集・削除）ビュー
class CommentDetailView(generics.RetrieveUpdateDestroyAPIView):
    queryset = Comment.objects.all()
    serializer_class = CommentSerializer
    permission_classes = [permissions.IsAuthenticated]

    def perform_update(self, serializer):
        comment = self.get_object()
        if comment.user != self.request.user:
            raise serializers.ValidationError("自分のコメントのみ編集できます。")
        serializer.save()

    def perform_destroy(self, instance):
        if instance.user != self.request.user:
            raise serializers.ValidationError("自分のコメントのみ削除できます。")
        instance.delete()

# いいね機能の実装
class TogglePostLikeView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, post_id):
        post = Post.objects.get(id=post_id)
        user = request.user
        like, created = PostLike.objects.get_or_create(post=post, user=user)
        if not created:
            like.delete()
            return Response({"status": "unliked"})
        return Response({"status": "liked"})

class ToggleCommentLikeView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, comment_id):
        comment = Comment.objects.get(id=comment_id)
        user = request.user
        like, created = CommentLike.objects.get_or_create(comment=comment, user=user)
        if not created:
            like.delete()
            return Response({"status": "unliked"})
        return Response({"status": "liked"})
