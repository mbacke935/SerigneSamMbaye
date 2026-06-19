from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView
from drf_spectacular.views import SpectacularAPIView, SpectacularSwaggerView, SpectacularRedocView

admin.site.site_header = 'Serigne Sam Mbaye — Administration'
admin.site.site_title = 'Espace Administration'
admin.site.index_title = 'Tableau de bord'

urlpatterns = [
    # Admin
    path('gestion/', admin.site.urls),

    # Auth JWT
    path('api/token/', TokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('api/token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),

    # API endpoints
    path('api/users/', include('apps.users.urls')),
    path('api/albums/', include('apps.albums.urls')),
    path('api/biographies/', include('apps.biographies.urls')),
    path('api/audios/', include('apps.audios.urls')),
    path('api/videos/', include('apps.videos.urls')),
    path('api/citations/', include('apps.citations.urls')),
    path('api/favorites/', include('apps.favorites.urls')),
    path('api/search/', include('apps.search.urls')),

    # Documentation Swagger / ReDoc
    path('api/schema/', SpectacularAPIView.as_view(), name='schema'),
    path('api/docs/', SpectacularSwaggerView.as_view(url_name='schema'), name='swagger-ui'),
    path('api/redoc/', SpectacularRedocView.as_view(url_name='schema'), name='redoc'),
] + static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
