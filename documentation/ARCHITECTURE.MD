# ARQUITECTURA DEL SISTEMA · RH Solutions v2

> Conocimiento técnico y diseño estructural del sistema.
> Stack oficial, modelo de autenticación, topología de datos (44 tablas en 3NF), estructura de carpetas, colas asíncronas y presupuesto de rendimiento.
>
> **[IMPORTANTE]** Para las leyes obligatorias de codificación, límite de 300 líneas y convenciones de carpetas:
> Consultar [`.agents/rules/rules.md`](../.agents/rules/rules.md).
> Para las directivas de seguridad operativas → [`.agents/rules/security_rules.md`](../.agents/rules/security_rules.md).
> Para el protocolo de migración desde el monolito legacy → [`.agents/workflows/migracion-modulo.md`](../.agents/workflows/migracion-modulo.md) y [`documentation/migrations.md`](./migrations.md).

---

## 1. Qué es RH Solutions v2

Plataforma SaaS empresarial de **Gestión de Recursos Humanos y Talento Humano** diseñada para PYMEs. Permite administrar el ciclo de vida laboral de los empleados: vinculación, contratos, expediente digital de documentos con control automático de vencimientos, expedición de certificados laborales en PDF, flujo de permisos e incapacidades con firma electrónica OTP, gestión de renuncias y notificaciones en tiempo real.

| Capa | Tecnología Oficial |
|---|---|
| **Backend** | **Python `3.12.9`** · Gestor **`uv 0.13+`** · **Django `5.2 LTS`** · **Django REST Framework (DRF)** · **Django Channels** (WebSockets) · **Pandas `2.2+`** & **`openpyxl`** (Reportes Excel y analítica) · **WeasyPrint / ReportLab** (Motor PDF nativo) |
| **Frontend** | **Node.js `v24.18.0 LTS`** · **React `19`** · **Next.js `15` (App Router)** · **TypeScript `5.x`** · **Tailwind CSS `v4`** · **TanStack Table `v8`** (Tablas modernas sin DataTables) · **Zustand** (Estado en memoria) · **React Hook Form + Zod** |
| **Base de Datos** | **PostgreSQL `17-alpine`** en Docker (`rh_solutions_postgres`, puerto `5435:5432`, BD `rh_solutions_v2`) · 44 tablas en Tercera Forma Normal (3NF) y ASCII estricto |
| **Caché, Colas y WS** | **Redis `7-alpine`** en Docker (`rh_solutions_redis`, puerto `6380:6379`) · **Celery + Celery Beat** (Jobs asíncronos y tareas programadas) |
| **Inspección BD** | **pgweb** en Docker (`rh_solutions_pgweb`, disponible en `http://localhost:7070`) |

### Roles del Sistema (Tabla `roles` -> `usuarios.id_rol`)

| `id_rol` | Código (`codigo`) | Nombre | Alcance en la Plataforma |
|---|---|---|---|
| `1` | `admin` | **Administrador / Talento Humano** | Acceso total al panel administrativo: gestión de usuarios, cargos, contratos, asignación/visualización de documentos, autorización de certificados, autorización final de permisos y aceptación de renuncias. |
| `2` | `empleado` | **Empleado / Colaborador** | Acceso al portal del colaborador: actualización controlada de perfil, carga de documentos requeridos, solicitud de certificados laborales, solicitud de permisos con firma OTP y radicación de carta de renuncia. |
| `3` | `jefe_inmediato` | **Jefe Inmediato / Gerente de Área** | Permisos de empleado más bandeja de pre-aprobación/rechazo de permisos de los colaboradores a su cargo. |

---

## 2. Modelo de Autenticación y Sesión Blindada (`HttpOnly`)

La autenticación opera bajo el principio innegociable **"El backend decide, el frontend refleja"**. Ningún token de sesión, JWT ni rol se expone jamás a JavaScript ni se almacena en `localStorage` o `sessionStorage`.

```text
[ Next.js 15 SPA / App Router ]                       [ Django 5.2 DRF + Redis ]
    │                                                     │
    │  1) POST /api/v1/auth/login/ (credenciales) ──────► │ Valida Argon2id + Rate Limit en Redis
    │     (Si es Admin o flujo crítico: exige paso 2FA)   │ Si requiere OTP → genera código hasheado en user_otp_codes
    │                                                     │
    │  2) Respuesta de sesión autenticada ◄────────────── │ Set-Cookie: rh_access_token (HttpOnly, Secure, SameSite=Lax)
    │                                                     │ Set-Cookie: rh_refresh_token (HttpOnly, Secure, SameSite=Lax)
    │                                                     │ Set-Cookie: csrftoken (para header X-CSRFToken en mutaciones)
    │                                                     │
    │  3) GET /api/v1/auth/me/ (solo cookies) ──────────► │ Lee cookie HttpOnly → devuelve OutputSerializer del usuario
    │     Zustand guarda el perfil SOLO en memoria RAM    │
    │                                                     │
    │  4) POST /api/v1/auth/logout/ (+X-CSRFToken) ─────► │ Invalida sesión en Redis/BD y limpia cookies HttpOnly
```

