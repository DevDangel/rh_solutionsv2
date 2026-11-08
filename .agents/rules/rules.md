# RULES · RH Solutions v2

> Leyes y estándares obligatorios de codificación, arquitectura de capas y flujo de trabajo.
> Todo desarrollador o agente de IA (`/columbus`, `/einstein`, `/dev`, `/desing`) debe cumplir estas normas sin excepción.
>
> - Para directivas de seguridad y bugs prohibidos del RH viejo → [`.agents/rules/security_rules.md`](./security_rules.md)
> - Para identidad visual, tablas modernas y modales → [`.agents/rules/design_rules.md`](./design_rules.md)
> - Para adaptabilidad móvil y breakpoints → [`.agents/rules/responsive_rules.md`](./responsive_rules.md)
> - Para desacople de componentes > 250 líneas → [`.agents/workflows/refactor-300.md`](../workflows/refactor-300.md)
> - Para migración de módulos desde el repo viejo → [`.agents/workflows/migracion-modulo.md`](../workflows/migracion-modulo.md)
> - Para comprensión general del sistema → [`documentation/ARCHITECTURE.MD`](../../documentation/ARCHITECTURE.MD)

**Principio rector:** Construir software limpio, seguro, modular y mantenible sin sobre-ingeniería. **El humano tiene siempre la última palabra** — la IA investiga en silencio, propone con argumentos técnicos y espera confirmación antes de tocar el código.

---

## 1. Flujo de Trabajo Obligatorio

### 1.1 Entender antes de tocar
1. **Inspección previa en silencio (Código + Base de Datos Real):** Leer siempre los archivos reales afectados (modelos, serializers, servicios, vistas, componentes React, stores) y consultar la fuente de la verdad en la base de datos PostgreSQL 17 dockerizada antes de opinar o proponer:
   ```bash
   docker exec rh_solutions_postgres psql -U rh_admin -d rh_solutions_v2 -c "\d <nombre_tabla>"
   ```
   Si estamos migrando con `/columbus`, inspeccionar primero el módulo equivalente en `C:\laragon\www\rh_solutions` y cruzarlo con la base de datos en Docker mediante el subagente `explorer`.
2. **Consistencia con el código vecino:** Identificar y respetar el patrón que ya utilizan los archivos del proyecto; no introducir librerías ni estilos ajenos al stack.
3. **Debate técnico honesto:** Si una petición tiene riesgos de seguridad, rompe una invariante o puede resolverse de una forma más limpia, advertirlo con franqueza y proponer la alternativa antes de ejecutar.

### 1.2 Propuesta antes de código (Freno de Aprobación)
Salvo correcciones triviales de una línea (un typo o un import faltante), la IA **nunca escribe ni modifica código sin aprobación explícita del usuario** (`"dale"`, `"implementa"`, `"procede"`, `"hazlo"`).

Si el cambio toca más de 3 archivos, migra un módulo, modifica contratos de API, altera tablas o toca lógica de negocio sensible, se debe presentar una propuesta clara acompañada de esta tabla resumen:

```markdown
### PROPUESTA — [Descripción corta del módulo o cambio]

| | |
|---|---|
| **Objetivo** | Qué se logra y qué problema o módulo resuelve |
| **Archivos afectados** | `rh_backend/apps/...`, `rh_frontend/src/components/...` |
| **Enfoque técnico** | Cómo se resuelve, qué tablas toca y por qué |
| **Seguridad y Bugs corregidos** | Qué se protege (y qué bugs del RH viejo se corrigen si es migración) |
| **Alternativas descartadas** | Opción B y por qué se descartó |
```

### 1.3 Al cerrar una tarea
Explicar qué se construyó o ajustó, qué se verificó con pruebas reales y qué queda pendiente o como siguiente paso natural.

---

## 2. Nomenclatura, Estilo y Legibilidad

1. **Variables semánticas:** Prohibidas variables de una sola letra con carga de negocio (`u`, `p`, `d`, `x`). Si la variable representa una entidad del dominio, su nombre debe decirlo claramente: `usuario_actual`, `solicitud_permiso`, `contrato_activo` (única excepción: índices triviales de bucles cortos).
2. **Funciones y métodos cortos:** Una sola responsabilidad. Si una función o método supera ~35–40 líneas o anida más de 3 niveles de condicionales, extraer a funciones auxiliares o métodos del servicio.
3. **DRY sin sobre-abstraer:** Repetir dos veces se tolera; a la tercera se extrae a un hook (`src/hooks/`), componente base (`src/components/ui/`) o servicio (`services.py`).
4. **Idioma del dominio:** Español neutro para conceptos de negocio, base de datos, endpoints y variables de dominio (`usuario`, `contrato`, `permiso`, `certificado`, `renuncia`); inglés únicamente para palabras reservadas del lenguaje o convenciones técnicas estándar (`created_at`, `request`, `response`, `payload`).
5. **Tuteo estándar (Prohibido el Voseo):** En textos de interfaz, alertas, placeholders, modales y mensajes de validación se usa siempre tuteo estándar ("puedes", "ingresa", "selecciona"). Queda prohibido el voseo ("podés", "ingresá").
6. **Comentarios útiles:** Máximo 1–2 líneas y solo cuando explican el *porqué* de una regla de negocio o decisión no obvia, nunca el *qué* evidente del código.

