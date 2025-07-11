from django.urls import path
from .views import PostCreateView, PostListView, MyPostListView, PostDetailView, CommentListView, CommentCreateView, CommentDetailView, TogglePostLikeView, ToggleCommentLikeView

urlpatterns = [
    path('', PostCreateView.as_view(), name='post-create'),
    path('list/', PostListView.as_view(), name='post-list'),
    path('myposts/', MyPostListView.as_view(), name='my-post-list'),
    path('<int:pk>/', PostDetailView.as_view(), name='post-detail'),  # 編集/削除
    path('<int:post_id>/comments/', CommentListView.as_view(), name='comment-list'),
    path('<int:post_id>/comments/add/', CommentCreateView.as_view(), name='comment-create'),
    path('comments/<int:pk>/', CommentDetailView.as_view(), name='comment-detail'),
    path('<int:post_id>/like/', TogglePostLikeView.as_view(), name='post-like-toggle'),
    path('comments/<int:comment_id>/like/', ToggleCommentLikeView.as_view(), name='comment-like-toggle'),
]
