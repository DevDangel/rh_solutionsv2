# SECURITY RULES · RH Solutions v2

> Manual y directivas de seguridad obligatorias.
> Léelo siempre antes de crear o modificar endpoints, autenticación, códigos OTP, generación de PDFs, subida de archivos o flujos de datos.
>
> - Para leyes de codificación y modularización → [`.agents/rules/rules.md`](./rules.md)
> - Para el modelo de autenticación en arquitectura → [`documentation/ARCHITECTURE.MD`](../../documentation/ARCHITECTURE.MD)
> - Para el detalle de los 20 pilares de seguridad → [`documentation/migrations.md`](../../documentation/migrations.md)

---

## 1. Reglas de Oro (Invariantes · NO Negociables)

1. **[CRÍTICO] Toda ruta que consulta o modifica datos de empleados o de la empresa exige autenticación activa (`IsAuthenticated`).**
2. **[CRÍTICO] La autorización y propiedad se deciden exclusivamente en el backend** inspeccionando `request.user` (`request.user.id_usuario` y `request.user.id_rol`), jamás confiando en un `id_usuario` o `rol` enviado desde el frontend.
3. **[CRÍTICO] Nunca devolver `str(e)`, trazas de pila (tracebacks), consultas SQL ni modelos Django crudos al cliente.** Todo error inesperado se registra con `logger.exception()` y responde al cliente con un mensaje genérico seguro.
4. **[CRÍTICO] Nunca guardar tokens JWT, sesión, rol ni datos personales en `localStorage` o `sessionStorage`.** La autenticación vive exclusivamente en cookies `HttpOnly`, `SameSite=Lax`.
5. **[CRÍTICO] Jamás incluir códigos OTP ni tokens de verificación en las respuestas JSON de ningún endpoint**, ni siquiera en modo `DEBUG=True`. Los códigos OTP viajan únicamente al canal de correo/notificación del usuario y se guardan hasheados en base de datos.
6. **[CRÍTICO] Bóveda privada para archivos sensibles (`PRIVATE_MEDIA_ROOT`).** Documentos de identidad, soportes médicos de incapacidades, contratos, certificados, cartas de renuncia y firmas PNG jamás se guardan en carpetas públicas estáticas. Toda descarga o visualización pasa por un endpoint autenticado que verifica permisos y emite un `FileResponse`.
7. **[CRÍTICO] Toda entrada del cliente se valida en el backend con un `*InputSerializer` dedicado.** La validación del frontend es solo UX; nunca reemplaza la seguridad del servidor.
8. **[CRÍTICO] Rate Limiting obligatorio en Redis:** Todos los endpoints de login, generación/verificación de OTP, recuperación de contraseña y descargas de PDF llevan limitador de intentos por IP y por usuario.
9. **[REQUERIDO] Protección CSRF activa (`X-CSRFToken`)** en todas las mutaciones (`POST`, `PUT`, `PATCH`, `DELETE`) usando cookies `HttpOnly`.
10. **[REQUERIDO] Consultas SQL 100% parametrizadas** a través del ORM de Django; prohibido interpolar variables con `f-strings` o `%` en `.raw()` o `cursor.execute()`.

---

## 2. Recetas de Backend (Django 5.2 + DRF)

### 2.1 Endpoint Protegido Estándar con `InputSerializer`, `OutputSerializer` y Servicio
```python
import logging
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from core.throttling import StandardAPIThrottle
from .serializers import ActualizarPerfilInputSerializer, PerfilOutputSerializer
from .services import actualizar_perfil_empleado

logger = logging.getLogger(__name__)


class MiPerfilUpdateAPIView(APIView):
    permission_classes = [IsAuthenticated]
    throttle_classes = [StandardAPIThrottle]

    def put(self, request):
        input_serializer = ActualizarPerfilInputSerializer(data=request.data)
        input_serializer.is_valid(raise_exception=True)

        try:
            # El usuario SIEMPRE se obtiene de la sesión autenticada (request.user)
            usuario_actualizado = actualizar_perfil_empleado(
                usuario=request.user,
                datos_validados=input_serializer.validated_data,
            )
            return Response(
                {
                    "status": "success",
                    "message": "Perfil actualizado correctamente.",
                    "data": PerfilOutputSerializer(usuario_actualizado).data,
                },
                status=status.HTTP_200_OK,
            )
        except Exception:
            logger.exception("Error inesperado al actualizar perfil del usuario %s", request.user.id_usuario)
            return Response(
                {
                    "status": "error",
                    "message": "No fue posible actualizar tu perfil en este momento. Inténtalo más tarde.",
                },
                status=status.HTTP_500_INTERNAL_SERVER_ERROR,
            )
```

### 2.2 Verificación de Rol y Propiedad del Recurso (Anti-IDOR)
Todo acceso a un permiso, certificado, documento o renuncia debe validar que el registro pertenezca a `request.user` o que el usuario tenga rol de Administrador (`id_rol == 1`) / Jefe Inmediato autorizado:
```python
from rest_framework.exceptions import PermissionDenied


def verificar_acceso_recurso(usuario, id_propietario_recurso: int, permitir_admin: bool = True) -> None:
    es_admin = permitir_admin and usuario.id_rol_id == 1
    es_propietario = usuario.id_usuario == id_propietario_recurso

    if not (es_propietario or es_admin):
        raise PermissionDenied("No tienes autorización para acceder o modificar este registro.")
```

