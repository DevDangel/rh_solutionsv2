# AGENTS · RH Solutions v2

Instrucciones obligatorias para cualquier asistente de IA o desarrollador que trabaje en este repositorio.

## Lee esto primero

Antes de escribir o modificar una sola línea de código, consulta los documentos de gobernanza del framework en `.agents/rules/`, `.agents/workflows/` y `documentation/`:

| Documento | Qué contiene | Cuándo es obligatorio |
|---|---|---|
| **[`.agents/rules/rules.md`](.agents/rules/rules.md)** | Estándares de código (Django Serializers de entrada/salida, BD en ASCII, límite de 300 líneas brutas y estructura por ítem del sidebar) | **Siempre** — define cómo se construye y se organiza el código |
| **[`.agents/rules/security_rules.md`](.agents/rules/security_rules.md)** | Reglas de oro, recetas de backend/frontend, tabla de bugs reales del RH viejo prohibidos y checklist de cierre | Antes de tocar endpoints, formularios, auth, archivos privados o datos de usuario |
| **[`.agents/rules/design_rules.md`](.agents/rules/design_rules.md)** | Identidad visual RH (`#000050` / `#02024D`), Layout Shell, prohibición de DataTables/flechas colapsables, tablas modernas y modales | Al crear o modificar vistas, tablas, modales y submódulos de dashboards |
| **[`.agents/rules/responsive_rules.md`](.agents/rules/responsive_rules.md)** | Filosofía mobile-first en Tailwind v4, breakpoints y adaptación móvil/tablet | Al tocar maquetación, componentes visuales, formularios o tablas |
| **[`.agents/workflows/refactor-300.md`](.agents/workflows/refactor-300.md)** | Procedimiento paso a paso para modularizar componentes React (`.tsx`) > 250 líneas | Al refactorizar o al detectar un componente en franja preventiva (250–300 líneas) |
| **[`.agents/workflows/migracion-modulo.md`](.agents/workflows/migracion-modulo.md)** | Protocolo de 6 pasos para migrar módulos desde `C:\laragon\www\rh_solutions` sin arrastrar deuda ni bugs | **Obligatorio** al migrar cualquier módulo con `/columbus` |
| **[`.agents/skills/`](.agents/skills/)** | Roles y protocolos operativos (`columbus`, `einstein`, `dev`, `desing`) | Al asumir una tarea o cuando el usuario invoca un comando `/` |
| **[`documentation/ARCHITECTURE.MD`](documentation/ARCHITECTURE.MD)** | Stack oficial, modelo de autenticación por Cookie `HttpOnly`, topología de carpetas, colas en Redis y WebSockets | Para entender cómo está construido el sistema |
| **[`documentation/migrations.md`](documentation/migrations.md)** | Auditoría completa del monolito viejo (`C:\laragon\www\rh_solutions`), los 8 módulos, las 44 tablas en 3NF y los 20 pilares de seguridad | Al consultar reglas de negocio del sistema original o auditar migraciones |

> **[IMPORTANTE]** [`.agents/rules/security_rules.md`](.agents/rules/security_rules.md) documenta vulnerabilidades críticas reales detectadas en el monolito original (`C:\laragon\www\rh_solutions`), incluyendo el filtrado de códigos OTP en respuestas JSON del módulo de permisos, inyecciones SQL, IDORs y archivos sensibles en rutas públicas. Reintroducir cualquiera de esos patrones está terminantemente prohibido.

---

## El proyecto en 30 segundos

Plataforma SaaS corporativa de Gestión de Recursos Humanos y Talento Humano para PYMEs (control de empleados, contratos, expediente digital de documentos con alertas de vencimiento, certificados laborales en PDF, permisos con firma electrónica OTP, renuncias y notificaciones en tiempo real).

```text
rh_backend/       Python 3.12 · Django 5.2 LTS · DRF · Channels · Pandas · WeasyPrint · Redis
rh_frontend/      React 19 · Next.js 15 (App Router) · TypeScript · Tailwind CSS v4 · TanStack Table v8 · Zustand
seeders/          Esquema maestro PostgreSQL 17 en 3NF (44 tablas: 27 catálogos + 17 operativas)
.agents/          Framework de gobernanza de IA (rules/, workflows/, skills/ y agents/)
```

---

## Las que nunca se rompen (Invariantes del Sistema)

