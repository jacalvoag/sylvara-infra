-- =============================================================================
-- 04_views.sql
-- Vistas del sistema — Sylvara
-- =============================================================================

-- ─── Resumen de actividad por usuario ────────────────────────────────────────
-- Expone el total histórico de parcelas y cuántas se crearon en el mes actual.
-- Consumida por el DashboardService.
CREATE OR REPLACE VIEW view_user_summary AS
SELECT
    u.user_id,
    u.user_name,
    -- Conteo total histórico de parcelas del usuario
    (SELECT COUNT(*)
     FROM sampling_plots sp2
     WHERE sp2.user_id = u.user_id) AS total_historical_plots,
    -- Conteo de parcelas creadas solo en el mes actual
    (SELECT COUNT(*)
     FROM sampling_plots sp3
     WHERE sp3.user_id = u.user_id
       AND sp3.start_date >= DATE_TRUNC('month', CURRENT_DATE)
       AND sp3.start_date <  DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month'
    ) AS current_month_plots
FROM users u;


-- ─── Últimas 3 parcelas por usuario ──────────────────────────────────────────
-- Devuelve las 3 parcelas más recientes de cada usuario usando ROW_NUMBER.
-- Consumida por el DashboardService junto con view_user_summary.
CREATE OR REPLACE VIEW view_latest_plots AS
SELECT
    user_id,
    sampling_plot_id AS id,
    sampling_plot_name AS name,
    description,
    total_area,
    unit_name AS area_unit,
    sampling_plot_status AS status,
    start_date
FROM (
    SELECT
        sp.*,
        um.unit_name,
        ROW_NUMBER() OVER (
            PARTITION BY sp.user_id
            ORDER BY sp.start_date DESC, sp.sampling_plot_id DESC
        ) AS position
    FROM sampling_plots sp
    JOIN unit_measurement um ON sp.unit_id = um.unit_id
) sub
WHERE position <= 3;


-- ─── Exportación diaria de métricas de consultas (benchmarking) ──────────────
-- Lee de pg_stat_statements y cruza con las queries registradas en el proyecto 8.
-- Consumida por el SnapshotService para exportar a BigQuery.
-- NOTA: se ejecuta después del seed de queries (05_seed_queries.sql).
DROP VIEW IF EXISTS v_daily_export;

CREATE OR REPLACE VIEW v_daily_export AS
SELECT
    8                             AS project_id,
    CURRENT_DATE                  AS snapshot_date,
    s.queryid::TEXT               AS queryid,
    s.dbid,
    s.userid,
    s.query,
    s.calls,
    s.total_exec_time             AS total_exec_time_ms,
    s.mean_exec_time              AS mean_exec_time_ms,
    s.min_exec_time               AS min_exec_time_ms,
    s.max_exec_time               AS max_exec_time_ms,
    s.stddev_exec_time            AS stddev_exec_time_ms,
    s.rows                        AS rows_returned,
    s.shared_blks_hit,
    s.shared_blks_read,
    s.shared_blks_dirtied,
    s.shared_blks_written,
    s.temp_blks_read,
    s.temp_blks_written
FROM pg_stat_statements s
WHERE s.dbid = (SELECT oid FROM pg_database WHERE datname = current_database())
  AND s.calls > 0
  AND UPPER(TRIM(s.query)) NOT IN ('BEGIN', 'COMMIT', 'ROLLBACK')
  AND EXISTS (
      SELECT 1
      FROM queries q
      WHERE q.project_id = 8
        AND TRIM(regexp_replace(s.query,    '\s+', ' ', 'g'))
          = TRIM(regexp_replace(q.query_sql, '\s+', ' ', 'g'))
  );