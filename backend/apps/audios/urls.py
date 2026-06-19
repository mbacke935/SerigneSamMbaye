from rest_framework.routers import DefaultRouter
from .views import AudioViewSet

router = DefaultRouter()
router.register('', AudioViewSet, basename='audio')

urlpatterns = router.urls
