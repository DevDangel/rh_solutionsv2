import logging
import secrets
from datetime import timedelta

import bcrypt
from django.conf import settings
from django.contrib.auth.hashers import check_password, make_password
from django.core.mail import EmailMultiAlternatives
from django.db import transaction
from django.utils import timezone
from rest_framework.exceptions import AuthenticationFailed, PermissionDenied, ValidationError

from apps.autenticacion.models import UserOtpCode
from apps.usuarios.models import Usuario

logger = logging.getLogger(__name__)

MAX_OTP_INTENTOS = 3
OTP_EXPIRACION_MINUTOS = 5


def enmascarar_correo(correo: str) -> str:
    if not correo or "@" not in correo:
        return "correo..."
    parte_local, dominio = correo.split("@", 1)
    if len(parte_local) <= 2:
        return f"*{parte_local[-1:]}@{dominio}"
    return f"{parte_local[:2]}{'*' * (len(parte_local) - 2)}@{dominio}"


def verificar_credenciales_usuario(usuario: Usuario, password_plano: str) -> bool:
    """
    Verifica la contraseña contra Argon2id/PBKDF2 de Django o contra hashes $2y$ heredados de PHP Laravel.
    Si un hash $2y$ de Laravel es válido, lo actualiza automáticamente a Argon2id.
    """
    hash_guardado = usuario.password or ""

    if hash_guardado.startswith(("$2y$", "$2a$", "$2b$")):
        hash_normalizado = ("$2b$" + hash_guardado[4:]).encode("utf-8")
        try:
            es_valido = bcrypt.checkpw(password_plano.encode("utf-8"), hash_normalizado)
        except ValueError:
            return False

        if es_valido:
            usuario.password = make_password(password_plano)
            usuario.save(update_fields=["password", "updated_at"])
        return es_valido

    return check_password(password_plano, hash_guardado)


def _construir_html_correo_otp(codigo: str, minutos: int = OTP_EXPIRACION_MINUTOS) -> str:
    anio_actual = timezone.now().year
    return f"""<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Código de Verificación OTP - RH Solutions</title>
</head>
<body style="font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f4f4f4; margin: 0; padding: 20px; line-height: 1.6;">
    <div style="max-width: 600px; margin: 0 auto; background-color: #ffffff; border-radius: 10px; box-shadow: 0 0 20px rgba(0,0,0,0.1); overflow: hidden;">
        <div style="background: #02024D; color: white; padding: 30px; text-align: center;">
            <h1 style="margin: 0; font-size: 24px; font-weight: 600;">Verificación de Acceso</h1>
        </div>
        <div style="padding: 40px 30px;">
            <div style="color: #333; font-size: 18px; margin-bottom: 20px;">Hola Administrador,</div>
            <div style="color: #666; font-size: 16px; margin-bottom: 30px;">
                Se ha iniciado una sesión en tu cuenta de RH Solutions. Para garantizar la seguridad, necesitamos que verifiques tu identidad con el siguiente código.
            </div>
            <div style="background: #02024D; border-radius: 10px; padding: 30px; text-align: center; margin: 30px 0;">
                <div style="color: white; font-size: 14px; font-weight: 600; margin-bottom: 10px; text-transform: uppercase; letter-spacing: 1px;">
                    Tu código de verificación es:
                </div>
                <div style="background-color: white; color: #333; font-size: 32px; font-weight: bold; padding: 15px 30px; border-radius: 8px; letter-spacing: 8px; display: inline-block;">
                    {codigo}
                </div>
            </div>
            <div style="background-color: #fff3cd; border: 1px solid #ffeaa7; border-radius: 8px; padding: 15px; margin: 20px 0; color: #856404;">
                <strong>Importante:</strong> Este código expira en {minutos} minutos. No compartas este código con nadie.
            </div>
            <div style="background-color: #e3f2fd; border-left: 4px solid #2196f3; padding: 15px; margin: 20px 0; color: #1565c0;">
                <strong>Nota de Seguridad:</strong><br>
                Si no solicitaste este código, ignora este correo. Tu cuenta permanece segura.
            </div>
        </div>
        <div style="background-color: #f8f9fa; padding: 25px 30px; text-align: center; border-top: 1px solid #e9ecef;">
            <p style="margin: 0; color: #6c757d; font-size: 14px;">
                <strong>Sistema de Recursos Humanos — RH Solutions</strong><br>
                Este es un correo automático, por favor no responder.
            </p>
            <p style="margin-top: 10px; font-size: 12px; color: #6c757d;">
                © {anio_actual} - Todos los derechos reservados
            </p>
        </div>
    </div>
</body>
</html>"""


