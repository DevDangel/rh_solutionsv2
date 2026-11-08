from rest_framework.throttling import AnonRateThrottle, UserRateThrottle


class AuthThrottle(AnonRateThrottle):
    """Límite estricto para intentos de login y recuperación de contraseña."""

    scope = "auth"


class OTPThrottle(UserRateThrottle):
    """Límite estricto para generación y verificación de códigos OTP."""

    scope = "otp"


class StandardAPIThrottle(UserRateThrottle):
    """Límite estándar para operaciones autenticadas de la API."""

    scope = "api"
