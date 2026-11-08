from django.urls import include, path

from core.views import HealthCheckAPIView

urlpatterns = [
    path("", HealthCheckAPIView.as_view(), name="api-root"),
    path("api/v1/health/", HealthCheckAPIView.as_view(), name="api-health-check"),
    path("api/v1/auth/", include("apps.autenticacion.urls")),
]
