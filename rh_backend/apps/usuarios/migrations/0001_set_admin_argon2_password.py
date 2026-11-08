from django.contrib.auth.hashers import make_password
from django.db import migrations


def actualizar_password_admin(apps, schema_editor):
    """
    Actualiza la contraseña del Administrador #1 (doc_usuario = '123456789')
    al hash Argon2id nativo de Python para la clave de prueba 'Admin123'.
    """
    hash_argon2 = make_password("Admin123")
    with schema_editor.connection.cursor() as cursor:
        cursor.execute(
            "UPDATE usuarios SET password = %s, updated_at = NOW() WHERE id_usuario = 1;",
            [hash_argon2],
        )


def revertir_password_admin(apps, schema_editor):
    pass


class Migration(migrations.Migration):
    initial = True
    dependencies = []

    operations = [
        migrations.RunPython(actualizar_password_admin, revertir_password_admin),
    ]
