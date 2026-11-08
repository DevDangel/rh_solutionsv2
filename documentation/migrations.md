# Documento Maestro de Migración y Arquitectura — RH Solutions v2

> **Propósito de este documento:** Servir como la **Única Fuente de la Verdad (Single Source of Truth)** para desarrolladores y agentes de IA sobre qué hacía exactamente el sistema legacy (`C:\laragon\www\rh_solutions`), cómo estaba estructurada su base de datos y su lógica de negocio, qué vulnerabilidades y deudas técnicas tenía, y cómo se construirá la nueva arquitectura desacoplada y blindada en `C:\Project\rh_solutionsv2`.

---

## 1. Visión General y Propósito del Proyecto

`RH Solutions` es una plataforma de Gestión de Talento Humano y Control de Personal pensada para PyMEs e instituciones (nacida originalmente alrededor del flujo operativo de una IPS en Colombia: *Promover S.A.S.*), enfocada en la **gestión integral del empleado (excepto liquidación de nómina)**:
- Hoja de vida del colaborador, seguridad social y firma electrónica manuscrita con consentimiento legal.
- Contratos laborales, funciones, cláusulas y vigencias.
- Solicitud y emisión automatizada de **Certificados Laborales** en PDF.
- **Gestión Documental** exigida por cargo o por persona, con control automático de fechas de vencimiento y alertas.
- **Permisos, Licencias y Vacaciones** con cálculo inteligente de días hábiles/calendario descontando festivos de Colombia, firma electrónica con OTP y generación de cartas en PDF.
- **Trámite de Renuncias** con previsualización de carta en vivo, aceptación/rechazo con citación a exámenes médicos de egreso, desvinculación programada y reincorporación.

### ¿Por qué migramos?
El proyecto original (`C:\laragon\www\rh_solutions`) demostró el valor comercial del producto, pero fue construido como un monolito **Laravel 12 MVC + Blade + Bootstrap 5 + jQuery + DataTables**, arrastrando problemas críticos para escalar y vender como SaaS/producto a PyMEs:
1. **Acoplamiento MVC y UX rígida:** Recargas completas, jQuery espagueti, modales pesados y estilos inconsistentes.
2. **Brechas graves de seguridad:** Archivos sensibles (firmas manuscritas, hojas de vida, incapacidades) en rutas públicas (`/storage/...`), vulnerabilidades IDOR, SQL Injection en rutas `GET`, exposición de códigos OTP en respuestas JSON y ausencia de Rate Limiting.
3. **Necesidad de Analítica Avanzada:** El nuevo sistema requiere capacidades nativas de análisis de datos y reportería con **Python + Pandas** sobre **PostgreSQL**.

---

## 2. Radiografía del Sistema Legacy (`C:\laragon\www\rh_solutions`)

### 2.1. Stack Tecnológico Antiguo
- **Backend:** PHP `^8.2` con **Laravel `^12.0`** (Arquitectura monolítica MVC con rutas en `routes/web.php`).
- **Base de Datos:** MySQL (`utf8mb4` mezclado con `utf32` en algunas tablas).
- **Motor de Tablas:** `yajra/laravel-datatables-oracle: ^12.6` (Server-side DataTables acoplado a HTML inyectado desde controladores PHP).
- **Generador de PDFs:** `barryvdh/laravel-dompdf: ^3.1` renderizando vistas Blade con imágenes membretadas.
- **Integraciones:** `google/apiclient: ^2.15` y consumo HTTP de **Google Calendar API v3** (`FestivosService`) para festivos en Colombia.
- **Frontend Real en Vistas Blade:**
  - Aunque `package.json` tenía instalado `@tailwindcss/vite: ^4.0.0`, **ninguna vista lo utilizaba**.
  - Todo el UI dependía de **Bootstrap `5.3.3`**, **jQuery `3.7.1`**, **DataTables `1.13.6`**, **Select2 `4.1.0`**, **SweetAlert2 `v11`**, **FontAwesome `6.0`** y hojas de estilo manuales en `public/css/*.css` junto con scripts imperativos en `public/js/*.js`.

### 2.2. Autenticación y Guards en el Sistema Viejo
- **Proveedor único:** Modelo `App\Models\Usuario` sobre la tabla `usuarios` (la tabla `users` nativa de Laravel existe en el SQL pero está vacía y sin uso).
- **Dos Guards de Sesión (`config/auth.php`):** `admin` y `usuario`.
- **Cómo diferenciaba Admin de Empleado:** No existía tabla de roles. El sistema verificaba de forma rígida `if ($user->id_cargo == 1)` (*Coordinador de talento humano*). Si era `1`, exigía OTP por correo y abría sesión en `Auth::guard('admin')`; para cualquier otro `id_cargo`, abría sesión directa en `Auth::guard('usuario')`.
- **Middleware `CheckUsuarioEstado` (`check.usuario.estado`):** En cada petición verificaba si `$usuario->id_estado == 2` (*Desvinculado*). Si era `2`, destruía la sesión y redirigía al login.

