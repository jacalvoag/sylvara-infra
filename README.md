# sylvara-infra

Repositorio de infraestructura de base de datos para el proyecto **Sylvara**.  
Contiene la configuración Docker, el esquema completo de PostgreSQL y la inicialización de MongoDB.

---

## Estructura

```
sylvara-infra/
├── docker-compose.yml          # Servicios: postgres, mongo, pgadmin, mongo-express
├── .env.example                # Variables de entorno (copiar a .env)
├── postgres/
│   └── init/                   # Scripts ejecutados en orden al crear el contenedor
│       ├── 01_schema.sql       # Tablas, ENUMs, datos semilla (unit_measurement, functional_types)
│       ├── 02_indexes.sql      # Índices de rendimiento
│       ├── 03_triggers.sql     # Función y trigger de validación de área por ciclo
│       └── 04_views.sql        # view_user_summary, view_latest_plots, v_daily_export
└── mongo/
    ├── init/
    │   └── 01_init.js          # Colecciones con schema validation, índices y seed
    └── schemas/
        └── README.md           # Documentación detallada de las 3 colecciones
```

---

## Inicio rápido

```bash
# 1. Clonar y configurar variables
cp .env.example .env
# Editar .env con tus credenciales

# 2. Levantar solo las bases de datos
docker compose up -d

# 3. Verificar que estén saludables
docker compose ps

# 4. (Opcional) Levantar herramientas de administración
docker compose --profile tools up -d
```

### Herramientas de administración (perfil `tools`)

| Herramienta   | URL                   | Credenciales por defecto |
|---------------|-----------------------|--------------------------|
| pgAdmin       | http://localhost:5050 | admin@sylvara.com / admin |
| Mongo Express | http://localhost:8081 | admin / admin            |

---

## Bases de datos

### PostgreSQL — `sylvara`

| Tabla               | Descripción                                              |
|---------------------|----------------------------------------------------------|
| `users`             | Usuarios del sistema                                     |
| `refresh_tokens`    | Sesiones activas (JWT refresh)                           |
| `google_tokens`     | Tokens de Google OAuth para BigQuery                     |
| `unit_measurement`  | Catálogo de unidades (Metros, Hectareas)                 |
| `sampling_plots`    | Parcelas de muestreo agroforestal                        |
| `functional_types`  | Tipos funcionales de especies (Frutal, Maderable, etc.)  |
| `species`           | Catálogo de especies                                     |
| `studies_zones`     | Zonas dentro de una parcela por ciclo                    |
| `species_zone`      | Registro de especies por zona y ciclo                    |
| `projects`          | Proyectos del módulo de benchmarking                     |
| `queries`           | Consultas SQL registradas para benchmarking              |
| `executions`        | Ejecuciones medidas por estrategia de índice             |

**Vistas:**
- `view_user_summary` — total histórico y parcelas del mes actual por usuario
- `view_latest_plots` — últimas 3 parcelas por usuario
- `v_daily_export` — métricas de `pg_stat_statements` cruzadas con queries del proyecto 8

**Trigger:**
- `trg_validar_area_zona` — valida que la suma de sub-áreas por ciclo no exceda el área total de la parcela

### MongoDB — `sylvara_db`

| Colección              | Descripción                                           |
|------------------------|-------------------------------------------------------|
| `activity_cycles`      | Ciclos cerrados completos (inmutable, write-once)     |
| `biodiversity_cache`   | Caché en caliente del ciclo activo (upsert frecuente) |
| `biodiversity_history` | Serie temporal de snapshots (append-only)             |

Ver `mongo/schemas/README.md` para la documentación completa de cada colección.

---

## Variables de entorno del backend NestJS

Una vez levantado el infra, estas son las variables que necesita el backend:

```env
# PostgreSQL
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
POSTGRES_DB=sylvara
POSTGRES_USER=sylvara_user
POSTGRES_PASSWORD=sylvara_pass

# MongoDB
MONGO_URI=mongodb://root:rootpass@localhost:27017/sylvara_db?authSource=admin
```

---

## Comandos útiles

```bash
# Ver logs de PostgreSQL
docker compose logs postgres

# Ver logs de MongoDB
docker compose logs mongo

# Conectarse a PostgreSQL
docker exec -it sylvara_postgres psql -U sylvara_user -d sylvara

# Conectarse a MongoDB
docker exec -it sylvara_mongo mongosh -u root -p rootpass --authenticationDatabase admin sylvara_db

# Detener sin borrar datos
docker compose down

# Detener y borrar volúmenes (reset total)
docker compose down -v
```
