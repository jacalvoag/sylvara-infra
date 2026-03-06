// =============================================================================
// 01_init.js
// Inicialización de MongoDB — Sylvara
// Crea la base de datos, el usuario de aplicación, las colecciones con
// validación de esquema y los índices necesarios.
// =============================================================================

db = db.getSiblingDB(process.env.MONGO_INITDB_DATABASE || 'sylvara_db');

// ─── Usuario de aplicación ────────────────────────────────────────────────────
db.createUser({
  user: process.env.MONGO_APP_USER || 'sylvara_app',
  pwd:  process.env.MONGO_APP_PASSWORD || 'sylvara_app_pass',
  roles: [{ role: 'readWrite', db: process.env.MONGO_INITDB_DATABASE || 'sylvara_db' }],
});

// =============================================================================
// Colección: activity_cycles
// =============================================================================
db.createCollection('activity_cycles', {
  validator: {
    $jsonSchema: {
      bsonType: 'object',
      required: ['sampling_plot_id', 'cycle_number', 'sampling_plot_status', 'startDate', 'globalMetrics', 'zonesDetails'],
      properties: {
        sampling_plot_id:      { bsonType: 'int' },
        cycle_number:          { bsonType: 'int', minimum: 1 },
        sampling_plot_status:  { bsonType: 'string', enum: ['active', 'inactive'] },
        startDate:             { bsonType: 'string' },
        endDate:               { bsonType: 'string' },
        globalMetrics: {
          bsonType: 'object',
          required: ['indices', 'counts'],
          properties: {
            indices: {
              bsonType: 'object',
              required: ['shannon', 'simpson', 'margalef', 'pielou'],
              properties: {
                shannon:  { bsonType: 'double' },
                simpson:  { bsonType: 'double' },
                margalef: { bsonType: 'double' },
                pielou:   { bsonType: 'double' }
              }
            },
            counts: {
              bsonType: 'object',
              required: ['species_richness', 'total_individuals'],
              properties: {
                species_richness:  { bsonType: 'int' },
                total_individuals: { bsonType: 'int' }
              }
            }
          }
        },
        global_species_summary: {
          bsonType: 'array',
          items: {
            bsonType: 'object',
            required: ['species_name', 'functional_type_name', 'total_individuals_in_plot'],
            properties: {
              species_name:              { bsonType: 'string' },
              functional_type_name:      { bsonType: 'string' },
              total_individuals_in_plot: { bsonType: 'int' },
              presence_in_zones:         { bsonType: 'array', items: { bsonType: 'string' } }
            }
          }
        },
        zonesDetails: {
          bsonType: 'array',
          items: {
            bsonType: 'object',
            required: ['study_zone_id', 'name_study_zone', 'indices', 'speciesRecords'],
            properties: {
              study_zone_id:   { bsonType: 'int' },
              name_study_zone: { bsonType: 'string' },
              indices: {
                bsonType: 'object',
                properties: {
                  shannon:  { bsonType: 'double' },
                  simpson:  { bsonType: 'double' },
                  margalef: { bsonType: 'double' },
                  pielou:   { bsonType: 'double' }
                }
              },
              speciesRecords: {
                bsonType: 'array',
                items: {
                  bsonType: 'object',
                  properties: {
                    species_name:       { bsonType: 'string' },
                    individual_count:   { bsonType: 'int' },
                    height_stratum_min: { bsonType: 'double' },
                    height_stratum_max: { bsonType: 'double' },
                    unit_name:          { bsonType: 'string' }
                  }
                }
              }
            }
          }
        }
      }
    }
  },
  validationLevel:  'moderate',
  validationAction: 'warn'
});