def generar_y_enviar_otp_admin(usuario: Usuario, ip_address: str | None = None) -> str:
    """
    Genera un código OTP criptográficamente seguro de 6 dígitos, invalida códigos previos no usados,
    guarda únicamente su hash en user_otp_codes y envía el correo por SMTP (Resend).
    Jamás retorna el código OTP en la respuesta HTTP (.agents/rules/security_rules.md Regla #5).
    """
    if not usuario.correo_usuario:
        raise ValidationError({"detail": "No hay un correo registrado para este administrador."})

    codigo_otp = f"{secrets.randbelow(900000) + 100000:06d}"
    ahora = timezone.now()

    with transaction.atomic():
        UserOtpCode.objects.filter(
            id_usuario=usuario,
            radicado="LOGIN_ADMIN",
            used_at__isnull=True,
        ).update(used_at=ahora)

        registro_otp = UserOtpCode.objects.create(
            id_usuario=usuario,
            otp_code_hash=make_password(codigo_otp),
            radicado="LOGIN_ADMIN",
            intentos=0,
            expires_at=ahora + timedelta(minutes=OTP_EXPIRACION_MINUTOS),
            ip_address=ip_address,
        )

    asunto = "Código de Verificación – RH Solutions"
    texto_plano = (
        f"Hola Administrador, tu código de verificación de RH Solutions es: {codigo_otp}. "
        f"Expira en {OTP_EXPIRACION_MINUTOS} minutos."
    )
    html_cuerpo = _construir_html_correo_otp(codigo_otp, OTP_EXPIRACION_MINUTOS)

    try:
        mensaje = EmailMultiAlternatives(
            subject=asunto,
            body=texto_plano,
            from_email=settings.DEFAULT_FROM_EMAIL,
            to=[usuario.correo_usuario],
        )
        mensaje.attach_alternative(html_cuerpo, "text/html")
        mensaje.send(fail_silently=False)
    except Exception:
        registro_otp.delete()
        logger.exception(
            "Error enviando correo OTP de login al usuario %s", usuario.id_usuario
        )
        raise ValidationError(
            {"detail": "Error enviando el código de verificación al correo. Intenta nuevamente."}
        )

    return enmascarar_correo(usuario.correo_usuario)


def iniciar_sesion_usuario(request, usuario: Usuario) -> None:
    """
    Promueve al usuario a una sesión autenticada real, regenerando el ID de sesión
    para prevenir ataques de Session Fixation.
    """
    request.session.flush()
    request.session.cycle_key()
    request.session["rh_auth_user_id"] = usuario.id_usuario
    usuario.last_login = timezone.now()
    usuario.save(update_fields=["last_login", "updated_at"])


