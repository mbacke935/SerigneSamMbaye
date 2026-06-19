from rest_framework.routers import DefaultRouter
from .views import BiographieViewSet

router = DefaultRouter()
router.register('', BiographieViewSet, basename='biographie')

urlpatterns = router.urls