// =============================================================================
// Colección: biodiversity_cache
// =============================================================================
db.createCollection('biodiversity_cache', {
  validator: {
    $jsonSchema: {
      bsonType: 'object',
      required: ['sampling_plot_id', 'cycle_number', 'lastUpdated', 'globalMetrics', 'zonesDetails'],
      properties: {
        sampling_plot_id: { bsonType: 'int' },
        cycle_number:     { bsonType: 'int', minimum: 1 },
        lastUpdated:      { bsonType: 'string' },
        globalMetrics: {
          bsonType: 'object',
          required: ['indices', 'counts'],
          properties: {
            indices: {
              bsonType: 'object',
              properties: {
                shannon:  { bsonType: 'double' },
                simpson:  { bsonType: 'double' },
                margalef: { bsonType: 'double' },
                pielou:   { bsonType: 'double' }
              }
            },
            counts: {
              bsonType: 'object',
              properties: {
                species_richness:  { bsonType: 'int' },
                total_individuals: { bsonType: 'int' }
              }
            }
          }
        },
        zonesDetails: {
          bsonType: 'array',
          items: {
            bsonType: 'object',
            properties: {
              study_zone_id:   { bsonType: 'int' },
              name_study_zone: { bsonType: 'string' },
              indices: {
                bsonType: 'object',
                properties: {
                  shannon:  { bsonType: 'double' },
                  simpson:  { bsonType: 'double' },
                  margalef: { bsonType: 'double' },
                  pielou:   { bsonType: 'double' }
                }
              },
              counts: {
                bsonType: 'object',
                properties: {
                  species_richness:  { bsonType: 'int' },
                  total_individuals: { bsonType: 'int' }
                }
              }
            }
          }
        }
      }
    }
  },
  validationLevel:  'moderate',
  validationAction: 'warn'
});

// =============================================================================
// Colección: biodiversity_history
// =============================================================================
db.createCollection('biodiversity_history', {
  validator: {
    $jsonSchema: {
      bsonType: 'object',
      required: ['timestamp', 'sampling_plot_id', 'cycle_number', 'globalMetrics', 'zonesDetails'],
      properties: {
        timestamp:        { bsonType: 'date' },
        sampling_plot_id: { bsonType: 'int' },
        cycle_number:     { bsonType: 'int', minimum: 1 },
        globalMetrics: {
          bsonType: 'object',
          required: ['indices', 'counts'],
          properties: {
            indices: {
              bsonType: 'object',
              properties: {
                shannon:  { bsonType: 'double' },
                simpson:  { bsonType: 'double' },
                margalef: { bsonType: 'double' },
                pielou:   { bsonType: 'double' }
              }
            },
            counts: {
              bsonType: 'object',
              properties: {
                species_richness:  { bsonType: 'int' },
                total_individuals: { bsonType: 'int' }
              }
            }
          }
        },
        zonesDetails: {
          bsonType: 'array',
          items: {
            bsonType: 'object',
            properties: {
              study_zone_id:   { bsonType: 'int' },
              name_study_zone: { bsonType: 'string' },
              indices: {
                bsonType: 'object',
                properties: {
                  shannon:  { bsonType: 'double' },
                  simpson:  { bsonType: 'double' },
                  margalef: { bsonType: 'double' },
                  pielou:   { bsonType: 'double' }
                }
              },
              counts: {
                bsonType: 'object',
                properties: {
                  species_richness:  { bsonType: 'int' },
                  total_individuals: { bsonType: 'int' }
                }
              },
              speciesRecords: {
                bsonType: 'array',
                items: {
                  bsonType: 'object',
                  properties: {
                    species_name:         { bsonType: 'string' },
                    functional_type_name: { bsonType: 'string' },
                    individual_count:     { bsonType: 'int' },
                    height_stratum_min:   { bsonType: 'double' },
                    height_stratum_max:   { bsonType: 'double' },
                    unit_name:            { bsonType: 'string' }
                  }
                }
              }
            }
          }
        }
      }
    }
  },
  validationLevel:  'moderate',
  validationAction: 'warn'
});

// =============================================================================
// Índices
// =============================================================================
db.biodiversity_cache.createIndex(
  { sampling_plot_id: 1, cycle_number: 1 },
  { unique: true, name: 'idx_cache_plot_cycle' }
);

db.biodiversity_history.createIndex(
  { sampling_plot_id: 1, cycle_number: 1, timestamp: -1 },
  { name: 'idx_history_plot_cycle_date' }
);

db.activity_cycles.createIndex(
  { sampling_plot_id: 1, cycle_number: 1 },
  { unique: true, name: 'idx_cycles_plot_cycle' }
);

print('sylvara_db inicializada: colecciones e índices creados.');