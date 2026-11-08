import os
from pathlib import Path

from dotenv import load_dotenv

BASE_DIR = Path(__file__).resolve().parent.parent

# Carga las variables exclusivas del backend desde rh_backend/.env
load_dotenv(BASE_DIR / ".env")

SECRET_KEY = os.getenv(
    "DJANGO_SECRET_KEY",
    "django-insecure-rh-solutions-v2-dev-key-change-in-production",
)

DEBUG = os.getenv("DJANGO_DEBUG", "True").lower() in ("true", "1", "yes")

ALLOWED_HOSTS = os.getenv("DJANGO_ALLOWED_HOSTS", "localhost,127.0.0.1").split(",")

INSTALLED_APPS = [
    "django.contrib.admin",
    "django.contrib.auth",
    "django.contrib.contenttypes",
    "django.contrib.sessions",
    "django.contrib.messages",
    "django.contrib.staticfiles",
    # Terceros
    "corsheaders",
    "rest_framework",
    "channels",
    # Núcleo y Módulos de RH Solutions v2
    "core",
    "apps.autenticacion",
    "apps.catalogos",
    "apps.usuarios",
    "apps.contratos",
    "apps.documentos",
    "apps.certificados",
    "apps.permisos",
    "apps.renuncias",
    "apps.notificaciones",
]

MIDDLEWARE = [
    "corsheaders.middleware.CorsMiddleware",
    "django.middleware.security.SecurityMiddleware",
    "django.contrib.sessions.middleware.SessionMiddleware",
    "django.middleware.common.CommonMiddleware",
    "django.middleware.csrf.CsrfViewMiddleware",
    "django.contrib.auth.middleware.AuthenticationMiddleware",
    "django.contrib.messages.middleware.MessageMiddleware",
    "django.middleware.clickjacking.XFrameOptionsMiddleware",
]

ROOT_URLCONF = "config.urls"

TEMPLATES = [
    {
        "BACKEND": "django.template.backends.django.DjangoTemplates",
        "DIRS": [],
        "APP_DIRS": True,
        "OPTIONS": {
            "context_processors": [
                "django.template.context_processors.request",
                "django.contrib.auth.context_processors.auth",
                "django.contrib.messages.context_processors.messages",
            ],
        },
    },
]

WSGI_APPLICATION = "config.wsgi.application"
ASGI_APPLICATION = "config.asgi.application"

# Base de Datos PostgreSQL 17 en Docker (rh_solutions_postgres)
DATABASES = {
    "default": {
        "ENGINE": "django.db.backends.postgresql",
        "NAME": os.getenv("POSTGRES_DB", "rh_solutions_v2"),
        "USER": os.getenv("POSTGRES_USER", "rh_admin"),
        "PASSWORD": os.getenv("POSTGRES_PASSWORD", "rh_secret_2026"),
        "HOST": os.getenv("POSTGRES_HOST", "localhost"),
        "PORT": os.getenv("POSTGRES_PORT", "5435"),
        "CONN_MAX_AGE": 60,
    }
}

# Caché y Rate Limiting en Redis 7 en Docker (rh_solutions_redis)
REDIS_URL = os.getenv("REDIS_URL", "redis://localhost:6380/0")

CACHES = {
    "default": {
        "BACKEND": "django_redis.cache.RedisCache",
        "LOCATION": REDIS_URL,
        "OPTIONS": {
            "CLIENT_CLASS": "django_redis.client.DefaultClient",
        },
    }
}

# Capa de canales WebSocket (Django Channels + Redis)
CHANNEL_LAYERS = {
    "default": {
        "BACKEND": "channels_redis.core.RedisChannelLayer",
        "CONFIG": {
            "hosts": [REDIS_URL],
        },
    },
}

# Configuración de Colas Asíncronas (Celery + Redis)
CELERY_BROKER_URL = os.getenv("CELERY_BROKER_URL", "redis://localhost:6380/1")
CELERY_RESULT_BACKEND = os.getenv("CELERY_RESULT_BACKEND", "redis://localhost:6380/1")
CELERY_TIMEZONE = "America/Bogota"

