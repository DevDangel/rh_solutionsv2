# RH Solutions v2 — Plataforma Corporativa de Gestión de Talento Humano

Bienvenido al repositorio oficial de **RH Solutions v2**, la evolución desacoplada, segura y de alto rendimiento del sistema de Gestión de Recursos Humanos para PYMEs.

---

## 1. Introducción al Proyecto

**RH Solutions v2** centraliza el ciclo de vida laboral de los colaboradores de una organización en una arquitectura moderna **API REST + SPA**:

- **Gestión de Empleados y Cargos:** Expediente completo normalizado en Tercera Forma Normal (3NF), seguridad social (EPS, Pensión, ARL, Caja de Compensación), licencias de conducción y control de estado laboral.
- **Gestión de Contratos:** Vinculación laboral, tipos y tiempos de contrato, salario, dependencias y prórrogas.
- **Expediente Digital de Documentos:** Asignación de documentos requeridos por empleado, bóveda privada de archivos, semáforo automático de vencimientos (`Vigente`, `Por vencer`, `Vencido`) y alertas por correo/WebSockets.
- **Certificados Laborales en PDF:** Solicitud con control de tiempo de espera (*cooldown*), autorización administrativa y expedición de certificados en PDF.
- **Permisos e Incapacidades con Firma Electrónica OTP:** Cálculo automático de días y horas hábiles (con festivos de Colombia), flujo de firma digital con código OTP de un solo uso y aprobación por Jefe Inmediato y Talento Humano.
- **Gestión de Renuncias:** Radicación con previsualización de carta en PDF, carta de aceptación y desactivación programada en la fecha efectiva de retiro.

### Stack Tecnológico Oficial

| Capa | Tecnología |
|---|---|
| **Backend (`rh_backend/`)** | Python `3.12.9` · Gestor `uv` · Django `5.2 LTS` · Django REST Framework · Django Channels · Pandas · WeasyPrint |
| **Frontend (`rh_frontend/`)** | Node.js `v24.18.0` · React `19` · Next.js `15` · TypeScript · Tailwind CSS `v4` · TanStack Table `v8` · Zustand |
| **Base de Datos (Docker)** | PostgreSQL `17-alpine` (`rh_solutions_postgres`, puerto `5435`, 44 tablas en 3NF) + visor `pgweb` (`puerto 7070`) |
| **Caché y Colas (Docker)** | Redis `7-alpine` (`rh_solutions_redis`, puerto `6380`) + Celery / Celery Beat |
| **Gobernanza de IA** | [ `AGENTS.md` ](./AGENTS.md) · [ `.agents/` ](./.agents/) (`/columbus`, `/einstein`, `/dev`, `/desing`) · [ `documentation/` ](./documentation/) |

---

## 2. Paso a Paso para Dejar el Proyecto Corriendo

Sigue estos 3 bloques en orden para levantar todo el entorno de desarrollo local en Windows.

### Paso 1: Prender la Base de Datos y Redis en Docker Desktop

La base de datos PostgreSQL 17 (con las 44 tablas y los 27 catálogos maestros ya sembrados), el visor web `pgweb` y `Redis` corren en contenedores definidos en [`docker-compose.yml`](./docker-compose.yml).

1. Abre **Docker Desktop** en Windows y espera a que el motor esté en verde (*Engine running*).
2. Abre una terminal PowerShell en la raíz del proyecto (`C:\Project\rh_solutionsv2`) y ejecuta:
   ```powershell
   docker compose up -d
   ```
3. Verifica que los 3 contenedores estén activos (`Up / healthy`) desde Docker Desktop o corriendo:
   ```powershell
   docker ps
   ```

