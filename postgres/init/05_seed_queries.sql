-- =============================================================================
-- 05_seed_queries.sql
-- 39 consultas de Sylvara para el módulo de benchmarking
-- Se ejecuta después de 04_views.sql (las vistas ya existen)
-- project_id = 8 (Sylvara)
-- =============================================================================

INSERT INTO queries (project_id, query_description, query_sql, target_table, query_type) VALUES

-- ════════════════════════════════════════════════════════════
--  SIMPLE_SELECT (10)
-- ════════════════════════════════════════════════════════════

(8, 'Verificar email duplicado (register)',
'SELECT 1 FROM users WHERE user_email = :email;',
'users', 'SIMPLE_SELECT'),

(8, 'Buscar usuario por email (login)',
'SELECT user_id, user_name, user_lastname, user_birthday, user_email, user_password, profile_picture_url, user_role FROM users WHERE user_email = :email;',
'users', 'SIMPLE_SELECT'),

(8, 'Validar refresh token',
'SELECT token_id, user_id, expires_at FROM refresh_tokens WHERE token = :refreshToken;',
'refresh_tokens', 'SIMPLE_SELECT'),

(8, 'Obtener perfil de usuario',
'SELECT user_id, user_name, user_lastname, user_birthday, user_email, profile_picture_url, user_role FROM users WHERE user_id = :userId;',
'users', 'SIMPLE_SELECT'),

(8, 'Verificar email duplicado (update profile)',
'SELECT 1 FROM users WHERE user_email = :email AND user_id <> :userId;',
'users', 'SIMPLE_SELECT'),

(8, 'Obtener contraseña actual',
'SELECT user_password FROM users WHERE user_id = :userId;',
'users', 'SIMPLE_SELECT'),

(8, 'Verificar propiedad de proyecto',
'SELECT sampling_plot_id FROM sampling_plots WHERE sampling_plot_id = :id AND user_id = :userId;',
'sampling_plots', 'SIMPLE_SELECT'),

(8, 'Verificar existencia proyecto y obtener ciclo',
'SELECT sampling_plot_id, current_cycle_number FROM sampling_plots WHERE sampling_plot_id = :id AND user_id = :userId;',
'sampling_plots', 'SIMPLE_SELECT'),

(8, 'Verificar existencia proyecto y status',
'SELECT sampling_plot_id, sampling_plot_status, current_cycle_number FROM sampling_plots WHERE sampling_plot_id = :id AND user_id = :userId;',
'sampling_plots', 'SIMPLE_SELECT'),

(8, 'Verificar especie en zona',
'SELECT spz.species_zone_id, spz.individual_count, spz.height_stratum_min, spz.height_stratum_max, um.unit_name, spz.cycle_number FROM species_zone spz JOIN unit_measurement um ON um.unit_id = spz.unit_id WHERE spz.species_id = :speciesId AND spz.study_zone_id = :zoneId;',
'species_zone', 'SIMPLE_SELECT'),

-- ════════════════════════════════════════════════════════════
--  JOIN (8)
-- ════════════════════════════════════════════════════════════

(8, 'Dashboard: usuario + resumen',
'SELECT u.user_name, u.profile_picture_url, v.total_historical_plots, v.current_month_plots FROM view_user_summary v JOIN users u ON u.user_id = v.user_id WHERE v.user_id = :userId;',
'view_user_summary', 'JOIN'),

(8, 'Dashboard: últimas parcelas',
'SELECT id, name, description, total_area, area_unit, status, start_date FROM view_latest_plots WHERE user_id = :userId;',
'view_latest_plots', 'JOIN'),

(8, 'Listar proyectos con paginación',
'SELECT sp.sampling_plot_id, sp.user_id, sp.sampling_plot_name, sp.description, sp.total_area, sp.unit_id, um.unit_name, sp.sampling_plot_status, sp.current_cycle_number, sp.start_date, sp.end_date FROM sampling_plots sp JOIN unit_measurement um ON sp.unit_id = um.unit_id WHERE sp.user_id = :userId AND (:status IS NULL OR sp.sampling_plot_status = :status::status) AND (:cursor IS NULL OR sp.sampling_plot_id < :cursor) ORDER BY sp.sampling_plot_id DESC LIMIT :limit + 1;',
'sampling_plots', 'JOIN'),