**Principios fundamentales:**
1. **Autenticación:** Cookies `HttpOnly` gestionadas por el navegador e inaccesibles desde `document.cookie` (inmunidad ante robo de sesión por XSS).
2. **Autorización:** Cada endpoint en Django DRF verifica `request.user` y sus permisos (`IsAuthenticated`, `IsAdminRole`, `IsOwnerOrAdmin`). Nunca se confía en un `id_usuario` o `rol` enviado en el body o query string.
3. **Rehidratación en Frontend:** El store de Zustand mantiene los datos básicos del usuario únicamente en memoria RAM. Al recargar la pestaña (`F5`), el frontend consulta `GET /api/v1/auth/me/` para rehidratar el estado.

---

## 3. Estructura del Backend (`rh_backend/`)

```text
rh_backend/
├── config/                     # Configuración central de Django 5.2 (settings, urls, asgi, celery)
├── core/                       # Utilidades transversales, excepciones personalizadas, middlewares, permisos base y rate limiters
├── apps/
│   ├── autenticacion/          # Login, Logout, Refresh, OTP 2FA, Recuperación segura de contraseña y Consentimiento de firma
│   ├── catalogos/              # Los 27 catálogos maestros (departamentos, municipios, EPS, ARL, pensiones, cargos, etc.)
│   ├── usuarios/               # Gestión de empleados, perfil personal, estado laboral y licencias de conducción
│   ├── contratos/              # Creación, edición, prórrogas e historial de contratos laborales
│   ├── documentos/             # Asignación de documentos requeridos, carga privada, control de vencimientos y alertas
│   ├── certificados/           # Solicitud, validación de cooldown (valida_tiempo_certificado), aprobación y generación PDF
│   ├── permisos/               # Solicitud, cálculo de días hábiles/festivos, firma OTP, aprobación y PDF
│   ├── renuncias/              # Radicación de renuncia, previsualización PDF, carta de aceptación y desactivación programada
│   └── notificaciones/         # Notificaciones en base de datos, despacho por WebSockets (Channels) y auditoría (audit_logs)
└── manage.py
```

Cada aplicación dentro de `apps/<modulo>/` sigue una separación estricta de responsabilidades:
- `models.py`: Modelos Django mapeados en ASCII estricto a las 44 tablas de PostgreSQL.
- `serializers.py`: Divididos explícitamente en `*InputSerializer` (validación de entrada) y `*OutputSerializer` (contratos de salida JSON).
- `services.py`: Lógica de negocio, mutaciones envueltas en `transaction.atomic()` y llamadas a tareas asíncronas.
- `selectors.py`: Consultas de lectura optimizadas con `select_related()` y `prefetch_related()`.
- `views.py`: Vistas DRF delgadas que reciben el request, validan con el `InputSerializer`, invocan al `service`/`selector` y responden con el `OutputSerializer`.
- `urls.py`: Rutas versionadas bajo `/api/v1/<modulo>/`.

---

## 4. Estructura del Frontend (`rh_frontend/`)

