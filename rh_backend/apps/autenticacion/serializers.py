from rest_framework import serializers

from apps.usuarios.models import Usuario


class LoginInputSerializer(serializers.Serializer):
    """Contrato de entrada obligatorio para POST /api/v1/auth/login/."""

    doc_usuario = serializers.RegexField(
        regex=r"^[0-9]{7,10}$",
        max_length=10,
        error_messages={
            "invalid": "El número de documento debe contener entre 7 y 10 dígitos numéricos.",
            "required": "El documento de usuario es obligatorio.",
        },
    )
    password = serializers.CharField(
        min_length=1,
        max_length=128,
        write_only=True,
        trim_whitespace=False,
        error_messages={
            "required": "La contraseña es obligatoria.",
        },
    )


class VerificarOtpInputSerializer(serializers.Serializer):
    """Contrato de entrada obligatorio para POST /api/v1/auth/otp/verificar/."""

    codigo = serializers.RegexField(
        regex=r"^[0-9]{6}$",
        max_length=6,
        error_messages={
            "invalid": "El código OTP debe contener exactamente 6 dígitos numéricos.",
            "required": "El código OTP es obligatorio.",
        },
    )


class UsuarioSesionOutputSerializer(serializers.ModelSerializer):
    """Contrato de salida explícito para el usuario autenticado."""

    uuid_usuario = serializers.UUIDField(source="uuid", read_only=True)
    documento = serializers.CharField(source="doc_usuario", read_only=True)
    primer_nombre = serializers.CharField(source="pri_nombre", read_only=True)
    segundo_nombre = serializers.CharField(source="seg_nombre", read_only=True)
    primer_apellido = serializers.CharField(source="pri_apellido", read_only=True)
    segundo_apellido = serializers.CharField(source="seg_apellido", read_only=True)
    correo = serializers.CharField(source="correo_usuario", read_only=True)
    id_rol = serializers.IntegerField(source="id_rol_id", read_only=True)
    rol_codigo = serializers.SerializerMethodField()
    nombre_cargo = serializers.CharField(source="id_cargo.cargo", read_only=True)

    class Meta:
        model = Usuario
        fields = [
            "id_usuario",
            "uuid_usuario",
            "documento",
            "primer_nombre",
            "segundo_nombre",
            "primer_apellido",
            "segundo_apellido",
            "correo",
            "id_rol",
            "rol_codigo",
            "nombre_cargo",
            "img_perfil",
        ]

    def get_rol_codigo(self, obj: Usuario) -> str:
        if obj.id_rol_id == 1:
            return "admin"
        if obj.id_rol_id == 3:
            return "jefe_inmediato"
        return "empleado"
