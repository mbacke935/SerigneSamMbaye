from rest_framework.routers import DefaultRouter

from .views import AlbumViewSet

router = DefaultRouter()
router.register('', AlbumViewSet, basename='album')

urlpatterns = router.urls
