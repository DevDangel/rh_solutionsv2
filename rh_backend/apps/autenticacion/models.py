from django.db import models

from apps.usuarios.models import Usuario


class UserOtpCode(models.Model):
    id = models.AutoField(primary_key=True)
    id_usuario = models.ForeignKey(
        Usuario,
        on_delete=models.CASCADE,
        db_column="id_usuario",
        related_name="otp_codes",
    )
    otp_code_hash = models.CharField(max_length=128)
    radicado = models.CharField(max_length=100, null=True, blank=True)
    intentos = models.SmallIntegerField(default=0)
    expires_at = models.DateTimeField()
    used_at = models.DateTimeField(null=True, blank=True)
    ip_address = models.CharField(max_length=45, null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = "user_otp_codes"
        managed = False
