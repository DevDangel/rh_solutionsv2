from django.core.cache import cache
from django.db import connection
from rest_framework import status
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.views import APIView


class HealthCheckAPIView(APIView):
    """
    Endpoint de verificación de salud de la infraestructura (PostgreSQL 17 + Redis 7).
    Ruta: GET /api/v1/health/
    """

    permission_classes = [AllowAny]
    authentication_classes = []

    def get(self, request):
        estado_bd = "ok"
        estado_redis = "ok"

        try:
            with connection.cursor() as cursor:
                cursor.execute("SELECT 1;")
                cursor.fetchone()
        except Exception:
            estado_bd = "error"

        try:
            cache.set("rh_healthcheck_ping", "pong", timeout=10)
            if cache.get("rh_healthcheck_ping") != "pong":
                estado_redis = "error"
        except Exception:
            estado_redis = "error"

        saludable = estado_bd == "ok" and estado_redis == "ok"
        return Response(
            {
                "status": "success" if saludable else "error",
                "message": "RH Solutions v2 API operativa."
                if saludable
                else "Fallo en servicios de infraestructura.",
                "data": {
                    "service": "rh_backend",
                    "database_postgres_17": estado_bd,
                    "cache_redis_7": estado_redis,
                },
            },
            status=status.HTTP_200_OK
            if saludable
            else status.HTTP_503_SERVICE_UNAVAILABLE,
        )
