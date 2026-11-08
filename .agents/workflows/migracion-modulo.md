# WORKFLOW · Migración de Módulo Legacy a Nuevo Stack

> Procedimiento operativo estricto para migrar cualquier módulo desde el monolito original (`C:\laragon\www\rh_solutions`) hacia la nueva arquitectura desacoplada (`C:\Project\rh_solutionsv2`).
> Es el protocolo obligatorio que sigue la skill **`/columbus`** junto con su subagente **`explorer`**.

---

## Propósito
Garantizar que la migración de cada módulo (Usuarios, Contratos, Documentos, Certificados, Permisos, Renuncias, Perfil y Dashboard) transporte el **100% de las reglas de negocio válidas** del sistema original, pero **erradique de raíz sus vulnerabilidades, bugs lógicos y malas prácticas visuales** (como las tablas de 23 columnas con flechas negras de DataTables o los monolitos Blade de 1,200 líneas).

---

## Procedimiento Estricto de 6 Pasos

### Paso 1: Radiografía en Vivo con el Subagente `explorer`
Antes de proponer nada, `/columbus` invoca a su subagente **`explorer`** ([`.agents/agents/explorer/agent.md`](../agents/explorer/agent.md)) indicándole el módulo exacto a investigar. `explorer` realiza en modo solo lectura:
1. **Inspección del Repo Original (`C:\laragon\www\rh_solutions`):** Lee el controlador PHP (`app/Http/Controllers/...`), el modelo Eloquent (`app/Models/...`), las rutas (`routes/web.php`) y las vistas Blade/CSS (`resources/views/...`, `public/css/...`) del módulo.
2. **Inspección de la Base de Datos Nueva en Docker (`rh_solutions_postgres`):** Consulta las tablas normalizadas en 3NF en PostgreSQL (`docker exec rh_solutions_postgres psql -U rh_admin -d rh_solutions_v2 -c "\d <tabla>"`) y revisa [`documentation/migrations.md`](../../documentation/migrations.md).
3. **Entrega de Radiografía:** `explorer` devuelve a `/columbus` la lista exacta de acciones del módulo, campos, validaciones, relaciones y los **bugs o agujeros de seguridad detectados en el código viejo**.

### Paso 2: Caza de Bugs Legacy y Traducción a 3NF
Con el informe de `explorer`, `/columbus` filtra el módulo contra [`.agents/rules/security_rules.md`](../rules/security_rules.md) y [`documentation/migrations.md`](../../documentation/migrations.md):
1. **¿Qué bugs tenía el módulo viejo?** (Ej. en *Permisos*: el código OTP devuelto en el JSON de `PermisosController.php:778`, los cambios de estado inconsistentes entre jefe y talento humano, o los soportes guardados en `public/storage`).
2. **¿Cómo cambian los campos de texto suelto a claves foráneas 3NF?** (Ej. pasar de guardar `'Aprobado'` o `'CC'` en texto a usar `id_estado_permiso`, `id_tipo_identificacion`, etc., tal como están sembrados en PostgreSQL).
3. **¿Cómo se transforma la tabla vieja de DataTables?** Definir cuáles son las **5 a 7 columnas esenciales** que irán en la tabla moderna (`*Table.tsx`) y qué campos secundarios pasarán al modal de detalle (`Ficha*Modal.tsx`).

### Paso 3: Presentación de la Propuesta y Freno de Aprobación
`/columbus` presenta al usuario en prosa clara y con la tabla de propuesta de [`.agents/rules/rules.md`](../rules/rules.md):
- Qué hacía el módulo en el RH viejo y **qué bugs/vulnerabilidades encontró `explorer` que vamos a corregir**.
- Qué endpoints se crearán en `rh_backend/apps/<modulo>/` (con sus `*InputSerializer`, `*OutputSerializer`, `services.py` y `selectors.py`).
- Qué componentes se crearán en `rh_frontend/src/components/<rol>/<item_sidebar>/` respetando el límite de 250–300 líneas y separando la tabla de sus modales.
- **Freno duro:** `/columbus` detiene su turno y espera una palabra positiva del usuario (`"dale"`, `"implementa"`, `"procede"`, `"hazlo"`). Jamás escribe código sin esa luz verde.

### Paso 4: Construcción del Backend (Django 5.2 DRF)
Una vez aprobado por el usuario, `/columbus` construye el backend del módulo cumpliendo:
1. Modelos en ASCII estricto sincronizados con las tablas de PostgreSQL (`rh_solutions_v2`).
2. Validación de entrada en `*InputSerializer` y formato de salida en `*OutputSerializer`.
3. Lógica de escritura en `services.py` con `transaction.atomic()` y `select_for_update()` cuando aplique.
4. Permisos (`IsAuthenticated` + verificación anti-IDOR) y `throttle_classes` en Redis.
5. Si el módulo maneja archivos o PDFs, almacenarlos en `PRIVATE_MEDIA_ROOT` con nombres UUID y servirlos por endpoint autenticado.

### Paso 5: Construcción del Frontend Modular (React 19 · Next.js 15)
Antes de escribir la llamada en el frontend, `/columbus` lee el `urls.py` y el `*OutputSerializer` recién creados para asegurar que el contrato coincida al 100%:
1. Crea los componentes dentro de `rh_frontend/src/components/<rol>/<item_sidebar>/`.
2. Separa la tabla moderna (`*Table.tsx`) de los modales (`Crear*Modal.tsx`, `Editar*Modal.tsx`, `Ficha*Modal.tsx`) para que ningún archivo se acerque a las 250–300 líneas brutas.
3. Conecta las llamadas mediante el cliente único `src/services/api.ts` (cookies `HttpOnly`, cero `localStorage`).

### Paso 6: Pruebas, Verificación Real y Bitácora en `migrations/`
Al terminar la implementación del módulo:
1. Verificar que las rutas y serializers de Django carguen sin errores (`python manage.py check`) y correr las pruebas del módulo.
2. Verificar en el frontend el conteo de líneas brutas (`< 250–300 líneas` por componente) y el tipado/linter en los archivos tocados.
3. Reportar al usuario con honestidad qué quedó funcionando y qué bugs del viejo quedaron sepultados.
4. **Pregunta obligatoria de cierre:** Preguntar al usuario si desea documentar el bloque completado en la carpeta raíz [`migrations/`](../../migrations/) bajo el estándar secuencial `NNN_migration_{que_se_migro}.md` (ej. `001_migration_login_estilos.md`, `002_migration_login_otpylogica.md`) o si continuamos con el siguiente paso.
