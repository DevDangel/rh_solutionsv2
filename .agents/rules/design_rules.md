# DESIGN RULES · RH Solutions v2

> **[ESTADO: EN CALIBRACIÓN — PENDIENTE DEL PRIMER MÓDULO MIGRADO (USUARIOS)]**
>
> Este documento contiene las directivas base de identidad visual heredadas de RH Solutions y las prohibiciones estrictas sobre componentes legacy.
> El estándar definitivo de clases para **Tablas Modernas, Botones de Exportación (Excel/PDF), Paginación, Filtros y Modales** se escribirá y congelará en este archivo inmediatamente después de construir, probar en pantalla y aprobar el primer módulo migrado (**Gestión de Usuarios**), para que el resto de los módulos del sistema mantengan 100% de equidad y transparencia visual.

---

## 1. Lo que se Conserva del Diseño Institucional de RH Solutions

1. **Sidebar Izquierda (`Sidebar.tsx`):**
   - Mantiene su identidad corporativa en azul marino institucional (`#000050` / `#02024D`), ancho fijo en escritorio (`300px`), texto blanco y submenús desplegables limpios para cada módulo.
   - Botón de Cerrar Sesión fijo en la parte inferior.
2. **Topbar Superior (`Topbar.tsx`):**
   - Barra blanca limpia (`70px` de alto) con sombra sutil, botón de apertura de menú en pantallas móviles y campana de notificaciones a la derecha.
3. **Área de Contenido (`main-content`):**
   - Fondo claro de contraste (`#f8f9fa`) con tarjetas contenedoras blancas (`bg-white`), limpias y bien espaciadas.

---

## 2. Lo que Queda Terminantemente Prohibido del Legacy

1. **[PROHIBIDO] jQuery DataTables y las flechas negras colapsables (`dtr-inline.collapsed`):**
   - Queda erradicado el uso de DataTables y ese comportamiento donde las tablas ocultaban columnas poniendo una flecha negra triangular (`►` / `▼`) que al hacer clic metía bruscamente el contenido dentro de la fila.
2. **[PROHIBIDO] Tablas saturadas de 15 o 23 columnas:**
   - Ninguna tabla principal mostrará todas las columnas de la base de datos de golpe. Las tablas mostrarán únicamente las **5 a 7 columnas clave** para escanear rápido, y el resto de la información se consultará mediante un botón limpio de **"Ver ficha / Detalle"** en un modal estructurado.
3. **[PROHIBIDO] Modales de Bootstrap acoplados al DOM o alertas nativas (`alert`, `confirm`):**
   - Los modales conservan la línea limpia blanca con encabezados en azul `#02024D` y formularios organizados por bloques de 2 columnas, pero construidos de forma nativa en React + Tailwind CSS v4 con `createPortal(..., document.body)`.

---

## 3. Secciones que se Consolidarán tras el Módulo 1 (Gestión de Usuarios)

Una vez validado visualmente el módulo de **Gestión de Usuarios**, se documentarán aquí las plantillas exactas para todos los módulos:
- [ ] Estructura exacta de la **Tabla Moderna** (TanStack Table v8 + Tailwind v4).
- [ ] Barra superior de tabla: buscador con debounce, filtros por estado/catálogo y botones de exportación a Excel/PDF.
- [ ] Componente oficial de **Paginación** y selector de filas por página.
- [ ] Plantilla estándar de **Modales** (Crear, Editar, Ver Ficha Completa y Confirmación) y **Skeletons de carga**.

---

*RH Solutions v2 · Reglas de Diseño Visual (Fase de Calibración Inicial)*