# Hashers de Contraseñas: Argon2id principal + fallback transparente a BCrypt (hashes legacy de Laravel)
PASSWORD_HASHERS = [
    "django.contrib.auth.hashers.Argon2PasswordHasher",
    "django.contrib.auth.hashers.BCryptPasswordHasher",
    "django.contrib.auth.hashers.BCryptSHA256PasswordHasher",
    "django.contrib.auth.hashers.PBKDF2PasswordHasher",
]

AUTH_PASSWORD_VALIDATORS = [
    {"NAME": "django.contrib.auth.password_validation.UserAttributeSimilarityValidator"},
    {"NAME": "django.contrib.auth.password_validation.MinimumLengthValidator", "OPTIONS": {"min_length": 8}},
    {"NAME": "django.contrib.auth.password_validation.CommonPasswordValidator"},
    {"NAME": "django.contrib.auth.password_validation.NumericPasswordValidator"},
]

# Internacionalización y Zona Horaria (Colombia)
LANGUAGE_CODE = "es-co"
TIME_ZONE = "America/Bogota"
USE_I18N = True
USE_TZ = True

STATIC_URL = "static/"

# Bóveda privada de archivos sensibles (Fuera de rutas públicas: .agents/rules/security_rules.md)
PRIVATE_MEDIA_ROOT = BASE_DIR / "private_media"

# Configuración de Cookies HttpOnly y CORS hacia Next.js (http://localhost:3000)
CORS_ALLOWED_ORIGINS = os.getenv(
    "CORS_ALLOWED_ORIGINS",
    "http://localhost:3000,http://127.0.0.1:3000",
).split(",")
CORS_ALLOW_CREDENTIALS = True

CSRF_TRUSTED_ORIGINS = os.getenv(
    "CSRF_TRUSTED_ORIGINS",
    "http://localhost:3000,http://127.0.0.1:3000",
).split(",")

SESSION_COOKIE_HTTPONLY = True
SESSION_COOKIE_SAMESITE = "Lax"
SESSION_COOKIE_SECURE = not DEBUG

CSRF_COOKIE_HTTPONLY = False  # Permite a src/services/api.ts enviar el header X-CSRFToken
CSRF_COOKIE_SAMESITE = "Lax"
CSRF_COOKIE_SECURE = not DEBUG

# Configuración central de Django REST Framework
REST_FRAMEWORK = {
    "DEFAULT_PERMISSION_CLASSES": [
        "rest_framework.permissions.IsAuthenticated",
    ],
    "DEFAULT_AUTHENTICATION_CLASSES": [
        "apps.autenticacion.authentication.RHSessionAuthentication",
    ],
    "DEFAULT_THROTTLE_CLASSES": [
        "core.throttling.StandardAPIThrottle",
    ],
    "DEFAULT_THROTTLE_RATES": {
        "auth": "10/min",
        "otp": "5/min",
        "api": "60/min",
    },
    "EXCEPTION_HANDLER": "core.exceptions.custom_exception_handler",
}

# Configuración SMTP para envío de códigos OTP y notificaciones (.env)
EMAIL_BACKEND = "django.core.mail.backends.smtp.EmailBackend"
EMAIL_HOST = os.getenv("MAIL_HOST", "smtp.resend.com")
EMAIL_PORT = int(os.getenv("MAIL_PORT", "587"))
EMAIL_HOST_USER = os.getenv("MAIL_USERNAME", "resend")
EMAIL_HOST_PASSWORD = os.getenv("MAIL_PASSWORD", "")
EMAIL_USE_TLS = os.getenv("MAIL_ENCRYPTION", "tls").lower() == "tls"
EMAIL_USE_SSL = os.getenv("MAIL_ENCRYPTION", "tls").lower() == "ssl"
EMAIL_TIMEOUT = 15

MAIL_FROM_NAME = os.getenv("MAIL_FROM_NAME", "RH Solutions")
MAIL_FROM_ADDRESS = os.getenv("MAIL_FROM_ADDRESS", "noreply@softnatur.sebacry.me")
DEFAULT_FROM_EMAIL = f"{MAIL_FROM_NAME} <{MAIL_FROM_ADDRESS}>"

DEFAULT_AUTO_FIELD = "django.db.models.BigAutoField"