1. **El backend decide, el frontend refleja.** La sesión y los tokens viven exclusivamente en cookies `HttpOnly`, `SameSite=Lax`; jamás en `localStorage` ni `sessionStorage`.
2. **Toda entrada se valida en backend mediante un `InputSerializer` dedicado.** Cero validaciones sueltas leyendo `request.data.get()` en las vistas o controladores.
3. **Toda salida estructurada usa un `OutputSerializer` explícito.** Prohibido exponer instancias de modelos Django crudas, diccionarios sin contrato o detalles de excepciones (`str(e)`).
4. **Base de datos PostgreSQL en ASCII estricto y Tercera Forma Normal (3NF).** Prohibido el uso de tildes, `ñ` o mayúsculas en nombres de tablas, columnas, índices o migraciones (`rules/rules.md` sección 3.3). Los estados y catálogos siempre van normalizados por clave foránea (`id_estado`, `id_rol`, etc.), nunca como texto libre.
5. **Cero tareas pesadas o llamadas HTTP/SMTP síncronas bloqueando el request.** Generación masiva de PDFs, envíos de correos SMTP y cruces pesados se despachan a colas en Redis.
6. **Español neutro con tuteo estándar** (`usuario`, `empleado`, `permiso`, placeholders, modales). Está prohibido el uso de voseo ("podés", "dejá"). Usa siempre tuteo ("puedes", "deja").
7. **Límite estricto de 300 líneas brutas y diseño modular en frontend (`rh_frontend/src/components/`):**
   - Ningún archivo `.tsx` o `.ts` bajo `src/components/` puede superar las **300 líneas brutas totales** en el editor.
   - **Franja preventiva (250 a 300 líneas):** desacoplar piezas secundarias (modales, cabeceras, filtros, tarjetas) para asegurar margen de crecimiento.
   - **Freno activo para la IA:** Si se solicita agregar código a un componente que ronda las 250 líneas o superará las 300, la IA tiene terminantemente prohibido obedecer e insertar el código en el monolito. Debe exigir la refactorización modular previa siguiendo [`.agents/workflows/refactor-300.md`](.agents/workflows/refactor-300.md).
8. **Estructura estricta por ítem del sidebar y prohibición de jQuery DataTables:**
   - Cada módulo del menú lateral vive en su propia subcarpeta en `snake_case` dentro de `src/components/<rol>/<item_sidebar>/` (`admin/usuarios/`, `admin/permisos/`, `empleado/certificados/`, etc.), separando la tabla principal de sus modales (`Crear*Modal.tsx`, `Editar*Modal.tsx`, `Ficha*Modal.tsx`).
   - Queda prohibido el estilo legacy de DataTables con flechas negras colapsables (`►` / `▼`) o tablas de 20+ columnas que rompan el layout. Las tablas principales muestran entre 5 y 7 columnas clave y delegan el resto del expediente al modal de detalle.

---

## Acceso a Base de Datos Local y Repositorio Legacy (Inspección y Verdad)

Los asistentes de IA y sus subagentes (`explorer`, `einstein_jr`) tienen permiso para ejecutar consultas de **solo lectura e inspección** sobre la base de datos PostgreSQL 17 dockerizada:

```bash
docker exec rh_solutions_postgres psql -U rh_admin -d rh_solutions_v2 -c "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public';"
```

- **Visor web (`pgweb`):** `http://localhost:7070`
- **Puerto PostgreSQL en host:** `localhost:5435` (Base de datos: `rh_solutions_v2` · Usuario: `rh_admin`)
- **Puerto Redis en host:** `localhost:6380`
- **Repositorio Legacy (solo lectura para migración con `/columbus` y `explorer`):** `C:\laragon\www\rh_solutions`

> **[ATENCIÓN]** Las credenciales locales (`rh_admin / rh_secret_2026`) aplican **exclusivamente al entorno local de desarrollo en Docker**. Bajo ninguna circunstancia deben utilizarse ni asumirse para entornos de pruebas o producción.

---

## Antes de dar algo por terminado

Pasa el checklist de [`.agents/rules/security_rules.md`](.agents/rules/security_rules.md) sección 5 y verifica que el código respete el límite de líneas y los contratos entre capas.

---

*RH Solutions v2 · Gobernanza de Ingeniería e IA*
