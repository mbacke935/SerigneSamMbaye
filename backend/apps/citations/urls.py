from rest_framework.routers import DefaultRouter
from .views import CitationViewSet

router = DefaultRouter()
router.register('', CitationViewSet, basename='citation')

urlpatterns = router.urls
