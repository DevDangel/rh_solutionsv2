import uuid as uuid_lib

from django.db import models

from apps.catalogos.models import Cargo, EstadoUsuario, Rol


class Usuario(models.Model):
    id_usuario = models.AutoField(primary_key=True)
    uuid = models.UUIDField(default=uuid_lib.uuid4, unique=True, editable=False)
    doc_usuario = models.CharField(max_length=45, unique=True)
    id_tipo_identificacion = models.IntegerField()
    pri_nombre = models.CharField(max_length=45)
    seg_nombre = models.CharField(max_length=45, null=True, blank=True)
    pri_apellido = models.CharField(max_length=45)
    seg_apellido = models.CharField(max_length=55, null=True, blank=True)
    fec_nacimiento = models.DateField()
    id_tipo_sangre = models.IntegerField()
    id_sexo = models.IntegerField()
    id_estado_civil = models.IntegerField(null=True, blank=True)
    dir_usuario = models.CharField(max_length=255, null=True, blank=True)
    cel_usuario = models.CharField(max_length=45, unique=True)
    cel_emer_usuario = models.CharField(max_length=45)
    correo_usuario = models.CharField(max_length=120, unique=True)
    registro_profesional = models.CharField(max_length=45, null=True, blank=True)
    password = models.CharField(max_length=255)
    id_rol = models.ForeignKey(
        Rol,
        on_delete=models.RESTRICT,
        db_column="id_rol",
        related_name="usuarios",
    )
    id_departamento = models.IntegerField()
    id_municipio = models.IntegerField()
    id_estado = models.ForeignKey(
        EstadoUsuario,
        on_delete=models.RESTRICT,
        db_column="id_estado",
        related_name="usuarios",
    )
    id_cargo = models.ForeignKey(
        Cargo,
        on_delete=models.RESTRICT,
        db_column="id_cargo",
        related_name="usuarios",
    )
    id_eps = models.IntegerField()
    id_pension = models.IntegerField()
    id_arl = models.IntegerField()
    id_caj_compen = models.IntegerField()
    id_profesion = models.IntegerField()
    img_perfil = models.CharField(max_length=255, default="imgs/default.jpg", null=True, blank=True)
    ruta_firma = models.CharField(max_length=500, null=True, blank=True)
    last_login = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = "usuarios"
        managed = False

    @property
    def is_authenticated(self) -> bool:
        return True

    @property
    def is_anonymous(self) -> bool:
        return False

    def __str__(self) -> str:
        return f"{self.pri_nombre} {self.pri_apellido} ({self.doc_usuario})"
