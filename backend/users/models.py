from django.contrib.auth.models import AbstractUser
from django.db import models

class CustomUser(AbstractUser):
    residence_prefecture = models.CharField(max_length=50)
    residence_city = models.CharField(max_length=50)

    def __str__(self):
        return self.username