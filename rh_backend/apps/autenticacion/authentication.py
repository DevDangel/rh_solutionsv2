from rest_framework import exceptions
from rest_framework.authentication import BaseAuthentication, CSRFCheck

from apps.usuarios.models import Usuario


def _enforce_csrf(request) -> None:
    def dummy_get_response(req):
        return None

    check = CSRFCheck(dummy_get_response)
    check.process_request(request)
    reason = check.process_view(request, None, (), {})
    if reason:
        raise exceptions.PermissionDenied(f"Fallo de validación CSRF: {reason}")


class RHSessionAuthentication(BaseAuthentication):
    """
    Autenticación basada en sesión HttpOnly de servidor (tabla django_session).
    Verifica en cada petición que el usuario exista y no esté desvinculado (id_estado = 2).
    """

    def authenticate(self, request):
        http_request = getattr(request, "_request", request)
        id_usuario = http_request.session.get("rh_auth_user_id")
        if not id_usuario:
            return None

        usuario = (
            Usuario.objects.select_related("id_rol", "id_estado", "id_cargo")
            .filter(id_usuario=id_usuario)
            .first()
        )

        if not usuario:
            http_request.session.flush()
            return None

        # Equivalente a CheckUsuarioEstado.php del legacy: si está desvinculado (2), expulsa la sesión
        if usuario.id_estado_id == 2:
            http_request.session.flush()
            raise exceptions.AuthenticationFailed(
                "Cuenta inhabilitada. Contáctate con el administrador."
            )

        if http_request.method not in ("GET", "HEAD", "OPTIONS", "TRACE"):
            _enforce_csrf(http_request)

        return (usuario, None)

    def authenticate_header(self, request) -> str:
        return "Session"

