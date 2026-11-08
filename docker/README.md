# Infraestructura Docker — RH Solutions v2

Esta carpeta y el archivo `docker-compose.yml` de la raíz levantan la infraestructura de datos del proyecto sin colisionar puertos con otros proyectos locales (como `come_daddy`).

## Servicios y Puertos

| Servicio | Contenedor | Imagen | Puerto Host → Contenedor | Acceso / URL |
| :--- | :--- | :--- | :--- | :--- |
| **PostgreSQL 17** | `rh_solutions_postgres` | `postgres:17-alpine` | `5435:5432` | `postgres://rh_admin:rh_secret_2026@localhost:5435/rh_solutions_v2` |
| **pgweb (Visor BD)** | `rh_solutions_pgweb` | `sosedoff/pgweb:latest` | **`7070:8081`** | **http://localhost:7070** (Autoconectado sin pedir login) |
| **Redis 7** | `rh_solutions_redis` | `redis:7-alpine` | `6380:6379` | `redis://localhost:6380/0` |

## Inicialización Automática del Seeder

Al levantar el contenedor por primera vez, PostgreSQL ejecuta automáticamente:
- `seeders/init_postgres.sql` montado en `/docker-entrypoint-initdb.d/01_init_postgres.sql:ro`

Esto crea las **44 tablas** (27 catálogos poblados + 17 tablas operativas limpias + Usuario `#1` Admin) y sincroniza las secuencias (`SERIAL`).

## Comandos Útiles

```powershell
# Levantar los contenedores en segundo plano
docker compose up -d

# Ver estado de los contenedores
docker ps

# Reiniciar la base de datos desde cero (vuelve a correr seeders/init_postgres.sql)
docker compose down -v
docker compose up -d
```
