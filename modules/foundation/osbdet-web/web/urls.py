"""web URL Configuration

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/3.2/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  path('', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  path('', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.urls import include, path
    2. Add a URL to urlpatterns:  path('blog/', include('blog.urls'))
"""
from django.conf import settings
from django.contrib import admin
from django.urls import include, path
from rest_framework import routers
from core import views as core_views
from django.conf.urls.static import static

router = routers.DefaultRouter()
router.register(r'commands', core_views.CommandViewSet)

# Wire up our API using automatic URL routing.
# Additionally, we include login URLs for the browsable API.
urlpatterns = [
    path("", include("frontend.urls")),
    path("admin/", admin.site.urls),
    path('api/v1/', include(router.urls)),    
    path('api/v1/command/', core_views.command),
    path('api-auth/', include('rest_framework.urls', namespace = 'rest_framework'))
] + static(settings.STATIC_URL, document_root = settings.STATIC_ROOT)