(8, 'Verificar zona pertenece al proyecto',
'SELECT sz.study_zone_id FROM studies_zones sz JOIN sampling_plots sp ON sp.sampling_plot_id = sz.sampling_plot_id WHERE sz.study_zone_id = :zoneId AND sp.sampling_plot_id = :plotId AND sp.user_id = :userId;',
'studies_zones', 'JOIN'),

(8, 'Listar especies de zona con paginación',
'SELECT spz.species_zone_id, spz.species_id, s.species_name, s.species_image_url, ft.functional_type_id, ft.functional_type_name, spz.individual_count, spz.height_stratum_min, spz.height_stratum_max, spz.unit_id, um.unit_name, spz.cycle_number FROM species_zone spz JOIN species s ON s.species_id = spz.species_id JOIN functional_types ft ON ft.functional_type_id = s.functional_type_id JOIN unit_measurement um ON um.unit_id = spz.unit_id WHERE spz.study_zone_id = :zoneId AND (:cursor IS NULL OR spz.species_zone_id < :cursor) ORDER BY spz.species_zone_id DESC LIMIT :limit + 1;',
'species_zone', 'JOIN'),

(8, 'Buscar especie en catálogo del proyecto',
'SELECT s.species_id, s.species_name, s.species_image_url, ft.functional_type_id, ft.functional_type_name FROM species s JOIN functional_types ft ON ft.functional_type_id = s.functional_type_id JOIN species_zone spz ON spz.species_id = s.species_id JOIN studies_zones sz ON sz.study_zone_id = spz.study_zone_id WHERE sz.sampling_plot_id = :plotId AND LOWER(s.species_name) = LOWER(:speciesName) LIMIT 1;',
'species', 'JOIN'),

(8, 'Verificar existencia species_zone para update/delete',
'SELECT spz.species_zone_id, spz.species_id FROM species_zone spz JOIN studies_zones sz ON sz.study_zone_id = spz.study_zone_id JOIN sampling_plots sp ON sp.sampling_plot_id = sz.sampling_plot_id WHERE spz.species_zone_id = :speciesZoneId AND sz.study_zone_id = :zoneId AND sp.sampling_plot_id = :plotId AND sp.user_id = :userId;',
'species_zone', 'JOIN'),

(8, 'Verificar zona + obtener ciclo (species POST)',
'SELECT sz.study_zone_id, sp.current_cycle_number FROM studies_zones sz JOIN sampling_plots sp ON sp.sampling_plot_id = sz.sampling_plot_id WHERE sz.study_zone_id = :zoneId AND sp.sampling_plot_id = :plotId AND sp.user_id = :userId;',
'studies_zones', 'JOIN'),

-- ════════════════════════════════════════════════════════════
--  AGGREGATION (1)
-- ════════════════════════════════════════════════════════════

(8, 'Catálogo consolidado del proyecto (SUM + GROUP BY)',
'SELECT s.species_id, s.species_name, s.species_image_url, ft.functional_type_name, SUM(spz.individual_count) AS total_individuals FROM species_zone spz JOIN species s ON s.species_id = spz.species_id JOIN functional_types ft ON ft.functional_type_id = s.functional_type_id JOIN studies_zones sz ON sz.study_zone_id = spz.study_zone_id WHERE sz.sampling_plot_id = :plotId AND spz.cycle_number = :currentCycle AND (:cursor IS NULL OR s.species_id < :cursor) GROUP BY s.species_id, s.species_name, s.species_image_url, ft.functional_type_name ORDER BY s.species_id DESC LIMIT :limit + 1;',
'species_zone', 'AGGREGATION'),

-- ════════════════════════════════════════════════════════════
--  SUBQUERY (1)
-- ════════════════════════════════════════════════════════════

(8, 'Limpiar especie huérfana (NOT EXISTS)',
'DELETE FROM species WHERE species_id = :speciesId AND NOT EXISTS (SELECT 1 FROM species_zone WHERE species_id = :speciesId);',
'species', 'SUBQUERY'),

-- ════════════════════════════════════════════════════════════
--  WRITE_OPERATION (19)
-- ════════════════════════════════════════════════════════════

