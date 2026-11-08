from django.urls import path

from .views import (
    CancelarOtpLoginAPIView,
    LoginAPIView,
    LogoutAPIView,
    MeAPIView,
    ReenviarOtpLoginAPIView,
    VerificarOtpLoginAPIView,
)

urlpatterns = [
    path("login/", LoginAPIView.as_view(), name="auth-login"),
    path("otp/verificar/", VerificarOtpLoginAPIView.as_view(), name="auth-otp-verificar"),
    path("otp/reenviar/", ReenviarOtpLoginAPIView.as_view(), name="auth-otp-reenviar"),
    path("otp/cancelar/", CancelarOtpLoginAPIView.as_view(), name="auth-otp-cancelar"),
    path("me/", MeAPIView.as_view(), name="auth-me"),
    path("logout/", LogoutAPIView.as_view(), name="auth-logout"),
]
