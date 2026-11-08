# 001 · Migración de Login, 2FA OTP de Administrador y Shells de Dashboard

- **Fecha:** 2026-11-07
- **Agente:** `/columbus` (`Agent: Columbus` 🧭)
- **Módulo Origen (Legacy Laravel 10):** `LoginController.php`, `OtpController.php`, `CheckUsuarioEstado.php`, `resources/views/login.blade.php`, `resources/views/emails/otp_login.blade.php`, `public/css/login.css`, `public/css/dashboard.css`, `public/js/login.js`
- **Módulo Destino (RH Solutions v2):** `rh_backend/apps/autenticacion/`, `rh_backend/apps/usuarios/`, `rh_backend/apps/catalogos/`, `rh_frontend/src/components/auth/`, `rh_frontend/src/components/layout/`, `rh_frontend/src/app/(auth)/login/`, `rh_frontend/src/app/admin/dashboard/`, `rh_frontend/src/app/empleado/dashboard/`
- **Estado:** Completado y verificado en vivo

---

## 1. Alcance de la Entrega

1. **Pantalla de Inicio de Sesión (`/login` y redirección desde `/`):**
   - Réplica visual fiel a `resources/views/login.blade.php` y `public/css/login.css` (mitad izquierda `#f4f6fc`, logo `rh19.png`, inputs `#02024D` con bordes redondeados de `8px`, botón de mostrar/ocultar contraseña, mitad derecha `#183160` con barras decorativas `#2a4576` e imagen corporativa `rh14.jpg`).
   - El enlace `"¿Olvidaste tu contraseña?"` permanece únicamente visual en esta entrega.
2. **Autenticación Diferenciada por Rol y 2FA OTP por Correo (Resend SMTP):**
   - **Administrador (`id_rol = 1`):** Valida credenciales con Argon2id (con soporte de transición transparente desde BCrypt `$2y$`), abre estado pre-login en sesión de servidor, genera un código OTP criptográfico de 6 dígitos (`secrets.randbelow()`), guarda únicamente su hash en `user_otp_codes`, envía el correo HTML mediante Resend SMTP (`smtp.resend.com:587`) al instante de pulsar **INICIAR SESION** y abre directamente el modal `OtpLoginModal.tsx` con el campo de 6 dígitos listo y temporizador de `5:00`.
   - **Empleado (`id_rol != 1`):** Inicia sesión directamente sin OTP, emite cookie `HttpOnly` (`SameSite=Lax`) y redirige a `/empleado/dashboard`.
3. **Guardias de Rol y Shells Limpios de Dashboard (`/admin/dashboard` y `/empleado/dashboard`):**
   - Protección cruzada mediante `DashboardShell.tsx` y `GET /api/v1/auth/me/`: usuarios sin sesión son redirigidos a `/login`, empleados no pueden acceder a `/admin/dashboard` y administradores no entran a `/empleado/dashboard`.
   - Shell visual fiel a `public/css/dashboard.css`: Sidebar izquierdo (`#000050`, `300px` de ancho, logo `rh18.png` y únicamente los ítems `Inicio` y `Cerrar sesión`), Topbar blanco (`70px` de alto con campana de notificaciones y menú de perfil con nombre y avatar `default.jpg`), área central `#f8f9fa` con el banner `rh19.png` y modal de confirmación `LogoutModal.tsx`.

---

## 2. Bugs y Vulnerabilidades del Legacy Corregidos

