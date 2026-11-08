from django.middleware.csrf import get_token
from rest_framework import status
from rest_framework.exceptions import AuthenticationFailed
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.usuarios.models import Usuario
from core.throttling import AuthThrottle, OTPThrottle, StandardAPIThrottle

from .serializers import (
    LoginInputSerializer,
    UsuarioSesionOutputSerializer,
    VerificarOtpInputSerializer,
)
from .services import (
    autenticar_paso_inicial,
    generar_y_enviar_otp_admin,
    verificar_otp_admin_login,
)


def _obtener_ip_cliente(request) -> str | None:
    xff = request.META.get("HTTP_X_FORWARDED_FOR")
    if xff:
        return xff.split(",")[0].strip()
    return request.META.get("REMOTE_ADDR")


class LoginAPIView(APIView):
    """
    POST /api/v1/auth/login/
    Valida documento y contraseña. Si es Empleado, inicia sesión; si es Admin, dispara OTP por correo.
    """

    permission_classes = [AllowAny]
    authentication_classes = []
    throttle_classes = [AuthThrottle]

    def post(self, request):
        serializer = LoginInputSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        resultado = autenticar_paso_inicial(
            request=request,
            doc_usuario=serializer.validated_data["doc_usuario"],
            password_plano=serializer.validated_data["password"],
            ip_address=_obtener_ip_cliente(request),
        )
        get_token(request)

        if resultado["requires_otp"]:
            return Response(
                {
                    "status": "success",
                    "message": "Se ha enviado un código de verificación a tu correo.",
                    "data": {
                        "requires_otp": True,
                        "email_masked": resultado["email_masked"],
                    },
                },
                status=status.HTTP_200_OK,
            )

        usuario = resultado["usuario"]
        return Response(
            {
                "status": "success",
                "message": "Inicio de sesión exitoso.",
                "data": {
                    "requires_otp": False,
                    "redirect_to": resultado["redirect_to"],
                    "user": UsuarioSesionOutputSerializer(usuario).data,
                },
            },
            status=status.HTTP_200_OK,
        )


class VerificarOtpLoginAPIView(APIView):
    """
    POST /api/v1/auth/otp/verificar/
    Verifica el código OTP de 6 dígitos del Administrador y crea la sesión HttpOnly definitiva.
    """

    permission_classes = [AllowAny]
    authentication_classes = []
    throttle_classes = [OTPThrottle]

    def post(self, request):
        serializer = VerificarOtpInputSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        usuario = verificar_otp_admin_login(
            request=request,
            codigo_ingresado=serializer.validated_data["codigo"],
        )
        get_token(request)

        return Response(
            {
                "status": "success",
                "message": "Código verificado. Iniciando sesión...",
                "data": {
                    "redirect_to": "/admin/dashboard",
                    "user": UsuarioSesionOutputSerializer(usuario).data,
                },
            },
            status=status.HTTP_200_OK,
        )


class ReenviarOtpLoginAPIView(APIView):
    """
    POST /api/v1/auth/otp/reenviar/
    Genera y envía un nuevo código OTP al Administrador en pre-login.
    """

    permission_classes = [AllowAny]
    authentication_classes = []
    throttle_classes = [OTPThrottle]

    def post(self, request):
        admin_id = request.session.get("rh_admin_pre_login_uid")
        if not admin_id:
            raise AuthenticationFailed("No hay un proceso de verificación activo.")

        usuario = Usuario.objects.filter(id_usuario=admin_id, id_rol_id=1).first()
        if not usuario:
            request.session.flush()
            raise AuthenticationFailed("No hay un proceso de verificación activo.")

        correo_enmascarado = generar_y_enviar_otp_admin(
            usuario=usuario,
            ip_address=_obtener_ip_cliente(request),
        )

        return Response(
            {
                "status": "success",
                "message": "Código reenviado al correo.",
                "data": {
                    "email_masked": correo_enmascarado,
                },
            },
            status=status.HTTP_200_OK,
        )


class CancelarOtpLoginAPIView(APIView):
    """
    POST /api/v1/auth/otp/cancelar/
    Limpia el estado de pre-login cuando el Administrador cierra el modal OTP.
    """

    permission_classes = [AllowAny]
    authentication_classes = []

    def post(self, request):
        request.session.flush()
        return Response(
            {"status": "success", "message": "Proceso de verificación cancelado."},
            status=status.HTTP_200_OK,
        )


class MeAPIView(APIView):
    """
    GET /api/v1/auth/me/
    Rehidrata la sesión actual leyendo la cookie HttpOnly y asegura el token CSRF.
    Si no hay sesión activa, devuelve data: null sin disparar alertas 403 en consola.
    """

    permission_classes = [AllowAny]
    throttle_classes = [StandardAPIThrottle]

    def get(self, request):
        get_token(request)
        if not isinstance(request.user, Usuario):
            return Response(
                {
                    "status": "success",
                    "data": None,
                },
                status=status.HTTP_200_OK,
            )

        return Response(
            {
                "status": "success",
                "data": UsuarioSesionOutputSerializer(request.user).data,
            },
            status=status.HTTP_200_OK,
        )


class LogoutAPIView(APIView):
    """
    POST /api/v1/auth/logout/
    Destruye la sesión en servidor y limpia la cookie HttpOnly.
    """

    permission_classes = [IsAuthenticated]
    throttle_classes = [StandardAPIThrottle]

    def post(self, request):
        request.session.flush()
        response = Response(
            {
                "status": "success",
                "message": "Sesión cerrada correctamente.",
            },
            status=status.HTTP_200_OK,
        )
        response.delete_cookie("sessionid")
        return response
