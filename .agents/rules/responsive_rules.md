# RESPONSIVE RULES · RH Solutions v2

> **[ESTADO: EN CALIBRACIÓN — PENDIENTE DEL PRIMER MÓDULO MIGRADO (USUARIOS)]**
>
> Este documento establece la base de adaptabilidad móvil en Tailwind CSS v4.
> El comportamiento responsive exacto de las nuevas **Tablas Modernas** y sus barras de herramientas (buscador, filtros y botones de exportación) se definirá y estandarizará aquí una vez probemos en pantalla el primer módulo migrado (**Gestión de Usuarios**).

---

## 1. Reglas Base que Aplican desde el Día Cero

1. **Filosofía Mobile-First en Tailwind CSS v4:**
   - La clase base sin prefijo (`w-full`, `flex-col`, `grid-cols-1`, `p-4`) maqueta para móviles pequeños (`0px` a `639px`).
   - El escalado hacia pantallas mayores se hace siempre hacia arriba con `sm:` (`640px`), `md:` (`768px`), `lg:` (`1024px`) y `xl:` (`1280px`).
   - **[PROHIBIDO]** Escribir `@media` queries manuales en archivos CSS para parchar vistas o invertir la cascada con `max-sm:`.
2. **Comportamiento del Layout (Sidebar + Topbar):**
   - En escritorio (`lg:` en adelante), la Sidebar azul (`#000050`) permanece fija a la izquierda (`300px`) y el contenido principal deja ese margen.
   - En pantallas menores (`< 1024px`), la Sidebar se oculta fuera del lienzo y se despliega suavemente como un drawer sobrepuesto al tocar el botón de menú en la Topbar.
3. **Formularios dentro de Modales:**
   - Los bloques de formulario que en escritorio van en 2 columnas (`md:grid-cols-2`) pasan automáticamente a 1 sola columna (`grid-cols-1`) en móvil para que ningún input quede aplastado.
4. **Cero Flechas Negras de Colapso Brusco en Tablas:**
   - Queda prohibido el patrón legacy de DataTables que colapsaba columnas con flechas negras triangulares empujando las filas. La adaptación responsive de las tablas (scroll horizontal limpio y/o vista compacta) se fijará al calibrar el módulo de **Usuarios**.

---

*RH Solutions v2 · Reglas Responsive (Fase de Calibración Inicial)*