(8, 'Insertar usuario (register)',
'INSERT INTO users (user_name, user_lastname, user_birthday, user_email, user_password) VALUES (:name, :lastname, :birthday, :email, :hashedPassword) RETURNING user_id, user_name, user_lastname, user_birthday, user_email, profile_picture_url, user_role;',
'users', 'WRITE_OPERATION'),

(8, 'Insertar refresh token',
'INSERT INTO refresh_tokens (user_id, token, expires_at) VALUES (:userId, :token, :expiresAt);',
'refresh_tokens', 'WRITE_OPERATION'),

(8, 'Eliminar refresh token (logout)',
'DELETE FROM refresh_tokens WHERE token = :refreshToken;',
'refresh_tokens', 'WRITE_OPERATION'),

(8, 'Rotar refresh token (delete viejo)',
'DELETE FROM refresh_tokens WHERE token = :oldToken;',
'refresh_tokens', 'WRITE_OPERATION'),

(8, 'Actualizar perfil',
'UPDATE users SET user_name = COALESCE(:name, user_name), user_lastname = COALESCE(:lastname, user_lastname), user_birthday = COALESCE(:birthday, user_birthday), user_email = COALESCE(:email, user_email), profile_picture_url = COALESCE(:pictureUrl, profile_picture_url) WHERE user_id = :userId RETURNING user_id, user_name, user_lastname, user_birthday, user_email, profile_picture_url, user_role;',
'users', 'WRITE_OPERATION'),

(8, 'Actualizar contraseña',
'UPDATE users SET user_password = :hashedNewPassword WHERE user_id = :userId;',
'users', 'WRITE_OPERATION'),

(8, 'Eliminar usuario (cascade)',
'DELETE FROM users WHERE user_id = :userId;',
'users', 'WRITE_OPERATION'),

(8, 'Crear proyecto (CTE INSERT + JOIN)',
'WITH inserted AS (INSERT INTO sampling_plots (user_id, sampling_plot_name, description, total_area, unit_id) VALUES (:userId, :name, :description, :totalArea, :unitId) RETURNING *) SELECT i.sampling_plot_id, i.user_id, i.sampling_plot_name, i.description, i.total_area, i.unit_id, um.unit_name, i.sampling_plot_status, i.current_cycle_number, i.start_date, i.end_date FROM inserted i JOIN unit_measurement um ON um.unit_id = i.unit_id;',
'sampling_plots', 'WRITE_OPERATION'),

(8, 'Actualizar proyecto (CTE UPDATE + JOIN)',
'WITH updated AS (UPDATE sampling_plots SET sampling_plot_name = COALESCE(:name, sampling_plot_name), description = COALESCE(:description, description), total_area = COALESCE(:totalArea, total_area), unit_id = COALESCE(:unitId, unit_id), start_date = COALESCE(:startDate, start_date) WHERE sampling_plot_id = :id RETURNING *) SELECT u.sampling_plot_id, u.user_id, u.sampling_plot_name, u.description, u.total_area, u.unit_id, um.unit_name, u.sampling_plot_status, u.current_cycle_number, u.start_date, u.end_date FROM updated u JOIN unit_measurement um ON um.unit_id = u.unit_id;',
'sampling_plots', 'WRITE_OPERATION'),

(8, 'Cambiar status de proyecto (CTE UPDATE con lógica de ciclo)',
'WITH updated AS (UPDATE sampling_plots SET sampling_plot_status = :newStatus::status, end_date = CASE WHEN :newStatus = ''inactive'' THEN CURRENT_DATE ELSE NULL END, start_date = CASE WHEN :newStatus = ''active'' THEN CURRENT_DATE ELSE start_date END, current_cycle_number = CASE WHEN :newStatus = ''active'' AND sampling_plot_status = ''inactive'' THEN current_cycle_number + 1 ELSE current_cycle_number END WHERE sampling_plot_id = :id RETURNING *) SELECT u.sampling_plot_id, u.user_id, u.sampling_plot_name, u.description, u.total_area, u.unit_id, um.unit_name, u.sampling_plot_status, u.current_cycle_number, u.start_date, u.end_date FROM updated u JOIN unit_measurement um ON um.unit_id = u.unit_id;',
'sampling_plots', 'WRITE_OPERATION'),