| Contenedor | Servicio | Puerto Local / URL | Credenciales de Desarrollo |
|---|---|---|---|
| **`rh_solutions_postgres`** | PostgreSQL `17-alpine` | `localhost:5435` | **BD:** `rh_solutions_v2`<br>**Usuario:** `rh_admin`<br>**Clave:** `rh_secret_2026` |
| **`rh_solutions_pgweb`** | Visor web de Base de Datos (`pgweb`) | **[http://localhost:7070](http://localhost:7070)** | *(Ingresa directo sin contraseña)* |
| **`rh_solutions_redis`** | Redis `7-alpine` | `localhost:6380` | *(Sin contraseña en red local)* |

> **Comandos útiles de Docker:**
> - Para apagar los contenedores al terminar el día sin perder datos: `docker compose stop`
> - Para volver a encenderlos: `docker compose start`
> - Para consultar la BD desde consola:
>   ```powershell
>   docker exec rh_solutions_postgres psql -U rh_admin -d rh_solutions_v2 -c "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public';"
>   ```

---

### Paso 2: Prender el Frontend (`rh_frontend/`)

El frontend corre de forma nativa en Windows sobre **Node.js `v24.18.0`**.

1. Abre una terminal y entra a la carpeta del frontend:
   ```powershell
   cd C:\Project\rh_solutionsv2\rh_frontend
   ```
2. Instala las dependencias (solo la primera vez o cuando cambie `package.json`):
   ```powershell
   npm install
   ```
3. Levanta el servidor de desarrollo con recarga en caliente:
   ```powershell
   npm run dev
   ```
4. Abre en tu navegador: **[http://localhost:3000](http://localhost:3000)**

---

### Paso 3: Prender el Backend (`rh_backend/`)

El backend corre de forma nativa en Windows sobre **Python `3.12.9`** y el gestor **`uv`**, el cual crea y administra automáticamente el entorno virtual en `rh_backend/.venv`.
*(Si aún no tienes Python 3.12.9 ni `uv` configurados en tu máquina, sigue primero la [Guía de Instalación de Python y `uv`](./guia_instalacion_python.md)).*

1. Abre una nueva terminal y entra a la carpeta del backend:
   ```powershell
   cd C:\Project\rh_solutionsv2\rh_backend
   ```
2. Sincroniza el entorno virtual (`.venv`) e instala las dependencias exactas del `uv.lock`:
   ```powershell
   uv sync
   ```
3. **Solo la primera vez**, aplica las migraciones internas de sesión de Django sobre la base de datos:
   ```powershell
   uv run python manage.py migrate
   ```
4. Levanta el servidor de desarrollo de Django (puedes elegir cualquiera de estas dos formas):

   **Opción A — Directo con `uv` (sin necesidad de activar el `.venv` manualmente):**
   ```powershell
   uv run python manage.py runserver 8000
   ```

   **Opción B — Activando el entorno virtual `.venv` de forma tradicional (`Git Bash` o `PowerShell`):**
   ```powershell
   # En PowerShell:
   .\.venv\Scripts\Activate.ps1
   # En Git Bash (MINGW64):
   source .venv/Scripts/activate

   python manage.py runserver 8000
   ```

5. La API estará disponible en: **[http://localhost:8000/api/v1/health/](http://localhost:8000/api/v1/health/)** (o directamente en **[http://localhost:8000/](http://localhost:8000/)**).

---

## 3. Documentación Clave del Repositorio

- **[`AGENTS.md`](./AGENTS.md):** Instrucciones maestras e invariantes del sistema para desarrolladores y agentes de IA.
- **[`documentation/ARCHITECTURE.MD`](./documentation/ARCHITECTURE.MD):** Diseño de arquitectura, flujo de autenticación por cookies `HttpOnly`, estructura de carpetas y presupuesto de rendimiento.
- **[`documentation/migrations.md`](./documentation/migrations.md):** Auditoría de los 8 módulos del sistema original, diccionario de las 44 tablas en 3NF y los 20 pilares de seguridad.
- **[`guia_instalacion_python.md`](./guia_instalacion_python.md):** Guía paso a paso para instalar Python `3.12.9` + `uv` y limpiar el `PATH` en Windows.
