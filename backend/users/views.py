from django.shortcuts import render
from rest_framework import generics
from rest_framework_simplejwt.views import TokenObtainPairView
from .serializers.register import RegisterSerializer
from .serializers.login import CustomTokenObtainPairSerializer
from .serializers.user import UserSerializer
from .models import CustomUser
from rest_framework.permissions import IsAuthenticated
from rest_framework.views import APIView
from rest_framework.response import Response

class RegisterView(generics.CreateAPIView):
    queryset = CustomUser.objects.all()
    serializer_class = RegisterSerializer

class LoginView(TokenObtainPairView):
    serializer_class = CustomTokenObtainPairSerializer

class MeView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        serializer = UserSerializer(request.user)
        return Response(serializer.data)