def autenticar_paso_inicial(
    request,
    doc_usuario: str,
    password_plano: str,
    ip_address: str | None = None,
) -> dict:
    """
    Evalúa documento y contraseña:
    - Si es Empleado (id_rol != 1): inicia sesión inmediatamente y devuelve redirect a /empleado/dashboard.
    - Si es Administrador (id_rol == 1): guarda estado pre-login en sesión, envía OTP por correo
      y solicita el paso de verificación 2FA.
    """
    usuario = (
        Usuario.objects.select_related("id_rol", "id_estado", "id_cargo")
        .filter(doc_usuario=doc_usuario)
        .first()
    )

    if not usuario or not verificar_credenciales_usuario(usuario, password_plano):
        raise AuthenticationFailed("Usuario o contraseña incorrecta")

    if usuario.id_estado_id == 2:
        raise PermissionDenied("Cuenta inhabilitada. Contáctate con el administrador.")

    # Si NO es Administrador (id_rol != 1) -> Login directo de Empleado
    if usuario.id_rol_id != 1:
        iniciar_sesion_usuario(request, usuario)
        return {
            "requires_otp": False,
            "usuario": usuario,
            "redirect_to": "/empleado/dashboard",
        }

    # Si es Administrador (id_rol == 1) -> Paso obligatorio de OTP
    correo_enmascarado = generar_y_enviar_otp_admin(usuario, ip_address=ip_address)
    request.session.flush()
    request.session["rh_admin_pre_login_uid"] = usuario.id_usuario

    return {
        "requires_otp": True,
        "email_masked": correo_enmascarado,
    }


def verificar_otp_admin_login(request, codigo_ingresado: str) -> Usuario:
    """
    Verifica el código OTP de 6 dígitos en base de datos con bloqueo transaccional (select_for_update)
    y límite estricto de 3 intentos en el backend.
    """
    admin_id = request.session.get("rh_admin_pre_login_uid")
    if not admin_id:
        raise AuthenticationFailed("No hay un proceso de verificación activo. Inicia sesión nuevamente.")

    ahora = timezone.now()

    with transaction.atomic():
        registro_otp = (
            UserOtpCode.objects.select_for_update()
            .filter(
                id_usuario_id=admin_id,
                radicado="LOGIN_ADMIN",
                used_at__isnull=True,
            )
            .order_by("-created_at")
            .first()
        )

        if not registro_otp:
            request.session.flush()
            raise AuthenticationFailed("No hay un código de verificación activo. Solicita uno nuevo.")

        if ahora > registro_otp.expires_at:
            registro_otp.used_at = ahora
            registro_otp.save(update_fields=["used_at", "updated_at"])
            raise AuthenticationFailed("El código ha expirado. Solicita uno nuevo.")

        if registro_otp.intentos >= MAX_OTP_INTENTOS:
            registro_otp.used_at = ahora
            registro_otp.save(update_fields=["used_at", "updated_at"])
            request.session.flush()
            raise PermissionDenied("Has superado el número máximo de intentos permitidos.")

        if not check_password(codigo_ingresado, registro_otp.otp_code_hash):
            registro_otp.intentos += 1
            if registro_otp.intentos >= MAX_OTP_INTENTOS:
                registro_otp.used_at = ahora
                registro_otp.save(update_fields=["intentos", "used_at", "updated_at"])
                request.session.flush()
                raise PermissionDenied("Has superado el número máximo de intentos permitidos.")

            registro_otp.save(update_fields=["intentos", "updated_at"])
            intentos_restantes = MAX_OTP_INTENTOS - registro_otp.intentos
            raise ValidationError(
                {
                    "detail": f"Código incorrecto. Te quedan {intentos_restantes} intento(s).",
                    "intentos_restantes": intentos_restantes,
                }
            )

        # OTP válido -> Marcar como consumido
        registro_otp.used_at = ahora
        registro_otp.save(update_fields=["used_at", "updated_at"])

    usuario = (
        Usuario.objects.select_related("id_rol", "id_estado", "id_cargo")
        .filter(id_usuario=admin_id)
        .first()
    )
    if not usuario or usuario.id_estado_id == 2:
        request.session.flush()
        raise AuthenticationFailed("Usuario no disponible.")

    iniciar_sesion_usuario(request, usuario)
    return usuario