---

## 3. Catálogo Exhaustivo de Módulos y Reglas de Negocio a Replicar

Toda la lógica de negocio descrita a continuación debe preservarse en el nuevo backend (corrigiendo sus fallos de seguridad y diseño):

### Módulo 1: Autenticación, 2FA (OTP Admin) y Recuperación de Contraseña
1. **Login por Documento (`doc_usuario` + `password`):**
   - Rechaza el acceso inmediatamente si `id_estado == 2` (*Desvinculado*).
   - Si el usuario tiene rol de **Empleado**, inicia sesión y emite las cookies `httpOnly`.
   - Si el usuario tiene rol de **Administrador de RRHH**, **no inicia sesión todavía**: genera un código OTP de 6 dígitos con vigencia de **5 minutos**, lo envía al correo registrado (mostrando en pantalla el correo enmascarado, ej. `sa***@gmail.com`) y abre el paso de verificación 2FA.
2. **Recuperación de Contraseña en 3 pasos:**
   - **Paso 1:** El usuario ingresa su número de documento (`doc_usuario`). Si existe y tiene correo, se genera un código OTP de 6 dígitos con vigencia de **20 minutos** y se envía por email.
   - **Paso 2:** Verificación del código con un máximo estricto de **3 intentos fallidos** (al tercer fallo se invalida el código y se reinicia el flujo).
   - **Paso 3:** Cambio de contraseña exigiendo política fuerte: mínimo 8 caracteres, al menos 1 mayúscula, 1 minúscula, 1 número y 1 carácter especial (`@$!%*#?&.`), más notificación por correo de cambio exitoso.

---

### Módulo 2: Gestión de Colaboradores, Perfil y Firma Electrónica
1. **Administración de Usuarios (Rol Admin):**
   - CRUD completo de empleados con datos personales, ubicación (`departamentos`, `municipio`), seguridad social (`eps`, `pensiones`, `arl`, `caja_compensacion`), `cargos` (asociados a `dependencias`), `profesion` y `registro_profesional`.
   - Validación en tiempo real de unicidad para: `doc_usuario`, `correo_usuario`, `cel_usuario` y combinación `registro_profesional + id_profesion`.
   - **Switch Activar / Desvincular (`cambiarEstado`):** Al pasar un empleado a *Desvinculado* (`id_estado = 2`), el sistema debe **revocar todas sus sesiones activas de inmediato**.
   - **Botón Reincorporar (`reincorporarUsuario`):** Visible cuando el empleado tiene una solicitud de renuncia en estado `aprobada`. Permite reincorporarlo archivando/limpiando el bloqueo de renuncia activa sin perder la trazabilidad en el historial.
2. **Autogestión de Perfil y Firma Electrónica (Rol Empleado):**
   - El empleado puede actualizar sus datos de contacto (`correo_usuario`, `cel_usuario`, `cel_emer_usuario`, `estado_civil`, `dir_usuario`, `id_departamento`, `id_municipio`).
   - **Foto de Perfil:** Subida de imagen o captura desde cámara web (máx. 5 MB).
   - **Firma Manuscrita Electrónica (`ruta_firma`) y Consentimiento Legal:**
     - El empleado sube su firma en formato `PNG` (fondo transparente, máx. 5 MB).
     - Debe aceptar explícitamente el **Consentimiento de Firma Digital**, el cual se registra en la tabla `consentimientos_firma_digital` (`id_usuario`, `ruta_firma`, `acepto_terminos`, `fecha_consentimiento`, más IP y User-Agent en el nuevo stack) bajo el marco de la **Ley 527 de 1999 y Decreto 2364 de 2012**.

---

### Módulo 3: Contratos y Cargos Organizacionales
1. **Cargos y Dependencias:**
   - CRUD de `cargos` vinculados a una `dependencia` (`id_dependencia`), validando que el nombre del cargo sea único.
2. **Contratos Laborales (`contrato`):**
   - Un empleado puede tener uno o varios contratos a lo largo de su historia laboral.
   - Campos: `id_usuario` (búsqueda previa por documento), `id_tip_contrato` (*Término fijo, Indefinido, Obra o labor, Aprendizaje, Prestación de servicios, etc.*), `id_tiemp_contrato`, `id_est_contrato` (*Vigente, Finalizado, Renovado, En prueba, etc.*), `fec_ingreso`, `fec_finalizacion` (opcional según tipo), `salario` (numérico entre `100.000` y `99.999.999`), `funciones` (hasta 6.000 caracteres) y `clausulas` (hasta 6.000 caracteres).

---