---

## 3. Backend (Python 3.12 · Django 5.2 LTS · DRF)

### 3.1 Contratos de Entrada (`InputSerializer` obligatorio)
Toda ruta `POST`, `PUT` o `PATCH` que reciba datos del cliente debe validar su entrada mediante una clase `Serializer` dedicada (`*InputSerializer`) dentro de `serializers.py`.
- **[PROHIBIDO]** Leer campos crudos de `request.data.get('campo')` en la vista sin pasar primero por un `InputSerializer` con `serializer.is_valid(raise_exception=True)`.
- **[PROHIBIDO]** Realizar llamadas HTTP externas síncronas o envíos de correo SMTP bloqueantes dentro de los métodos `validate_*` del Serializer.
- **[REGLA]** Toda validación de formato, tipos, rangos de fechas y existencia de claves foráneas se declara en el `*InputSerializer`.

### 3.2 Contratos de Salida (`OutputSerializer` obligatorio)
Toda respuesta JSON que devuelva entidades o listados debe serializarse mediante un `*OutputSerializer` explícito en `serializers.py`.
- **[PROHIBIDO]** Retornar diccionarios armados a mano con `.values()` de un modelo completo o exponer campos sensibles como `contrasena`, hashes OTP o rutas internas del sistema de archivos.
- **[PROHIBIDO]** Ejecutar consultas SQL adicionales (N+1) dentro de `SerializerMethodField` sin haber cargado previamente las relaciones con `select_related()` o `prefetch_related()` en el `selector`.
- **[REGLA]** Definir siempre una lista blanca explícita de campos (`fields = [...]`); queda prohibido el uso de `fields = '__all__'`.

### 3.3 Convención en Base de Datos PostgreSQL (ASCII Estricto y 3NF)
Para garantizar integridad referencial, rendimiento y compatibilidad total entre PostgreSQL 17, Django ORM y Pandas:
- **[PROHIBIDO]** Utilizar caracteres fuera del estándar ASCII en nombres de tablas, columnas, claves foráneas, primarias o índices (cero tildes, prohibida la letra `ñ` y diéresis `ü`).
- **[REGLA]** Todos los identificadores de base de datos van en español usando exclusivamente `snake_case` con el alfabeto inglés (`[a-z0-9_]`).
  - Correcto: `observacion`, `descripcion`, `fecha_nacimiento`, `id_estado_permiso`.
  - Prohibido: `observación`, `descripción`, `año`, `contraseña`.
- **[REGLA 3NF]** Ningún estado (`Activo`, `Pendiente`, `Aprobado`, `Rechazado`, `Vencido`) ni catálogo (`CC`, `O+`, `Masculino`, `EPS`) se guarda como texto libre o `ENUM` suelto: siempre apunta mediante clave foránea a su tabla de catálogo correspondiente definida en [`seeders/init_postgres.sql`](../../seeders/init_postgres.sql).

### 3.4 Vistas, Servicios y Selectores
- **Vistas (`views.py`):** Delgadas. Solo orquestan permisos, `InputSerializer`, llamada al servicio/selector y retorno con `OutputSerializer`.
- **Servicios (`services.py`):** Contienen toda la lógica de negocio de escritura (`create`, `update`, cambios de estado, generación de radicados) envuelta en `transaction.atomic()` cuando toca más de una tabla.
- **Selectores (`selectors.py`):** Contienen las consultas de lectura optimizadas, filtros de búsqueda y paginación para las tablas y reportes.

---

## 4. Frontend (React 19 · Next.js 15 · TypeScript · Tailwind v4)

### 4.1 Estándar de Componentes y Estado
- **Componentes funcionales en TypeScript (`.tsx`)** con tipado explícito para `props` y respuestas de API (`src/types/`). Prohibido el uso de `any`.
- **Lógica reutilizable** → Custom Hooks en `src/hooks/`.
- **Estado global compartido en memoria** → Zustand en `src/stores/`.
- **Cliente HTTP único:** Exclusivamente `src/services/api.ts` (nunca usar `fetch()` ni `axios` crudo directamente en los componentes).
- **Cero jQuery y cero Bootstrap:** Queda prohibido importar jQuery, Bootstrap, Select2 o DataTables. Todo se construye con React 19, Tailwind CSS v4 y TanStack Table v8.

