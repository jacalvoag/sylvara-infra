# Esquemas de colecciones — MongoDB (sylvara_db)

Las tres colecciones tienen propósitos distintos y nunca se solapan en responsabilidades.

---

## activity_cycles

Histórico inmutable de ciclos cerrados. Se escribe **una sola vez** cuando una parcela pasa a `inactive`. El backend nunca actualiza un documento de esta colección, solo inserta.

```json
{
  "_id": ObjectId,
  "sampling_plot_id": 101,
  "cycle_number": 1,
  "sampling_plot_status": "inactive",
  "startDate": "2026-01-01",
  "endDate": "2026-02-26",
  "globalMetrics": {
    "indices": {
      "shannon": 3.12,
      "simpson": 0.89,
      "margalef": 4.15,
      "pielou": 0.82
    },
    "counts": {
      "species_richness": 25,
      "total_individuals": 1250
    }
  },
  "global_species_summary": [
    {
      "species_name": "Cedrela odorata",
      "functional_type_name": "Maderable",
      "total_individuals_in_plot": 45,
      "presence_in_zones": ["Zona Norte", "Zona Centro", "Zona Sur"]
    }
  ],
  "zonesDetails": [
    {
      "study_zone_id": 50,
      "name_study_zone": "Zona Norte",
      "indices": {
        "shannon": 2.15,
        "simpson": 0.78,
        "margalef": 2.1,
        "pielou": 0.72
      },
      "speciesRecords": [
        {
          "species_name": "Cedrela odorata",
          "individual_count": 15,
          "height_stratum_min": 2.5,
          "height_stratum_max": 12.0,
          "unit_name": "Metros"
        }
      ]
    }
  ]
}
```

**Índice:** `{ sampling_plot_id: 1, cycle_number: 1 }` — unique

---

## biodiversity_cache

Caché en caliente del ciclo activo. Existe **un documento por parcela activa**. Se actualiza (upsert) cada vez que el backend registra, edita o elimina una especie en una zona.

```json
{
  "_id": ObjectId,
  "sampling_plot_id": 101,
  "cycle_number": 1,
  "lastUpdated": "2026-02-26T21:30:00Z",
  "globalMetrics": {
    "indices": {
      "shannon": 3.12,
      "simpson": 0.89,
      "margalef": 4.15,
      "pielou": 0.82
    },
    "counts": {
      "species_richness": 25,
      "total_individuals": 1250
    }
  },
  "zonesDetails": [
    {
      "study_zone_id": 50,
      "name_study_zone": "Zona Norte",
      "indices": {
        "shannon": 2.15,
        "simpson": 0.75,
        "margalef": 2.1,
        "pielou": 0.75
      },
      "counts": {
        "species_richness": 12,
        "total_individuals": 400
      }
    },
    {
      "study_zone_id": 51,
      "name_study_zone": "Zona Sur",
      "indices": {
        "shannon": 1.85,
        "simpson": 0.68,
        "margalef": 1.95,
        "pielou": 0.68
      },
      "counts": {
        "species_richness": 9,
        "total_individuals": 850
      }
    }
  ]
}
```

**Índice:** `{ sampling_plot_id: 1, cycle_number: 1 }` — unique

---

## biodiversity_history

Serie temporal de snapshots globales. Se **inserta** un documento por parcela activa periódicamente (ej. fin de día o fin de ciclo). Nunca se modifica un documento existente. Permite graficar la evolución de índices en el tiempo.

```json
{
  "_id": ObjectId,
  "timestamp": ISODate("2026-02-26T23:59:59.000Z"),
  "sampling_plot_id": 101,
  "cycle_number": 1,
  "globalMetrics": {
    "indices": {
      "shannon": 3.12,
      "simpson": 0.89,
      "margalef": 4.15,
      "pielou": 0.82
    },
    "counts": {
      "species_richness": 25,
      "total_individuals": 1250
    }
  },
  "zonesDetails": [
    {
      "study_zone_id": 50,
      "name_study_zone": "Zona Norte",
      "indices": {
        "shannon": 2.15,
        "simpson": 0.78,
        "margalef": 2.1,
        "pielou": 0.72
      },
      "counts": {
        "species_richness": 12,
        "total_individuals": 400
      },
      "speciesRecords": [
        {
          "species_name": "Cedrela odorata",
          "functional_type_name": "Maderable",
          "individual_count": 15,
          "height_stratum_min": 2.5,
          "height_stratum_max": 12.0,
          "unit_name": "Metros"
        }
      ]
    }
  ]
}
```

**Índice:** `{ sampling_plot_id: 1, cycle_number: 1, timestamp: -1 }`

---

## Diferencias clave entre colecciones

| Aspecto              | activity_cycles         | biodiversity_cache         | biodiversity_history       |
|----------------------|-------------------------|----------------------------|----------------------------|
| Ciclo de vida        | Inmutable (write-once)  | Mutable (upsert frecuente) | Inmutable (append-only)    |
| Cuándo se escribe    | Al cerrar parcela       | Cada operación de species  | Periódicamente (snapshot)  |
| Docs por parcela     | Uno por ciclo cerrado   | Uno por parcela activa     | N snapshots por parcela    |
| `speciesRecords`     | Siempre completo        | No incluido (solo conteos) | Incluido en cada zona      |
| `global_species_summary` | Incluido          | No incluido                | No incluido                |