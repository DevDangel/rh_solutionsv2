from django.db import models


class Rol(models.Model):
    id_rol = models.AutoField(primary_key=True)
    nom_rol = models.CharField(max_length=45, unique=True)
    descripcion = models.CharField(max_length=255, null=True, blank=True)

    class Meta:
        db_table = "roles"
        managed = False

    def __str__(self) -> str:
        return self.nom_rol


class EstadoUsuario(models.Model):
    id_estado = models.AutoField(primary_key=True)
    nom_estado = models.CharField(max_length=155, unique=True)

    class Meta:
        db_table = "estado_usuario"
        managed = False

    def __str__(self) -> str:
        return self.nom_estado


class Cargo(models.Model):
    id_cargo = models.AutoField(primary_key=True)
    cargo = models.CharField(max_length=155, unique=True)
    id_dependencia = models.IntegerField()

    class Meta:
        db_table = "cargos"
        managed = False

    def __str__(self) -> str:
        return self.cargo