### Módulo 4: Solicitud y Emisión de Certificados Laborales
1. **Reglas de Solicitud (Rol Empleado):**
   - El certificado se solicita sobre un **contrato específico (`id_contrato`)** perteneciente al empleado.
   - Genera un **radicado único de 6 dígitos** (`radicado_cert`).
   - **Opciones personalizables (switches booleanos):**
     - `incluir_cargo`
     - `incluir_salario`
     - `incluir_funciones`
     - `dirigido_banco` (si es `true`, exige seleccionar `id_banco`).
   - **Motivos que exigen adjuntar soporte (PDF/JPG/PNG):**
     - *Trámite de visa*, *Arrendamiento de vivienda*, *Trámite de pensión o cesantías*, *Homologación de estudios en el extranjero*, *Trámite de becas o ayudas educativas*, *Postulación a estudios superiores*.
   - **Regla de Segunda Vez y Cooldown (`tiempo_espera`):**
     - Si el empleado ya pidió antes un certificado para ese mismo contrato, el sistema detecta `esSegundaVez` y exige llenar la justificación `motivo_seg_vez`.
     - Una vez que una solicitud es aprobada o rechazada, se activa un **tiempo de enfriamiento (`tiempo_espera`) de 24 horas en producción** (configurable por variable de entorno a 3 minutos en desarrollo) antes de permitir otra solicitud sobre el mismo contrato.
2. **Ciclo de Estados de la Solicitud:**
   - `pendiente` → El empleado puede **Cancelar** la solicitud (pasa a `sin solicitud`). No puede eliminarla mientras esté `pendiente`.
   - `sin solicitud` → El empleado puede **Editar**, **Enviar** (vuelve a `pendiente`) o **Eliminar**.
   - `rechazada` → El empleado debe **Editar** primero la solicitud corrigiendo lo observado en `motivo_rechazo`; al guardar cambios se habilita el botón **Enviar** (pasa a `pendiente`) o puede **Eliminar**.
   - `aprobada` → Habilita la visualización/descarga segura del certificado en PDF.
3. **Aprobación o Rechazo (Rol Admin):**
   - **Aprobar:** Calcula dinámicamente si el empleado `"Labora"` (`fec_finalizacion` nula o futura) o `"Laboró"` (`fec_finalizacion` pasada), arma el PDF con las secciones elegidas (`cargo`, `contrato`, `salario`, `funciones` truncadas a 700 caracteres, `banco`), guarda el PDF, registra en `historial_certificados` y envía el PDF adjunto por correo al empleado.
   - **Rechazar:** Registra `motivo_rechazo`, guarda en `historial_certificados` y notifica por correo al empleado.

---

### Módulo 5: Gestión Documental por Cargo y Persona + Vencimientos
1. **Asignación de Documentos Requeridos (`documentos_requeridos` — Rol Admin):**
   - El administrador puede exigir un documento de dos maneras:
     - **Masiva por Cargo (`id_cargo`):** Aplica a todos los empleados que tengan ese cargo.
     - **Individual por Persona (`id_usuario`):** Aplica a un empleado específico buscado por cédula.
   - Define el nombre del documento (`nom_documento`), el formato permitido (`id_tip_document`: `1 = PDF`, `2 = Word`, `3 = Excel`), si es `obligatorio` y si **`requiere_fecha` de vencimiento** (`0` o `1`).
2. **Subida y Semáforo Automático de Estados (`documentos` — Rol Empleado y Admin):**
   - El empleado ve la lista combinada de documentos requeridos para su `id_cargo` **más** los asignados a su `id_usuario`.
   - Peso máximo por archivo: **5 MB**.
   - **Regla de cálculo de estado:**
     - No subido todavía → **`Pendiente`**
     - Subido y no requiere fecha de vencimiento → **`Cargado`**
     - Subido con `fecha_vencimiento`:
       - Faltan **más de 7 días** (`dias > 7`) → **`Vigente`**
       - Faltan **entre 0 y 7 días** (`0 <= dias <= 7`) → **`Por vencer`**
       - Fecha ya pasada (`dias < 0`) → **`Vencido`**
3. **Job Programado de Vencimientos (6:00 AM y 6:00 PM en Celery Beat):**
   - Recalcula estados de todos los documentos con fecha de vencimiento.
   - Cuando un documento entra en `Por vencer` o `Vencido`:
     - Crea notificación en plataforma (`notificaciones`) para el empleado y para los administradores de RRHH (sin duplicar si ya existe una activa).
     - Envía correo de alerta al empleado y registra el envío en `historial_emails_documentos` para garantizar que no se envíe spam repetido por el mismo evento.

---

### Módulo 6: Permisos, Licencias y Vacaciones (Calendario Colombia + Firma OTP)
1. **Reglas por Tipo de Permiso (`tipo_permisos`):**

| ID | Tipo de Permiso | Duración | Tipo de Conteo | ¿Exige Soporte PDF? |
| :--- | :--- | :--- | :--- | :--- |
| `1` | **Vacaciones** | `15` días fijos | Días **hábiles** (Lun–Sáb sin domingos ni festivos) | No |
| `2` | **Licencia de luto** | `5` días fijos | Días **hábiles** (Lun–Sáb sin domingos ni festivos) | **Sí (Obligatorio)** |
| `3` | **Cita médica** | `1` mismo día (`hora_inicio` a `hora_fin`) | Horas en el mismo día | **Sí (Obligatorio)** |
| `4` | **Calamidad doméstica** | `num_dias` variable | Días **hábiles** (Lun–Sáb sin domingos ni festivos) | **Sí (Obligatorio)** |
| `5` | **Permiso no remunerado** | `num_dias` variable | Días **calendario** (corridos) | No |
| `6` | **Licencia de maternidad** | `126` días fijos | Días **calendario** (corridos) | Opcional |