(8, 'Eliminar proyecto (cascade)',
'DELETE FROM sampling_plots WHERE sampling_plot_id = :id AND user_id = :userId;',
'sampling_plots', 'WRITE_OPERATION'),

(8, 'Crear zona (CTE INSERT + JOIN)',
'WITH inserted AS (INSERT INTO studies_zones (sampling_plot_id, name_study_zone, sub_area, unit_id, cycle_number) VALUES (:plotId, :name, :subArea, :unitId, :currentCycle) RETURNING *) SELECT i.study_zone_id, i.name_study_zone, i.sub_area, i.unit_id, um.unit_name, i.cycle_number FROM inserted i JOIN unit_measurement um ON um.unit_id = i.unit_id;',
'studies_zones', 'WRITE_OPERATION'),

(8, 'Actualizar zona (CTE UPDATE + JOIN)',
'WITH updated AS (UPDATE studies_zones SET name_study_zone = COALESCE(:name, name_study_zone), sub_area = COALESCE(:subArea, sub_area), unit_id = COALESCE(:unitId, unit_id) WHERE study_zone_id = :zoneId RETURNING *) SELECT u.study_zone_id, u.name_study_zone, u.sub_area, u.unit_id, um.unit_name, u.cycle_number FROM updated u JOIN unit_measurement um ON um.unit_id = u.unit_id;',
'studies_zones', 'WRITE_OPERATION'),

(8, 'Eliminar zona (cascade)',
'DELETE FROM studies_zones WHERE study_zone_id = :zoneId;',
'studies_zones', 'WRITE_OPERATION'),

(8, 'Crear especie nueva',
'INSERT INTO species (species_name, functional_type_id, species_image_url) VALUES (:name, :functionalTypeId, :imageUrl) RETURNING species_id;',
'species', 'WRITE_OPERATION'),

(8, 'Registrar especie en zona (CTE INSERT + JOINs)',
'WITH inserted AS (INSERT INTO species_zone (study_zone_id, species_id, individual_count, height_stratum_min, height_stratum_max, unit_id, cycle_number) VALUES (:zoneId, :speciesId, :count, :heightMin, :heightMax, 1, :currentCycle) RETURNING *) SELECT i.species_zone_id, i.species_id, s.species_name, s.species_image_url, ft.functional_type_id, ft.functional_type_name, i.individual_count, i.height_stratum_min, i.height_stratum_max, i.unit_id, um.unit_name, i.cycle_number FROM inserted i JOIN species s ON s.species_id = i.species_id JOIN functional_types ft ON ft.functional_type_id = s.functional_type_id JOIN unit_measurement um ON um.unit_id = i.unit_id;',
'species_zone', 'WRITE_OPERATION'),

(8, 'Actualizar especie global',
'UPDATE species SET species_name = COALESCE(:speciesName, species_name), species_image_url = COALESCE(:imageUrl, species_image_url), functional_type_id = COALESCE(:functionalTypeId, functional_type_id) WHERE species_id = :speciesId;',
'species', 'WRITE_OPERATION'),

(8, 'Actualizar species_zone (CTE UPDATE + JOINs)',
'WITH updated AS (UPDATE species_zone SET individual_count = COALESCE(:count, individual_count), height_stratum_min = COALESCE(:heightMin, height_stratum_min), height_stratum_max = COALESCE(:heightMax, height_stratum_max) WHERE species_zone_id = :speciesZoneId RETURNING *) SELECT u.species_zone_id, u.species_id, s.species_name, s.species_image_url, ft.functional_type_id, ft.functional_type_name, u.individual_count, u.height_stratum_min, u.height_stratum_max, u.unit_id, um.unit_name, u.cycle_number FROM updated u JOIN species s ON s.species_id = u.species_id JOIN functional_types ft ON ft.functional_type_id = s.functional_type_id JOIN unit_measurement um ON um.unit_id = u.unit_id;',
'species_zone', 'WRITE_OPERATION'),

(8, 'Eliminar species_zone',
'DELETE FROM species_zone WHERE species_zone_id = :speciesZoneId;',
'species_zone', 'WRITE_OPERATION');