```text
rh_frontend/
├── src/
│   ├── app/                    # Rutas de Next.js 15 App Router (páginas delgadas que montan vistas/componentes)
│   │   ├── (auth)/             # Login, verificación OTP y recuperación de contraseña
│   │   ├── admin/              # Rutas del panel de Administrador / Talento Humano
│   │   └── empleado/           # Rutas del portal de Empleado / Jefe Inmediato
│   ├── components/             # Sujeto al límite estricto de 300 líneas brutas (franja preventiva 250–300)
│   │   ├── layout/             # Sidebar.tsx (#000050), Topbar.tsx (blanca con campana de notificaciones), DashboardShell.tsx
│   │   ├── ui/                 # Primitivos reutilizables (DataTable moderna, AppPaginacion, ConfirmModal, FeedbackModal, Skeletons)
│   │   ├── admin/              # Subcarpetas por cada ítem de la Sidebar del Administrador:
│   │   │   ├── dashboard/
│   │   │   ├── usuarios/       # UsuariosTable.tsx, CrearUsuarioModal.tsx, EditarUsuarioModal.tsx, FichaUsuarioModal.tsx
│   │   │   ├── documentos/     # AsignacionDocumentos, VisualizacionDocumentos
│   │   │   ├── contratos/      # ContratosTable.tsx, CrearContratoModal.tsx, EditarContratoModal.tsx
│   │   │   ├── certificados/   # AutorizarCertificados, HistorialCertificados
│   │   │   ├── permisos/       # AutorizarPermisos, HistorialPermisos
│   │   │   └── renuncias/      # AceptarRenuncias, HistorialRenuncias
│   │   └── empleado/           # Subcarpetas por cada ítem de la Sidebar del Empleado:
│   │       ├── dashboard/
│   │       ├── mi_perfil/
│   │       ├── documentos/
│   │       ├── certificados/
│   │       ├── permisos/
│   │       └── renuncias/
│   ├── hooks/                  # Custom hooks de React (debounce, filtros de tabla, festivos, WebSockets)
│   ├── stores/                 # Stores de Zustand en memoria (authStore, notificationStore, uiStore)
│   ├── services/
│   │   └── api.ts              # Cliente HTTP único centralizado (con credentials: 'include' y manejo de CSRF)
│   └── types/                  # Interfaces TypeScript alineadas con los OutputSerializers del backend
```

---

## 5. Infraestructura Local en Docker (`docker-compose.yml`)

La infraestructura de datos corre aislada en contenedores Docker mientras que el backend (Django) y el frontend (Next.js) corren de forma nativa en el host para máxima velocidad de recarga en caliente (HMR):

| Contenedor | Imagen | Puerto Host → Contenedor | Propósito |
|---|---|---|---|
| `rh_solutions_postgres` | `postgres:17-alpine` | `5435:5432` | Base de datos relacional (`rh_solutions_v2`) inicializada con [`seeders/init_postgres.sql`](../seeders/init_postgres.sql) |
| `rh_solutions_pgweb` | `sosedoff/pgweb:latest` | `7070:8081` | Cliente visual web para inspeccionar las 44 tablas en `http://localhost:7070` |
| `rh_solutions_redis` | `redis:7-alpine` | `6380:6379` | Broker de colas Celery, caché de catálogos, rate limiting y capa de canales WebSocket |

### Comandos de Acceso a la Base de Datos Real (Fuente de la Verdad en Docker)

**Consulta directa no interactiva (para agentes de IA y subagentes):**
```bash
docker exec rh_solutions_postgres psql -U rh_admin -d rh_solutions_v2 -c "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public';"
```

**Inspección de estructura de una tabla (`\d`):**
```bash
docker exec rh_solutions_postgres psql -U rh_admin -d rh_solutions_v2 -c "\d usuarios"
```

**Consola interactiva (para desarrollador humano en terminal):**
```bash
docker exec -it rh_solutions_postgres psql -U rh_admin -d rh_solutions_v2
```

---

## 6. Tareas Programadas (Celery Beat) y Tiempo Real (Channels)

Los antiguos comandos cron de Laravel (`app/Console/Commands/`) se ejecutan en **Celery Beat** sobre Redis:
1. **`actualizar_estados_documentos` (6:00 AM y 6:00 PM):** Evalúa `documentos.fecha_vencimiento`, marca como `Por vencer` (`id_estado_documento = 4`) cuando faltan `<= 7` días y `Vencido` (`id_estado_documento = 5`) cuando `< 0` días, registra en `historial_emails_documentos`, encola los correos y emite notificación por WebSocket.
2. **`procesar_retiros_renuncias_aprobadas` (6:00 AM y 6:00 PM):** Busca renuncias aprobadas cuya `fecha_efectiva_retiro <= hoy` y pasa automáticamente al empleado a estado `Inactivo` (`usuarios.id_estado = 2`), revocando sus sesiones activas.

---

## 7. Presupuesto de Rendimiento

| Métrica | Objetivo | Límite Aceptable |
|---|---|---|
| Respuesta JSON de listado paginado (DRF) | `< 120 ms` | `250 ms` |
| Consultas SQL por request HTTP | `≤ 5` | `8` |
| Generación de vista previa de PDF en memoria | `< 400 ms` | `800 ms` |
| Líneas brutas por componente en `src/components/` | `< 250 líneas` | `300 líneas` (Tope absoluto) |

---

*RH Solutions v2 · Documentación Oficial de Arquitectura*