2. **Algoritmo de Fechas y Festivos de Colombia (`FestivosService`):**
   - Obtiene los festivos del año desde Google Calendar API v3 (o cálculo algorítmico de festivos de Colombia Ley Emiliani como fallback sin años quemados) y los cachea en **Redis por 24 horas**.
   - **Días hábiles:** Cuenta de lunes a sábado excluyendo domingos y festivos nacionales.
   - **Fecha de Reincorporación (`fecha_reincorporacion`):** Toma `fecha_finalizacion + 1 día`; si cae en domingo o festivo, avanza hasta el siguiente día hábil.
3. **Firma Electrónica del Permiso validada con OTP:**
   - Exige que el empleado tenga firma PNG cargada en su perfil (`ruta_firma`).
   - El empleado solicita un código OTP de firma (`enviarOTPFirma`), lo recibe en su correo y lo valida (`verificarOTPFirma`).
   - Al guardar, el sistema genera automáticamente el PDF de la carta de solicitud según la plantilla del tipo de permiso, incrustando la firma manuscrita y el pie legal (Ley 527 de 1999).
4. **Ciclo de Estados y Aprobación:**
   - Estados: `Sin solicitud` ↔ `Pendiente` → `Autorizado` / `Rechazado`.
   - Al **Autorizar** (Admin): genera el segundo PDF (**Carta de Aprobación de Permiso**), lo envía por correo al empleado y registra en `historial_permisos`.
   - Al **Rechazar** (Admin): guarda `motivo_rechazo`, registra en `historial_permisos` y envía correo de rechazo.

---

### Módulo 7: Solicitud y Gestión de Renuncias
1. **Regla de Solicitud Única Activa:**
   - Un empleado no puede crear una nueva solicitud de renuncia si ya tiene una en estado `pendiente`, `sin solicitud`, `aprobada` o `rechazada` (si está `rechazada` o `sin solicitud`, edita o reutiliza la existente).
2. **Creación y Previsualización de Carta en PDF:**
   - Campos: `radicado_renun` (6 dígitos), `fech_renun` (estrictamente posterior a hoy), `motivo_renun`, `motivo_ampliado` (opcional, máx. 250 caracteres), `autoriza_firma` y `autoriza_datos`.
   - Permite **previsualizar en tiempo real** cómo quedará la carta de renuncia en PDF antes de enviarla, tomando la fecha de ingreso del último contrato del empleado y su firma electrónica.
3. **Aprobación, Carta de Aceptación y Desvinculación Programada:**
   - Cuando el Admin **Aprueba** la renuncia:
     - Genera el PDF de **Carta de Aceptación de Renuncia**, que incluye la orden para realizar el examen médico ocupacional de egreso (Resolución 2346 de 2007 Art. 6).
     - Envía la carta por correo al empleado y guarda copia en `historial_renuncias`.
   - **Desvinculación diferida automática (Job 6:00 AM y 6:00 PM en Celery Beat):**
     - Aprobar la renuncia **no bloquea al empleado ese mismo día** si su `fech_renun` es a fin de mes. El job programado verifica diariamente qué renuncias aprobadas ya alcanzaron `fech_renun <= hoy` (hora `America/Bogota`) y en esa fecha cambia automáticamente al empleado a `id_estado = 2` (*Desvinculado*) y revoca sus sesiones.

---

### Módulo 8: Sistema de Notificaciones en Tiempo Real
- Bandeja de notificaciones (`notificaciones`) con contador de no leídas, marcar individual/todas como leídas y eliminación lógica (`estado = 0`).
- **Mejora en v2:** En lugar de consultar la base de datos desde la vista en cada recarga de página, las notificaciones se empujarán en vivo mediante **WebSockets (Django Channels + Redis)** cuando un empleado cree una solicitud o cuando RRHH apruebe/rechace un trámite o venza un documento.

---

## 4. Análisis del Modelo de Datos y Normalización 3NF en PostgreSQL (`seeders/init_postgres.sql`)

