from rest_framework.exceptions import PermissionDenied
from rest_framework.permissions import BasePermission


class IsAdminRole(BasePermission):
    """Permite acceso exclusivo al rol Administrador / Talento Humano (id_rol = 1)."""

    message = "No tienes permisos de administrador para realizar esta acción."

    def has_permission(self, request, view) -> bool:
        usuario = getattr(request, "user", None)
        return bool(
            usuario
            and usuario.is_authenticated
            and getattr(usuario, "id_rol_id", None) == 1
        )


class IsEmpleadoOrJefeRole(BasePermission):
    """Permite acceso a Empleados (id_rol = 2) y Jefes Inmediatos (id_rol = 3)."""

    message = "Esta sección es exclusiva para colaboradores activos."

    def has_permission(self, request, view) -> bool:
        usuario = getattr(request, "user", None)
        return bool(
            usuario
            and usuario.is_authenticated
            and getattr(usuario, "id_rol_id", None) in (2, 3)
        )


def verificar_acceso_recurso(
    usuario,
    id_propietario_recurso: int,
    permitir_admin: bool = True,
) -> None:
    """
    Receta anti-IDOR obligatoria (.agents/rules/security_rules.md sección 2.2).
    Verifica que el recurso pertenezca al usuario de la sesión o sea Administrador.
    """
    es_admin = permitir_admin and getattr(usuario, "id_rol_id", None) == 1
    es_propietario = getattr(usuario, "id_usuario", None) == id_propietario_recurso

    if not (es_propietario or es_admin):
        raise PermissionDenied(
            "No tienes autorización para acceder o modificar este registro."
        )