### 4.2 Límite Estricto de 300 Líneas Brutas en Componentes (`src/components/`)
1. **Tope estricto:** Ningún archivo `.tsx` o `.ts` dentro de `rh_frontend/src/components/` puede exceder las **300 líneas brutas totales** (la numeración real que marca el editor de principio a fin, incluyendo imports, tipos, JSX, comentarios y líneas en blanco). Vigilado por ESLint (`max-lines`).
2. **Franja preventiva (250 a 300 líneas brutas):** Todo componente que entre en el rango de **250 a 300 líneas** está en alerta preventiva y debe desacoplarse para bajar holgadamente por debajo de las 250 líneas.
3. **Prohibición de monolitos tipo legacy:** En el sistema viejo existían vistas de 1,200 líneas (como `gestionarUsuarios.blade.php`) que mezclaban la tabla principal con los modales de crear y editar. En RH Solutions v2, la tabla y cada modal viven siempre en archivos separados.
4. **Mandato de objeción activa para la IA (Freno al Prompter):**
   Si el usuario solicita añadir código, columnas, filtros o modales a un componente que ya ronda las **250 líneas** o que superará las **300 líneas** con el cambio, **la IA tiene terminantemente prohibido obedecer e insertar el código en ese archivo**. La IA debe frenar en seco, advertir que se viola el límite arquitectónico y proponer primero el desacople siguiendo [`.agents/workflows/refactor-300.md`](../workflows/refactor-300.md).

### 4.3 Organización Estricta por Ítem de la Sidebar
Cada sección del menú lateral (Sidebar) de cada rol (`admin/` y `empleado/`) vive en su propia subcarpeta nombrada en `snake_case` dentro de `src/components/<rol>/<item_sidebar>/`:

```text
src/components/
├── layout/
│   ├── Sidebar.tsx                  # Menú lateral azul institucional (#000050)
│   ├── Topbar.tsx                   # Barra superior blanca con notificaciones
│   └── DashboardShell.tsx           # Contenedor estructural del panel
├── ui/                              # Piezas transversales (AppPaginacion, ConfirmModal, FeedbackModal, Skeletons)
├── admin/
│   ├── dashboard/                   # Inicio Admin (KPIs y gráficas)
│   ├── usuarios/                    # Gestión de Usuarios (UsuariosTable, CrearUsuarioModal, EditarUsuarioModal, FichaUsuarioModal, CargosModal)
│   ├── documentos/                  # Gestión de Documentos (AsignacionTable, VisualizacionTable, SubirDocumentoModal)
│   ├── contratos/                   # Gestión de Contratos (ContratosTable, CrearContratoModal, EditarContratoModal, DetalleContratoModal)
│   ├── certificados/                # Gestión de Certificados (SolicitudesCertificadosTable, HistorialCertificadosTable, AprobarCertificadoModal)
│   ├── permisos/                    # Gestión de Permisos (AutorizarPermisosTable, HistorialPermisosTable, DetallePermisoModal)
│   └── renuncias/                   # Gestión de Renuncias (SolicitudesRenunciaTable, HistorialRenunciasTable, AceptarRenunciaModal)
└── empleado/
    ├── dashboard/                   # Inicio Empleado
    ├── mi_perfil/                   # Datos personales y consentimiento de firma digital
    ├── documentos/                  # Mis Documentos (subida y descarga segura)
    ├── certificados/                # Solicitar Certificados
    ├── permisos/                    # Solicitar Permiso y firma electrónica OTP
    └── renuncias/                   # Solicitar Renuncia y vista previa de carta
```

- El componente orquestador de la vista, su tabla (`*Table.tsx`), sus filtros (`*Filters.tsx`) y sus modales (`*Modal.tsx`) coexisten dentro de la subcarpeta del ítem de la sidebar comunicándose con imports relativos (`./CrearUsuarioModal`).

### 4.4 Modales y Notificaciones UI
- **[PROHIBIDO]** El uso de `alert()`, `confirm()` o `prompt()` nativos del navegador, así como librerías viejas acopladas al DOM. Toda confirmación de acción crítica o notificación de éxito/error debe utilizar los componentes UI nativos del proyecto (`ConfirmModal.tsx`, `FeedbackModal.tsx`).
- **[REGLA]** Todo modal que se dispare desde una fila de tabla o contenedor con transformaciones/sombras debe renderizarse mediante `createPortal(..., document.body)` de React para garantizar que el fondo oscurecido (`backdrop`) cubra toda la pantalla sin quedar recortado por el contenedor padre.

---

## 5. Herramientas, Linters y Cuidado del Entorno

- **Backend (Python):** `ruff check` y `ruff format --check`.
- **Frontend (Next.js / TypeScript):** `npx eslint` y `tsc --noEmit`.
- **[ATENCIÓN]** No ejecutar formateadores masivos sobre archivos que no fueron parte de la tarea actual para mantener el historial de `git diff` limpio.

---

*RH Solutions v2 · Leyes Oficiales de Ingeniería*
