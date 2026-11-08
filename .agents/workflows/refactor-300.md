# WORKFLOW · Refactorización Modular (< 300 Líneas)

> Procedimiento operativo obligatorio de desacople en el frontend (`rh_frontend/src/components/`).
> Se ejecuta siempre que un componente `.tsx` o `.ts` entre en la franja preventiva (**250 a 300 líneas brutas**) o cuando una tarea nueva amenace con superar las 300 líneas.

---

## Invocación
- **Manual:** Solicitado por el usuario (`"aplica el refactor-300"`, `"desacopla este componente"`).
- **Automática (Freno Activo de la IA):** Disparada obligatoriamente por `/columbus`, `/dev` o `/desing` cuando el usuario pida agregar código, columnas, filtros o modales a un componente que ya ronda las **250 líneas** o que superaría las **300 líneas brutas** con el cambio (ver [`.agents/rules/rules.md`](../rules/rules.md) sección 4.2).

---

## Procedimiento Estricto de 5 Pasos

### Paso 1: Medición y Diagnóstico
1. Contar las líneas brutas reales del archivo en el editor (incluyendo imports, interfaces TypeScript, JSX, comentarios y líneas en blanco).
2. Identificar los bloques que están inflando el archivo:
   - Modales de creación, edición, confirmación o visualización de ficha embebidos en la misma vista.
   - Barras de filtros, buscadores y botones de exportación extensos.
   - Secciones de formularios largos (ej. *Datos personales*, *Residencia*, *Seguridad social*).
   - Sub-tablas o tarjetas repetitivas dentro de `.map()`.

### Paso 2: Extracción de Modales y Piezas Pesadas (> 300 líneas brutas)
1. **Modales:** Extraer cada modal a su propio archivo dedicado dentro de la misma carpeta del módulo (`Crear*Modal.tsx`, `Editar*Modal.tsx`, `Ficha*Modal.tsx`), renderizado siempre con `createPortal(..., document.body)`.
2. **Formularios extensos:** Si un modal de formulario (como el de Crear/Editar Usuario) supera por sí solo las 250 líneas, dividir sus bloques internos en subcomponentes limpios (`SeccionDatosPersonales.tsx`, `SeccionSeguridadSocial.tsx`) o extraer la lógica de estado/validación a un custom hook (`useUsuarioForm.ts` en `src/hooks/`).

### Paso 3: Ubicación en la Carpeta del Ítem de la Sidebar
1. Alojar todos los subcomponentes extraídos dentro de la subcarpeta correspondiente al ítem de la sidebar:
   `rh_frontend/src/components/<rol>/<item_sidebar>/`
2. El componente principal del módulo actúa únicamente como **orquestador delgado**: coordina qué modal se abre, pasa callbacks y conecta la tabla con la barra de herramientas.
3. Conectar padre e hijos mediante `props` tipadas en TypeScript usando imports relativos (`./CrearUsuarioModal`).

### Paso 4: Franja Preventiva de Seguridad (< 250 líneas brutas)
1. Si tras extraer los modales el componente de la tabla o el orquestador sigue entre **250 y 300 líneas brutas**:
   - Extraer la barra superior de búsqueda/filtros/exportación a `*Toolbar.tsx` o `*Header.tsx`.
   - Extraer la definición de columnas de TanStack Table si es muy extensa a un archivo auxiliar o hook dentro del módulo.
2. El archivo principal y cada uno de sus subcomponentes deben quedar **holgadamente por debajo de las 250 líneas brutas** para dejar margen de crecimiento futuro (*headroom*).

### Paso 5: Verificación Física Obligatoria
1. Comprobar el conteo real de líneas de todos los archivos creados o modificados para certificar que ninguno alcance las 300 líneas brutas.
2. Verificar que los tipos de TypeScript (`tsc --noEmit`) y ESLint (`npx eslint`) sobre los archivos tocados pasen con 0 errores y sin imports huérfanos.