| # | Problema en el Monolito Legacy (`C:\laragon\www\rh_solutions`) | Solución Implementada en RH Solutions v2 |
|---|---|---|
| 1 | `LoginController.php` validaba `$user->id_cargo != 1` en lugar de `id_rol == 1`, dejando fuera del 2FA a administradores con otro cargo o exigiendo OTP por cargo en vez de rol. | Validación estricta por clave foránea de rol (`usuario.id_rol_id == 1`) en [`autenticar_paso_inicial()`](file:///C:/Project/rh_solutionsv2/rh_backend/apps/autenticacion/services.py#L170-L211). |
| 2 | El OTP del login se guardaba en texto plano en la sesión PHP (`Session::put('otp_code')`) en vez de usar la tabla transaccional `user_otp_codes`. | El código se almacena exclusivamente como hash (`make_password(codigo_otp)`) en la tabla `user_otp_codes` con `radicado="LOGIN_ADMIN"`, `expires_at` y `used_at`. |
| 3 | El límite de 3 intentos fallidos de OTP estaba programado únicamente en JavaScript del navegador (`public/js/login.js:285`), permitiendo fuerza bruta directa al endpoint. | Control de `intentos >= 3` en servidor dentro de `transaction.atomic()` con bloqueo de fila `select_for_update()` en PostgreSQL ([`verificar_otp_admin_login()`](file:///C:/Project/rh_solutionsv2/rh_backend/apps/autenticacion/services.py#L214-L283)). |
| 4 | Generación de OTP con `rand(100000, 999999)` (PRNG no criptográfico) y doble clic manual para enviar el correo. | Generación criptográfica con `secrets.randbelow(900000) + 100000` y disparo automático del correo en el mismo paso de login. |
| 5 | Mensajes de error que permitían enumeración de documentos registrados y exposición de `e.getMessage()`. | Mensaje único `"Usuario o contraseña incorrecta"` ante documento inexistente o clave inválida, y manejador global [`custom_exception_handler`](file:///C:/Project/rh_solutionsv2/rh_backend/core/exceptions.py#L11-L64) que jamás expone trazas internas. |

---

## 3. Archivos Creados y Modificados

### Variables de Entorno
- [`.env`](file:///C:/Project/rh_solutionsv2/.env) y [`.env.example`](file:///C:/Project/rh_solutionsv2/.env.example) (Raíz) — Exclusivos para la infraestructura de contenedores Docker (`docker-compose.yml`: puertos y credenciales de PostgreSQL 17, pgweb y Redis 7).
- [`rh_backend/.env`](file:///C:/Project/rh_solutionsv2/rh_backend/.env) y [`rh_backend/.env.example`](file:///C:/Project/rh_solutionsv2/rh_backend/.env.example) — Exclusivos del backend Django (conexión a PostgreSQL, Redis/Celery, secretos Django/CORS y credenciales SMTP de Resend). `rh_backend/.env.example` contiene únicamente los nombres de las variables vacías (`VARIABLE=`), y `rh_backend/.env` está protegido en [`rh_backend/.gitignore`](file:///C:/Project/rh_solutionsv2/rh_backend/.gitignore).

### Backend (`rh_backend/`)
- [`config/settings.py`](file:///C:/Project/rh_solutionsv2/rh_backend/config/settings.py) — Configuración de `RHSessionAuthentication`, `PASSWORD_HASHERS` (Argon2id + BCrypt), SMTP Resend y tasas de `DEFAULT_THROTTLE_RATES`.
- [`config/urls.py`](file:///C:/Project/rh_solutionsv2/rh_backend/config/urls.py) — Montaje de `/api/v1/auth/`.
- [`apps/catalogos/models.py`](file:///C:/Project/rh_solutionsv2/rh_backend/apps/catalogos/models.py) — Modelos `Rol`, `EstadoUsuario` y `Cargo` sincronizados con `seeders/init_postgres.sql`.
- [`apps/usuarios/models.py`](file:///C:/Project/rh_solutionsv2/rh_backend/apps/usuarios/models.py) — Modelo `Usuario` mapeado a la tabla `usuarios` en 3NF.
- [`apps/usuarios/migrations/0001_set_admin_argon2_password.py`](file:///C:/Project/rh_solutionsv2/rh_backend/apps/usuarios/migrations/0001_set_admin_argon2_password.py) — Migración de datos que actualiza la contraseña del Administrador `#1` (`doc_usuario = '123456789'`) a un hash Argon2id válido en Python.
- [`apps/autenticacion/models.py`](file:///C:/Project/rh_solutionsv2/rh_backend/apps/autenticacion/models.py) — Modelo `UserOtpCode` mapeado a `user_otp_codes`.
- [`apps/autenticacion/authentication.py`](file:///C:/Project/rh_solutionsv2/rh_backend/apps/autenticacion/authentication.py) — Clase `RHSessionAuthentication` con validación en tiempo real de `id_estado != 2` y protección CSRF.
- [`apps/autenticacion/serializers.py`](file:///C:/Project/rh_solutionsv2/rh_backend/apps/autenticacion/serializers.py) — `LoginInputSerializer`, `VerificarOtpInputSerializer` y `UsuarioSesionOutputSerializer`.
- [`apps/autenticacion/services.py`](file:///C:/Project/rh_solutionsv2/rh_backend/apps/autenticacion/services.py) — Lógica de negocio de autenticación, verificación Argon2id/BCrypt, plantilla HTML de correo OTP, envío por Resend y rotación de sesión.
- [`apps/autenticacion/views.py`](file:///C:/Project/rh_solutionsv2/rh_backend/apps/autenticacion/views.py) y [`apps/autenticacion/urls.py`](file:///C:/Project/rh_solutionsv2/rh_backend/apps/autenticacion/urls.py) — Endpoints `login/`, `otp/verificar/`, `otp/reenviar/`, `otp/cancelar/`, `me/` y `logout/`.

### Frontend (`rh_frontend/`)
- [`public/imgs/`](file:///C:/Project/rh_solutionsv2/rh_frontend/public/imgs) — Activos gráficos migrados desde el proyecto original (`rh19.png`, `rh18.png`, `rh14.jpg`, `default.jpg`, favicons).
- [`src/types/auth.ts`](file:///C:/Project/rh_solutionsv2/rh_frontend/src/types/auth.ts) — Contratos TypeScript de sesión, login y verificación OTP.
- [`src/stores/authStore.ts`](file:///C:/Project/rh_solutionsv2/rh_frontend/src/stores/authStore.ts) — Store de sesión en memoria RAM (Zustand) sin uso de `localStorage` ni `sessionStorage`.
- [`src/components/auth/LoginForm.tsx`](file:///C:/Project/rh_solutionsv2/rh_frontend/src/components/auth/LoginForm.tsx) (`208` líneas) — Formulario de inicio de sesión con validación de documento, toggle de contraseña y conexión con el modal OTP.
- [`src/components/auth/OtpLoginModal.tsx`](file:///C:/Project/rh_solutionsv2/rh_frontend/src/components/auth/OtpLoginModal.tsx) (`210` líneas) — Modal 2FA en `createPortal` con temporizador `5:00`, auto-submit al 6.º dígito y reenvío de código.
- [`src/components/layout/DashboardShell.tsx`](file:///C:/Project/rh_solutionsv2/rh_frontend/src/components/layout/DashboardShell.tsx) (`115` líneas) — Guardia de sesión y rol (`admin` vs `empleado`) y estructura base de los dashboards.
- [`src/components/layout/Sidebar.tsx`](file:///C:/Project/rh_solutionsv2/rh_frontend/src/components/layout/Sidebar.tsx) (`82` líneas) — Menú lateral `#000050` con logo `rh18.png`, `Inicio` y `Cerrar sesión`.
- [`src/components/layout/Topbar.tsx`](file:///C:/Project/rh_solutionsv2/rh_frontend/src/components/layout/Topbar.tsx) (`116` líneas) — Barra superior con campana de notificaciones y menú de usuario autenticado.
- [`src/components/layout/LogoutModal.tsx`](file:///C:/Project/rh_solutionsv2/rh_frontend/src/components/layout/LogoutModal.tsx) (`72` líneas) — Modal de confirmación de cierre de sesión.
- [`src/app/page.tsx`](file:///C:/Project/rh_solutionsv2/rh_frontend/src/app/page.tsx), [`src/app/(auth)/login/page.tsx`](file:///C:/Project/rh_solutionsv2/rh_frontend/src/app/(auth)/login/page.tsx), [`src/app/admin/dashboard/page.tsx`](file:///C:/Project/rh_solutionsv2/rh_frontend/src/app/admin/dashboard/page.tsx), [`src/app/empleado/dashboard/page.tsx`](file:///C:/Project/rh_solutionsv2/rh_frontend/src/app/empleado/dashboard/page.tsx) y [`src/app/layout.tsx`](file:///C:/Project/rh_solutionsv2/rh_frontend/src/app/layout.tsx).

---

## 4. Migraciones de Base de Datos y Verificación

- **Migración ejecutada:** `uv run python manage.py migrate` -> `Applying usuarios.0001_set_admin_argon2_password... OK`.
- **Verificación de tipos Frontend (`tsc --noEmit`):** `0` errores.
- **Verificación de linter Backend (`ruff check`):** `All checks passed!`.
- **Auditoría de líneas por componente (`src/components/`):** Todos los componentes entre `72` y `210` líneas brutas (bajo el umbral preventivo de `250` líneas y el límite estricto de `300`).
- **Prueba funcional en navegador:** Validada por el usuario contra PostgreSQL 17 y el backend Django en vivo.
