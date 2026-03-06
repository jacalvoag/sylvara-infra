-- =============================================================================
-- 02_indexes.sql
-- Índices de optimización — Sylvara
-- =============================================================================

-- ─── Dashboard y gestión de usuarios ─────────────────────────────────────────
-- Optimiza la carga de parcelas por usuario y el filtrado por fechas
CREATE INDEX idx_sampling_plots_user_id    ON sampling_plots(user_id);
CREATE INDEX idx_sampling_plots_start_date ON sampling_plots(start_date DESC);

-- ─── Cálculo de índices de biodiversidad ─────────────────────────────────────
-- Mejora el rendimiento de JOINs y agrupaciones para los índices ecológicos
CREATE INDEX idx_studies_zones_sampling_plot_id ON studies_zones(sampling_plot_id);
CREATE INDEX idx_species_zone_study_zone_id     ON species_zone(study_zone_id);
CREATE INDEX idx_species_name_search            ON species(species_name);

-- ─── Seguridad y sesiones ────────────────────────────────────────────────────
-- Acelera la validación y limpieza de tokens de sesión
CREATE INDEX idx_refresh_tokens_user_id    ON refresh_tokens(user_id);
CREATE INDEX idx_refresh_tokens_expires_at ON refresh_tokens(expires_at);

-- ─── Estadísticas del planificador ───────────────────────────────────────────
ANALYZE users;
ANALYZE sampling_plots;
ANALYZE studies_zones;
ANALYZE species_zone;