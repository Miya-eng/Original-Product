from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from .models import CustomUser

class CustomUserAdmin(UserAdmin):
    model = CustomUser
    fieldsets = UserAdmin.fieldsets + (
        ("居住地情報", {
            "fields": ("residence_prefecture", "residence_city")
        }),
    )

admin.site.register(CustomUser, CustomUserAdmin)

