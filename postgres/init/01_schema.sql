-- =============================================================================
-- 01_schema.sql
-- Esquema principal de Sylvara — PostgreSQL
-- Se ejecuta automáticamente al crear el contenedor por primera vez
-- =============================================================================

-- ─── Extensiones ─────────────────────────────────────────────────────────────
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- ─── Tipos ENUM ──────────────────────────────────────────────────────────────
CREATE TYPE roles AS ENUM ('USER', 'ADMIN');
CREATE TYPE status AS ENUM ('active', 'inactive');

-- ─── Usuarios ────────────────────────────────────────────────────────────────
CREATE TABLE users (
    user_id          SERIAL PRIMARY KEY,
    user_name        VARCHAR(100)  NOT NULL,
    user_lastname    VARCHAR(100)  NOT NULL,
    user_birthday    DATE          NOT NULL,
    user_email       VARCHAR(255)  UNIQUE NOT NULL,
    user_password    VARCHAR(255)  NOT NULL,
    user_role        roles         NOT NULL DEFAULT 'USER',
    profile_picture_url VARCHAR(512)
);

-- ─── Sesiones ────────────────────────────────────────────────────────────────
CREATE TABLE refresh_tokens (
    token_id   SERIAL PRIMARY KEY,
    user_id    INT          NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    token      VARCHAR(512) UNIQUE NOT NULL,
    created_at TIMESTAMP    NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMP    NOT NULL
);

CREATE TABLE google_tokens (
    id            SERIAL PRIMARY KEY,
    user_id       INT     UNIQUE NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    access_token  TEXT    NOT NULL,
    refresh_token TEXT,
    expires_at    TIMESTAMP NOT NULL,
    scope         VARCHAR(255) NOT NULL
);

-- ─── Unidades de medida ───────────────────────────────────────────────────────
CREATE TABLE unit_measurement (
    unit_id   SERIAL PRIMARY KEY,
    unit_name VARCHAR(250) NOT NULL UNIQUE
);

INSERT INTO unit_measurement (unit_name) VALUES
    ('Metros'),
    ('Hectareas');

-- ─── Parcelas de muestreo ─────────────────────────────────────────────────────
CREATE TABLE sampling_plots (
    sampling_plot_id     SERIAL PRIMARY KEY,
    user_id              INT            NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    sampling_plot_name   VARCHAR(100)   NOT NULL,
    sampling_plot_status status         NOT NULL DEFAULT 'active',
    description          TEXT,
    total_area           DECIMAL(10, 2) NOT NULL,
    unit_id              INT            NOT NULL REFERENCES unit_measurement(unit_id),
    start_date           DATE           NOT NULL DEFAULT CURRENT_DATE,
    end_date             DATE,
    current_cycle_number INT            DEFAULT 1
);

-- ─── Tipos funcionales de especies ───────────────────────────────────────────
CREATE TABLE functional_types (
    functional_type_id   SERIAL PRIMARY KEY,
    functional_type_name VARCHAR(250) NOT NULL UNIQUE
);

INSERT INTO functional_types (functional_type_name) VALUES
    ('Frutal'),
    ('Cerco vivo'),
    ('Maderable'),
    ('Medicinal'),
    ('Medicinal y plaguicida'),
    ('Ornamental'),
    ('Maderable y medicinal'),
    ('Frutal trepadora'),
    ('Medicinal y ornamental'),
    ('Medicinal y forrajero'),
    ('Frutal y forrajero');

-- ─── Catálogo de especies ─────────────────────────────────────────────────────
CREATE TABLE species (
    species_id        SERIAL PRIMARY KEY,
    species_name      VARCHAR(250) NOT NULL,
    functional_type_id INT         NOT NULL REFERENCES functional_types(functional_type_id),
    species_image_url VARCHAR(512)
);

-- ─── Zonas de estudio ────────────────────────────────────────────────────────
CREATE TABLE studies_zones (
    study_zone_id    SERIAL PRIMARY KEY,
    sampling_plot_id INT            NOT NULL REFERENCES sampling_plots(sampling_plot_id) ON DELETE CASCADE,
    name_study_zone  VARCHAR(250)   NOT NULL,
    sub_area         DECIMAL(10, 2) NOT NULL,
    unit_id          INT            NOT NULL REFERENCES unit_measurement(unit_id),
    cycle_number     INT            NOT NULL DEFAULT 1
);

-- ─── Registro de especies por zona ───────────────────────────────────────────
CREATE TABLE species_zone (
    species_zone_id    SERIAL PRIMARY KEY,
    study_zone_id      INT            NOT NULL REFERENCES studies_zones(study_zone_id) ON DELETE CASCADE,
    species_id         INT            NOT NULL REFERENCES species(species_id) ON DELETE RESTRICT,
    individual_count   INT            NOT NULL,
    height_stratum_min DECIMAL(10, 2) NOT NULL,
    height_stratum_max DECIMAL(10, 2) NOT NULL,
    unit_id            INT            NOT NULL DEFAULT 1 CHECK (unit_id = 1) REFERENCES unit_measurement(unit_id),
    cycle_number       INT            DEFAULT 1
);

-- ─── Benchmarking: proyectos y ejecuciones ────────────────────────────────────
CREATE TABLE projects (
    project_id   SERIAL PRIMARY KEY,
    project_type VARCHAR(20) NOT NULL CHECK (
        project_type IN (
            'ECOMMERCE', 'SOCIAL', 'FINANCIAL', 'HEALTHCARE', 'IOT',
            'EDUCATION', 'CONTENT', 'ENTERPRISE', 'LOGISTICS', 'GOVERNMENT'
        )
    ),
    description  TEXT,
    db_engine    VARCHAR(20) NOT NULL CHECK (
        db_engine IN ('POSTGRESQL', 'MYSQL', 'MONGODB', 'OTHER')
    )
);

CREATE TABLE queries (
    query_id          SERIAL PRIMARY KEY,
    project_id        INT  REFERENCES projects(project_id),
    query_description TEXT NOT NULL,
    query_sql         TEXT NOT NULL,
    target_table      VARCHAR(100),
    query_type        VARCHAR(30) CHECK (
        query_type IN (
            'SIMPLE_SELECT', 'AGGREGATION', 'JOIN', 'WINDOW_FUNCTION',
            'SUBQUERY', 'WRITE_OPERATION'
        )
    )
);

CREATE TABLE executions (
    execution_id       BIGSERIAL PRIMARY KEY,
    project_id         INT  REFERENCES projects(project_id),
    query_id           INT  REFERENCES queries(query_id),
    index_strategy     VARCHAR(20) CHECK (
        index_strategy IN ('NO_INDEX', 'SINGLE_INDEX', 'COMPOSITE_INDEX')
    ),
    execution_timestamp   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    execution_time_ms     BIGINT,
    records_examined      BIGINT,
    records_returned      BIGINT,
    dataset_size_rows     BIGINT,
    dataset_size_mb       NUMERIC,
    concurrent_sessions   INT,
    shared_buffers_hits   BIGINT,
    shared_buffers_reads  BIGINT
);

-- ─── Seed: proyecto Sylvara (project_id = 8) ─────────────────────────────────
-- El SERIAL arranca en 1, se avanza la secuencia para garantizar el ID 8
-- que referencia v_daily_export y el SnapshotService del backend.
SELECT setval('projects_project_id_seq', 7);

INSERT INTO projects (project_id, project_type, description, db_engine) VALUES (
    8,
    'EDUCATION',
    'Sylvara - Aplicación centralizada para investigadores agroforestales encargada del cálculo de índices de biodiversidad',
    'POSTGRESQL'
);