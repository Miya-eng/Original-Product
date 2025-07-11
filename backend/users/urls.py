from django.urls import path
from .views import RegisterView, LoginView, MeView
from rest_framework_simplejwt.views import TokenRefreshView

urlpatterns = [
    path('register/', RegisterView.as_view(), name='register'),
    path('login/', LoginView.as_view(), name='login'),  # ログイン
    path('me/', MeView.as_view(), name='me'), # ユーザー情報取得
    path('token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),  # トークン更新
]

#/api/token/ に username と password をPOSTするとaccess_token と refresh_token が返ってくる