### 2.3 Bóveda Privada de Archivos y Nombres Anonimizados
- **[PROHIBIDO]** Guardar archivos usando la cédula, el nombre del empleado o nombres predecibles en rutas accesibles públicamente (ej. `public/storage/firmas/firma_1098765432.png`).
- **[REGLA]** Todo archivo subido (PDF de incapacidad, cédula, firma digital) se valida por **Magic Bytes reales** (`%PDF-`, `\x89PNG`, `\xFF\xD8\xFF`), se renombra con un `uuid4().hex` aleatorio y se almacena fuera de la carpeta pública en `PRIVATE_MEDIA_ROOT`.

---

## 3. Recetas de Frontend (React 19 · Next.js 15)

### 3.1 Peticiones Seguras con Cliente Único (`src/services/api.ts`)
Todas las llamadas al backend deben realizarse a través del cliente centralizado `api` que inyecta automáticamente `credentials: 'include'` (para enviar las cookies `HttpOnly`) y la cabecera `X-CSRFToken`:
```typescript
import { api } from '@/services/api';

// Ejemplo de mutación segura:
const respuesta = await api.post('/api/v1/permisos/solicitar/', payload);
```
- **[PROHIBIDO]** Usar `fetch()` o `axios` crudo dentro de componentes o hooks.

### 3.2 Estado de Autenticación en Memoria
- `useAuthStore` (Zustand) mantiene los datos básicos del usuario **exclusivamente en memoria RAM**.
- Al inicializar la aplicación o recargar la página, el layout consulta `GET /api/v1/auth/me/` para rehidratar el usuario.
- Jamás se leen ni escriben roles, permisos o tokens en `localStorage` ni `sessionStorage`.

---

## 4. Tabla de Anti-Patrones Prohibidos (Bugs Reales Detectados en el RH Legacy)

Estos fallos existían en el monolito original (`C:\laragon\www\rh_solutions`) y fueron descubiertos durante la auditoría. **Reintroducir cualquiera de ellos en RH Solutions v2 se considera un fallo crítico:**

| Bug / Anti-patrón en el RH Legacy | Dónde ocurría en el viejo | Solución Obligatoria en RH Solutions v2 |
|---|---|---|
| **Devolver el código OTP en el JSON de respuesta** | `PermisosController.php:778` (`'otp_debug' => $otpCode`) | **Prohibido bajo cualquier entorno.** El OTP jamás sale en el response HTTP; solo se envía por correo y se guarda su hash en `user_otp_codes`. |
| **Inyección SQL y borrado por petición `GET`** | `UsuariosController.php` (`GET /usuarios/{id}/eliminar` con SQL concatenado) | Borrados o desactivaciones exclusivamente por `DELETE` / `PATCH` autenticado, con CSRF y consultas 100% parametrizadas por ORM. |
| **Cambio de contraseña sin validar token criptográfico** | `PasswordResetController@updatePassword` (recibía `id_usuario` plano en el POST) | Flujo de recuperación atado a un token firmado de un solo uso en Redis/BD; nunca aceptar `id_usuario` libre para cambiar clave. |
| **IDOR en certificados, permisos y renuncias** | Descarga de PDFs y soportes pasando `{id}` secuencial sin verificar dueño | Usar `uuid` público en rutas y ejecutar `verificar_acceso_recurso(request.user, recurso.id_usuario)` antes de devolver datos o archivos. |
| **Firmas PNG y soportes médicos en carpeta pública** | `public/storage/firmas/` y `public/storage/documentos/` accesibles sin login | Almacenamiento en `PRIVATE_MEDIA_ROOT` con nombres UUID y entrega mediante endpoint protegido con `IsAuthenticated`. |
| **Guardar sesión o rol en `localStorage`** | Scripts JS del cliente | Cookies `HttpOnly` + store de Zustand únicamente en memoria RAM. |
| **Devolver `str(e)` o errores de base de datos al cliente** | Bloques `catch` en varios controladores (`$e->getMessage()`) | Registrar con `logger.exception()` en el servidor y responder mensaje genérico amigable al usuario. |
| **Operaciones multi-tabla sin transacción ni bloqueo** | Creación de permisos/renuncias + historial sin `transaction` ni bloqueo de fila | Envolver siempre en `with transaction.atomic():` y usar `select_for_update()` para evitar condiciones de carrera por doble clic. |

---

## 5. Checklist de Seguridad antes de Cerrar una Feature o Migración

**Backend (Django DRF):**
- [ ] ¿El endpoint exige `IsAuthenticated` y valida el rol correspondiente (`admin`, `empleado`, `jefe_inmediato`)?
- [ ] ¿El usuario se toma siempre de `request.user` y se verifica la propiedad del recurso (`verificar_acceso_recurso`)?
- [ ] ¿Toda la entrada pasa por un `*InputSerializer` dedicado?
- [ ] ¿Toda la salida pasa por un `*OutputSerializer` explícito sin exponer campos sensibles ni `str(e)`?
- [ ] ¿Tiene configurado su `throttle_classes` en Redis (`AuthThrottle`, `OTPThrottle` o `StandardAPIThrottle`)?
- [ ] ¿Las escrituras compuestas están dentro de `transaction.atomic()`?
- [ ] ¿Si maneja archivos o PDFs, se guardan en la bóveda privada con nombre UUID y se sirven tras verificar autorización?

**Frontend (Next.js / React):**
- [ ] ¿Usa exclusivamente `src/services/api.ts` (cero `fetch` crudo)?
- [ ] ¿El estado de sesión vive en memoria (Zustand) sin tocar `localStorage` ni `sessionStorage`?
- [ ] ¿Ningún componente tocado supera el límite de 250–300 líneas brutas?

---

*RH Solutions v2 · Directivas Oficiales de Seguridad*
