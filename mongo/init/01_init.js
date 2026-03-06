// =============================================================================
// 01_init.js
// Inicialización de MongoDB — Sylvara
// Se ejecuta automáticamente al crear el contenedor por primera vez.
// Crea la base de datos, el usuario de aplicación, las colecciones con
// validación de esquema y los índices necesarios.
// =============================================================================

// Cambiar al contexto de la base de datos de la aplicación
db = db.getSiblingDB(process.env.MONGO_INITDB_DATABASE || 'sylvara_db');

// ─── Usuario de aplicación (menor privilegio que root) ────────────────────────
db.createUser({
  user: process.env.MONGO_APP_USER || 'sylvara_app',
  pwd:  process.env.MONGO_APP_PASSWORD || 'sylvara_app_pass',
  roles: [{ role: 'readWrite', db: process.env.MONGO_INITDB_DATABASE || 'sylvara_db' }],
});

// =============================================================================
// Colección: activity_cycles
// Ciclos cerrados de investigación. Se escribe una vez al cerrar una parcela
// y nunca se modifica (histórico inmutable).
// =============================================================================
db.createCollection('activity_cycles', {
  validator: {
    $jsonSchema: {
      bsonType: 'object',
      required: ['sampling_plot_id', 'cycle_number', 'sampling_plot_status', 'startDate', 'globalMetrics', 'zonesDetails'],
      properties: {
        sampling_plot_id: {
          bsonType: 'int',
          description: 'ID de la parcela en PostgreSQL'
        },
        cycle_number: {
          bsonType: 'int',
          minimum: 1,
          description: 'Número de ciclo de investigación'
        },
        sampling_plot_status: {
          bsonType: 'string',
          enum: ['active', 'inactive'],
          description: 'Estado de la parcela al cerrar el ciclo'
        },
        startDate: {
          bsonType: 'string',
          description: 'Fecha de inicio del ciclo (YYYY-MM-DD)'
        },
        endDate: {
          bsonType: 'string',
          description: 'Fecha de cierre del ciclo (YYYY-MM-DD)'
        },
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
              species_name:             { bsonType: 'string' },
              functional_type_name:     { bsonType: 'string' },
              total_individuals_in_plot:{ bsonType: 'int' },
              presence_in_zones: {
                bsonType: 'array',
                items: { bsonType: 'string' }
              }
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
// Caché en caliente de índices del ciclo activo. Se actualiza en cada
// operación de species (create / update / delete) desde el backend.
// =============================================================================
db.createCollection('biodiversity_cache', {
  validator: {
    $jsonSchema: {
      bsonType: 'object',
      required: ['sampling_plot_id', 'cycle_number', 'lastUpdated', 'globalMetrics', 'zonesDetails'],
      properties: {
        sampling_plot_id: { bsonType: 'int' },
        cycle_number:     { bsonType: 'int', minimum: 1 },
        lastUpdated:      { bsonType: 'string', description: 'ISO 8601 timestamp' },
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
// Serie temporal diaria de snapshots globales por parcela y ciclo.
// Se inserta un documento por parcela activa cada noche (cron o manual).
// Nunca se actualiza, solo se inserta.
// =============================================================================
db.createCollection('biodiversity_history', {
  validator: {
    $jsonSchema: {
      bsonType: 'object',
      required: ['timestamp', 'sampling_plot_id', 'cycle_number', 'globalMetrics', 'zonesDetails'],
      properties: {
        timestamp:        { bsonType: 'date', description: 'Fecha exacta del snapshot' },
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
                    species_name:          { bsonType: 'string' },
                    functional_type_name:  { bsonType: 'string' },
                    individual_count:      { bsonType: 'int' },
                    height_stratum_min:    { bsonType: 'double' },
                    height_stratum_max:    { bsonType: 'double' },
                    unit_name:             { bsonType: 'string' }
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
// Índices de MongoDB
// =============================================================================

// biodiversity_cache — lookup principal del backend por parcela y ciclo activo
db.biodiversity_cache.createIndex(
  { sampling_plot_id: 1, cycle_number: 1 },
  { unique: true, name: 'idx_cache_plot_cycle' }
);

// biodiversity_history — serie temporal: parcela + ciclo + fecha
db.biodiversity_history.createIndex(
  { sampling_plot_id: 1, cycle_number: 1, timestamp: -1 },
  { name: 'idx_history_plot_cycle_date' }
);

// activity_cycles — ciclos cerrados por parcela (único por parcela+ciclo)
db.activity_cycles.createIndex(
  { sampling_plot_id: 1, cycle_number: 1 },
  { unique: true, name: 'idx_cycles_plot_cycle' }
);

// =============================================================================
// Datos de ejemplo (seed mínimo)
// Replican la estructura de los JSON de referencia del proyecto
// =============================================================================

db.activity_cycles.insertOne({
  sampling_plot_id: 101,
  cycle_number: 1,
  sampling_plot_status: 'inactive',
  startDate: '2026-01-01',
  endDate: '2026-02-26',
  globalMetrics: {
    indices: {
      shannon: 3.12, simpson: 0.89, margalef: 4.15, pielou: 0.82
    },
    counts: {
      species_richness: 25, total_individuals: 1250
    }
  },
  global_species_summary: [
    {
      species_name: 'Cedrela odorata',
      functional_type_name: 'Maderable',
      total_individuals_in_plot: 45,
      presence_in_zones: ['Zona Norte', 'Zona Centro', 'Zona Sur']
    }
  ],
  zonesDetails: [
    {
      study_zone_id: 50,
      name_study_zone: 'Zona Norte',
      indices: { shannon: 2.15, simpson: 0.78, margalef: 2.1, pielou: 0.72 },
      speciesRecords: [
        {
          species_name: 'Cedrela odorata',
          individual_count: 15,
          height_stratum_min: 2.5,
          height_stratum_max: 12.0,
          unit_name: 'Metros'
        }
      ]
    }
  ]
});

db.biodiversity_cache.insertOne({
  sampling_plot_id: 101,
  cycle_number: 1,
  lastUpdated: '2026-02-26T21:30:00Z',
  globalMetrics: {
    indices: { shannon: 3.12, simpson: 0.89, margalef: 4.15, pielou: 0.82 },
    counts: { species_richness: 25, total_individuals: 1250 }
  },
  zonesDetails: [
    {
      study_zone_id: 50,
      name_study_zone: 'Zona Norte',
      indices: { shannon: 2.15, simpson: 0.75, margalef: 2.1, pielou: 0.75 },
      counts: { species_richness: 12, total_individuals: 400 }
    },
    {
      study_zone_id: 51,
      name_study_zone: 'Zona Sur',
      indices: { shannon: 1.85, simpson: 0.68, margalef: 1.95, pielou: 0.68 },
      counts: { species_richness: 9, total_individuals: 850 }
    }
  ]
});

db.biodiversity_history.insertOne({
  timestamp: new Date('2026-02-26T23:59:59.000Z'),
  sampling_plot_id: 101,
  cycle_number: 1,
  globalMetrics: {
    indices: { shannon: 3.12, simpson: 0.89, margalef: 4.15, pielou: 0.82 },
    counts: { species_richness: 25, total_individuals: 1250 }
  },
  zonesDetails: [
    {
      study_zone_id: 50,
      name_study_zone: 'Zona Norte',
      indices: { shannon: 2.15, simpson: 0.78, margalef: 2.1, pielou: 0.72 },
      counts: { species_richness: 12, total_individuals: 400 },
      speciesRecords: [
        {
          species_name: 'Cedrela odorata',
          functional_type_name: 'Maderable',
          individual_count: 15,
          height_stratum_min: 2.5,
          height_stratum_max: 12.0,
          unit_name: 'Metros'
        }
      ]
    }
  ]
});

print('sylvara_db inicializada: colecciones, índices y seed insertados.');