El archivo original [model-database-old-mvc.sql](file:///C:/Project/rh_solutionsv2/model-database-old-mvc.sql) contenía 29 tablas (varias de ellas internas de Laravel y con datos transaccionales de prueba sucios). A partir de la auditoría del código PHP y la normalización en Tercera Forma Normal (3NF), el esquema definitivo en [seeders/init_postgres.sql](file:///C:/Project/rh_solutionsv2/seeders/init_postgres.sql) consta de **44 tablas** (**27 Tablas Catálogo** pobladas + **17 Tablas Operativas** limpias, iniciando únicamente con el Usuario `#1` Administrador).

### 4.1. Las 5 tablas que estaban en el código PHP pero faltaban en `model-database-old-mvc.sql`
Incluidas formalmente en el esquema PostgreSQL:
1. **`notificaciones`**: `id`, `usuario_id`, `documento_id`, `tipo`, `mensaje`, `usuario_nombre`, `cedula_usuario`, `img_perfil`, `url`, `leida` (`boolean`), `estado` (`boolean`), `created_at`, `updated_at`.
2. **`user_otp_codes`**: Control y auditoría de códigos OTP hasheados (`otp_code_hash`), intentos, expiración (`expires_at`) y uso (`used_at`).
3. **`consentimientos_firma_digital`**: `id`, `id_usuario`, `ruta_firma`, `acepto_terminos`, `ip_address`, `user_agent`, `fecha_consentimiento`.
4. **`valida_tiempo_certificado`**: Control de cooldown entre solicitudes de certificados por contrato.
5. **`historial_emails_documentos`**: Control de idempotencia para no enviar correos repetidos por documentos vencidos o por vencer.

### 4.2. Normalización de Catálogos, Roles y Estados (Cero `ENUM` o textos sueltos)
1. **Nuevas Tablas de Estado Independientes por Módulo (FKs estrictas):**
   - **`estado_documento`** (`1: Pendiente`, `2: Cargado`, `3: Vigente`, `4: Por vencer`, `5: Vencido`) → FK `id_estado_documento` en `documentos`.
   - **`estado_permiso`** (`1: Sin solicitud`, `2: Pendiente`, `3: Autorizado`, `4: Rechazado`, `5: Cancelado`) → FK `id_estado_permiso` en `permisos` e `historial_permisos`.
   - **`estado_certificado`** (`1: Sin solicitud`, `2: Pendiente`, `3: Aprobada`, `4: Rechazada`, `5: Cancelada`) → FK `id_estado_certificado` en `solicitud_certificado` e `historial_certificados`.
   - **`estado_renuncia`** (`1: Sin solicitud`, `2: Pendiente`, `3: Aprobada`, `4: Rechazada`, `5: Cancelada`) → FK `id_estado_renuncia` en `renuncia_solicitud` e `historial_renuncias`.
   - **`estado_licencia`** y **`categoria_licencia`**: Pobladas en el seeder (estaban vacías en el SQL viejo).
2. **Separación de Cargo vs. Rol del Sistema (`roles`) y Demográficos de `usuarios`:**
   - Nueva tabla **`roles`** (`1: Administrador`, `2: Empleado`) vinculada mediante `usuarios.id_rol`, desacoplando los permisos del sistema del cargo laboral (`id_cargo`).
   - Los antiguos `ENUM` de `usuarios` pasan a sus propias tablas catálogo con llave foránea:
     - **`tipo_identificacion`** (`id_tipo_identificacion`: `CC, CE, TI, PA, DNI, PEP, PPT`) — nombrada así para no colisionar con `tipo_documento` (`PDF, Word, Excel`).
     - **`tipo_sangre`** (`id_tipo_sangre`: `A+, A-, B+, B-, AB+, AB-, O+, O-`).
     - **`sexo`** (`id_sexo`: `Masculino, Femenino`).
     - **`estado_civil`** (`id_estado_civil`: `Soltero(a), Casado(a), Divorciado(a), Viudo(a), Unión libre, Separado(a)`).
3. **Corrección de tipos de datos para Analítica con Pandas:**
   - En `contrato`, el campo `salario` pasa de `varchar(45)` a `NUMERIC(12, 2)`.
   - Normalización de codificación a `UTF-8` estándar de PostgreSQL (eliminando la mezcla de `utf32_spanish_ci` y `utf8mb4` de MySQL).
   - Renombrado de la columna `contraseña` (con `ñ`) a `password` en `usuarios` para compatibilidad nativa con Django y `Argon2`.
4. **Identificadores Públicos (`uuid`) y Sincronización de Secuencias:**
   - Columna `uuid` (`UUIDv4` con `gen_random_uuid()`) en las entidades expuestas por API (`usuarios`, `contrato`, `documentos`, `permisos`, `solicitud_certificado`, `renuncia_solicitud`).
   - Al final de [seeders/init_postgres.sql](file:///C:/Project/rh_solutionsv2/seeders/init_postgres.sql) se ejecuta `setval(pg_get_serial_sequence(...))` sobre las 28 tablas con datos semilla para evitar colisiones de llaves primarias en futuras inserciones.
5. **Limpieza de datos sucios y tablas basura de Laravel:**
   - Se eliminan los empleados de prueba (`25..28`), contratos (`54..58`) y trámites huérfanos del dump viejo, dejando **solo los catálogos maestros y el Usuario `#1` (Admin)**.
   - Se descartan del esquema de negocio `users` (vacía), `migrations`, `jobs`, `job_batches`, `failed_jobs`, `cache`, `cache_locks` y `sessions`.
6. **Nueva tabla `audit_logs` (Trazabilidad y Firma Electrónica):**
   - Guardará cada evento crítico (aprobaciones, rechazos, cambios de salario, desvinculaciones, descargas de documentos y el **hash `SHA-256`** de cada PDF firmado electrónicamente).

---

## 5. Deuda Técnica y Vulnerabilidades del Sistema Viejo (Lo que Corregimos)

La auditoría del repositorio legacy documentó fallos críticos que quedan erradicados por diseño en `rh_solutionsv2`:

| # | Vulnerabilidad / Bug en el Sistema Viejo | Ubicación en el Legacy | Solución en `rh_solutionsv2` (Django + Next.js) |
| :--- | :--- | :--- | :--- |
| **1** | **Inyección SQL (SQLi) y borrado por `GET`** | `UsuariosController@delete` ejecutaba `DELETE FROM usuarios WHERE id_usuario=$id` en ruta `GET`. | ORM de Django con consultas 100% parametrizadas y verbos HTTP estrictos (`DELETE` autenticado con CSRF). |
| **2** | **Fuga del código OTP en respuesta JSON** | `PermisosController@enviarOTPFirma` (línea 778) devolvía `'otp' => $otp` en el JSON al navegador. | El OTP jamás sale en una respuesta HTTP; se almacena hasheado en Redis y solo viaja por correo asíncrono (Celery). |
| **3** | **Reset de contraseña sin verificar sesión/token** | `PasswordResetController@updatePassword` permitía cambiar la clave de cualquier cédula enviando un `POST` directo. | Token de recuperación firmado de un solo uso vinculado criptográficamente al `id_usuario` en Redis. |
| **4** | **IDOR masivo en archivos y trámites** | `verSoporte($id)`, `verCartaRenuncia($id)` y `cambiarEstado($id)` no verificaban que el registro perteneciera al usuario autenticado. | Querysets filtrados a nivel de servidor (`filter(usuario=request.user)`) + permisos de objeto `IsOwnerOrRHAdmin` + UUIDs. |
| **5** | **Firmas PNG y documentos en carpeta pública** | Guardados en `storage/app/public/firmas/...` y `soportes/...`, accesibles sin login por URL directa. | Bóveda privada fuera de rutas públicas (`PRIVATE_MEDIA_ROOT`). Descarga solo tras validar sesión y permisos. |
| **6** | **Falta total de Rate Limiting en Login y OTP** | Se podían probar los 900.000 códigos OTP de 6 dígitos por fuerza bruta sin bloqueo. | Rate limiting por IP + Usuario en Redis y destrucción automática del OTP al 3er intento fallido. |
| **7** | **Bugs de persistencia e inconsistencias** | `ruta_firma` y `fecha_emision` fuera de `$fillable`; typo `$request->tip_sangr` borraba el tipo de sangre; `VisualizarDocumentosController` ignoraba documentos asignados por persona; párrafo duplicado en plantilla PDF de permisos. | Serializers tipados en Django, tests automatizados por flujo y plantillas HTML/CSS limpias para PDFs. |

---

## 6. Nuevo Stack y Arquitectura de Seguridad Blindada (`rh_solutionsv2`)

### 6.1. El Nuevo Stack Tecnológico
- **Ejecución Híbrida Optimizada para Windows:**
  - **En Local (Velocidad nativa e IDE):**
    - **Backend API:** **Python `3.12.9`** (gestionado con **`uv`**) + **Django `5.2 LTS`** + **Django REST Framework (DRF)** + **Django Channels** (WebSockets).
    - **Analítica y Datos:** **Pandas `2.2+`** + **NumPy** para reportes de ausentismo, rotación, vencimiento documental y costos de contratación.
    - **Motor de PDFs:** **WeasyPrint / ReportLab** renderizando plantillas limpias con sello criptográfico `SHA-256`.
    - **Frontend:** **Node.js `v24.18`** + **Next.js `15` (App Router, React 19, TypeScript)** + **Tailwind CSS v4** + **TanStack Table v8** (reemplazo moderno de jQuery DataTables) + **TanStack Query** + **Zod + React Hook Form**.
  - **En Docker (`docker-compose.yml`):**
    - **Base de Datos:** **PostgreSQL `17-alpine`** (puerto dedicado para no colisionar con otros proyectos).
    - **Visor Web de BD:** **pgweb (`sosedoff/pgweb`)** autoconectado a PostgreSQL sin logins manuales.
    - **Cache, Sesiones, Rate Limit, Broker y WebSockets:** **Redis `7-alpine`** con persistencia AOF.
    - **Colas y Tareas Programadas:** **Celery Worker** + **Celery Beat** corriendo sobre contenedor Linux para evitar las limitaciones de `prefork` en Windows.

---

### 6.2. Los 20 Pilares de Seguridad Blindada ("El Frontend muestra, el Backend decide")

1. **HTTPS Obligatorio y Transporte Seguro:**
   - En producción: `SECURE_SSL_REDIRECT = True`, `SECURE_PROXY_SSL_HEADER`, cookies con flag `Secure=True` y `Strict-Transport-Security` (HSTS por 1 año con `includeSubDomains`).
2. **JWT Bien Firmado y Validado (`HS256` / `RS256` con clave dedicada):**
   - Firma criptográfica independiente de `SECRET_KEY`, validando estrictamente `iss` (issuer), `aud` (audience), `exp` (expiration), `iat` y `jti` (identificador único de token en Redis).
3. **Tokens de Corta Duración + Refresh Token con Rotación:**
   - `access_token` de **5 a 10 minutos** de vida.
   - `refresh_token` de **7 días** con rotación automática en cada refresco (`ROTATE_REFRESH_TOKENS = True`) y detección de robo: si un `refresh_token` ya rotado vuelve a usarse, se revoca toda la familia de sesiones del usuario en Redis.
4. **Tokens 100% en Cookies `HttpOnly` (Cero `localStorage` / `sessionStorage`):**
   - Ningún token ni dato sensible se guarda jamás en `localStorage`, `sessionStorage` ni cookies accesibles por `document.cookie`.
   - Configuración de cookies: `HttpOnly=True`, `SameSite='Lax'` (o `'Strict'`), `Secure=True` (en prod) y `Path` restringido (`/api/v1/auth/refresh/` para el refresh token).
5. **Contraseñas con Hash Argon2 (`Argon2PasswordHasher`):**
   - `Argon2id` (`argon2-cffi`) como algoritmo principal de Django (ganador del Password Hashing Competition, resistente a ataques por GPU/ASIC), manteniendo `BCryptPasswordHasher` como segundo en la lista para poder migrar de forma transparente los hashes `$2y$12$...` existentes en la base de datos antigua.
6. **Autorización en Cada Endpoint (Deny by Default):**
   - Configuración global de DRF: `DEFAULT_PERMISSION_CLASSES = ['rest_framework.permissions.IsAuthenticated']`. Ningún endpoint queda abierto por olvido.
7. **Roles y Permisos desde el Servidor, Nunca desde el Cliente:**
   - El permiso se evalúa en el backend consultando el rol real y el `id_estado` del usuario en caché/BD en cada request. Si el usuario pasa a `Desvinculado`, queda fuera en el acto.
8. **Bloqueo de Asignación Masiva (Anti-Mass Assignment):**
   - Separación estricta entre `ReadSerializer` y `WriteSerializer` en DRF. Campos como `id_usuario`, `rol`, `id_estado`, `estado`, `radicado`, `ruta_cert`, `pdf_aprobacion` o `tiempo_espera` son estrictamente `read_only` o asignados en la capa de servicio del backend, ignorando cualquier campo extra inyectado en el JSON.
9. **No Confiar en Cabeceras del Cliente (Anti-IP Spoofing):**
   - Configuración explícita de `NUM_PROXIES` al leer `X-Forwarded-For`. Ignorar cabeceras `X-Original-URL`, `X-Rewrite-URL` o `Host` no incluidos en `ALLOWED_HOSTS`.
10. **CORS Restringido (`django-cors-headers`):**
    - `CORS_ALLOWED_ORIGINS` limitado exclusivamente al dominio exacto del frontend Next.js (`http://localhost:3000` en dev), con `CORS_ALLOW_CREDENTIALS = True` y lista cerrada de métodos y cabeceras permitidas.
11. **Cabeceras de Seguridad (Equivalente a Helmet en Django + Next.js):**
    - `Content-Security-Policy (CSP)` sin `unsafe-eval` en producción.
    - `X-Content-Type-Options: nosniff`
    - `X-Frame-Options: DENY` (usando visor controlado para previsualización de PDFs).
    - `Referrer-Policy: strict-origin-when-cross-origin`
    - `Permissions-Policy: camera=(self), microphone=(), geolocation=()` (habilitando cámara solo en el propio origen para la captura de foto de perfil).
12. **Validación de Datos en el Backend (Doble Capa):**
    - Aunque Next.js valide con `Zod` para dar buena UX, el backend en Django re-valida tipos, rangos de fechas, longitudes, expresiones regulares, estados de negocio y cabeceras binarias reales de archivos (`python-magic` para verificar que un `.pdf` o `.png` sea realmente ese formato y no un ejecutable o script).
13. **Consultas 100% Parametrizadas (Anti-SQL Injection):**
    - Prohibido interpolar variables en strings SQL. Todo pasa por el ORM de Django; si algún reporte analítico complejo requiere SQL crudo para Pandas, se ejecuta exclusivamente con tuplas de parámetros (`cursor.execute(sql, [param1, param2])`).
14. **Protección XSS (Cross-Site Scripting):**
    - Escape automático en React/Next.js, prohibición de `dangerouslySetInnerHTML` con datos de usuario, sanitización de textos largos (`funciones`, `clausulas`, `motivo_ampliado`) en backend con `nh3`/`bleach` antes de inyectarlos en las plantillas HTML de generación de PDFs.
15. **Protección CSRF (Cross-Site Request Forgery):**
    - Token CSRF de Django (`csrftoken` + cabecera `X-CSRFToken`) obligatorio en todas las peticiones mutables (`POST`, `PUT`, `PATCH`, `DELETE`) que utilicen cookies `HttpOnly`.
16. **Rate Limiting Granular por Endpoint y Bloqueo por Intentos Fallidos (en Redis):**

| Scope / Endpoint | Límite Permitido | Ventana / Bloqueo |
| :--- | :--- | :--- |
| **`auth_login`** (`POST /api/v1/auth/login`) | **5 intentos** por IP + Documento | Bloqueo temporal de **15 minutos** tras 5 fallos consecutivos. |
| **`otp_request`** (Envío de OTP Login / Firma / Reset) | **3 envíos** por Usuario/IP | Ventana de **15 minutos** (cooldown mínimo de 60s entre reenvíos). |
| **`otp_verify`** (Verificación de código OTP de 6 dígitos) | **3 intentos** por código emitido | Al 3er fallo el código se **destruye en Redis** y exige generar uno nuevo. |
| **`password_reset`** (Solicitud de recuperación de clave) | **3 solicitudes** por IP / Cédula | Ventana de **30 minutos**. Respuesta genérica para evitar enumeración. |
| **`file_upload`** (Subida de documentos, soportes, firma) | **10 subidas** por Usuario | Ventana de **1 minuto** (peso máximo validado en Nginx/ASGI: 5MB–10MB). |
| **`pdf_generation`** (Emisión/Preview de PDFs) | **10 generaciones** por Usuario | Ventana de **1 minuto**. |
| **`api_authenticated`** (Tráfico general autenticado) | **120 peticiones** por Usuario | Ventana de **1 minuto**. |
| **`api_anonymous`** (Endpoints públicos como catálogos/login) | **30 peticiones** por IP | Ventana de **1 minuto**. |

17. **Errores Genéricos sin Detalles Internos:**
    - Manejador global de excepciones en DRF: ante cualquier fallo inesperado (`500`) o error de base de datos, el cliente recibe únicamente `{ "error": "Error interno del servidor", "code": "INTERNAL_ERROR", "trace_id": "<uuid>" }`. Jamás se exponen stacktraces, nombres de tablas ni rutas del servidor.
18. **Secretos en Variables de Entorno Validadas al Arranque:**
    - Cero credenciales en el repositorio. Validación estricta al iniciar Django: si falta `SECRET_KEY`, `JWT_SIGNING_KEY`, `DATABASE_URL` o `REDIS_URL`, el proceso falla inmediatamente con un mensaje claro.
19. **Dependencias Actualizadas y Bloqueadas (`uv.lock` y `pnpm-lock.yaml`):**
    - Versiones fijadas con hashes de integridad y auditoría periódica con `pip-audit` / `pnpm audit`.
20. **Logs Estructurados, Auditoría y Monitoreo:**
    - Logs técnicos en formato JSON estructurado (con `trace_id`, `user_id`, `ip`, `path`, `status_code`, `latency_ms`) sin registrar nunca contraseñas, tokens ni códigos OTP en los archivos de log.
    - Tabla `audit_logs` en PostgreSQL para auditoría funcional y legal de RRHH.

---

## 7. Transformación de UX/UI (De Blade/jQuery a Next.js + Tailwind CSS)

1. **Adiós a jQuery DataTables y Recargas Completas:**
   - Todas las tablas del sistema (Usuarios, Contratos, Certificados, Documentos, Permisos, Renuncias e Historiales) pasan a un componente unificado sobre **TanStack Table v8 + Tailwind CSS**, con paginación, búsqueda con *debounce*, filtros por estado/dependencia, ordenamiento server-side y exportación limpia a Excel/PDF desde el backend con Pandas.
2. **Layouts Separados y Persistentes (App Router):**
   - `(auth)`: Login con transición fluida al paso de OTP 2FA en el mismo contenedor sin recargar la página (corrigiendo el bug del doble envío de OTP del sistema viejo) y flujo guiado Step-by-Step para recuperar contraseña.
   - `(employee)`: Portal del colaborador con barra lateral moderna, indicadores de estado de sus trámites, previsualizador de PDFs integrado en un *Drawer/Modal* seguro y campana de notificaciones en vivo por WebSockets.
   - `(admin)`: Consola de Talento Humano con **Dashboard Analítico impulsado por Pandas** (KPIs de personal activo por dependencia, contratos próximos a vencer, semáforo de cumplimiento documental, ausentismo por permisos y tasa de rotación), bandejas de aprobación en un clic y visor rápido de soportes.
3. **Flujo de Firma Electrónica y Previsualización Transparente:**
   - Captura o subida de firma con recorte/previsualización instantánea en cliente antes de subir el PNG validado al backend.
   - Previsualización en vivo de la Carta de Renuncia y Solicitud de Permiso antes de estampar la firma con OTP.
