-- =============================================================================
-- 03_triggers.sql
-- Triggers y funciones de validación — Sylvara
-- =============================================================================

-- ─── Función: validación de área de zona por ciclo ───────────────────────────
-- Garantiza que la suma de sub_areas dentro de un mismo ciclo no supere
-- el área total de la parcela. Cada ciclo de investigación es independiente.
CREATE OR REPLACE FUNCTION validar_area_zona()
RETURNS TRIGGER AS $$
DECLARE
    area_total_parcela    DECIMAL(10, 2);
    suma_areas_existentes DECIMAL(10, 2);
BEGIN
    -- Área total definida para la parcela base
    SELECT total_area
    INTO area_total_parcela
    FROM sampling_plots
    WHERE sampling_plot_id = NEW.sampling_plot_id;

    -- Suma de sub_areas de zonas en el mismo ciclo (excluye la fila actual en UPDATE)
    SELECT COALESCE(SUM(sub_area), 0)
    INTO suma_areas_existentes
    FROM studies_zones
    WHERE sampling_plot_id = NEW.sampling_plot_id
      AND cycle_number     = NEW.cycle_number
      AND study_zone_id   <> NEW.study_zone_id;

    IF (suma_areas_existentes + NEW.sub_area) > area_total_parcela THEN
        RAISE EXCEPTION
            'Error de validación: La suma de sub-áreas para el ciclo % (%) excede el área total de la parcela (%)',
            NEW.cycle_number,
            (suma_areas_existentes + NEW.sub_area),
            area_total_parcela;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ─── Trigger: validación antes de INSERT o UPDATE en studies_zones ───────────
DROP TRIGGER IF EXISTS trg_validar_area_zona ON studies_zones;

CREATE TRIGGER trg_validar_area_zona
BEFORE INSERT OR UPDATE ON studies_zones
FOR EACH ROW EXECUTE FUNCTION validar_area_zona();