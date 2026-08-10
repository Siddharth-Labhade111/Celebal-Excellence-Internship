# Healthcare Data Pipeline — Medallion Architecture on Databricks

A scalable healthcare data pipeline that transforms raw, unstructured patient data
into business-ready insights using the **Medallion Architecture** (Bronze → Silver
→ Gold), built on **AWS S3, Databricks, Delta Lake, and PySpark**, automated with
**Lakeflow Declarative Pipelines** (formerly Delta Live Tables / DLT).

---

## 1. Project Overview

Healthcare organizations generate large volumes of data — patient records,
admissions, billing — that is often unstructured and difficult to analyze
directly. This project builds a pipeline that ingests, cleans, transforms, and
aggregates raw healthcare data into structured, analytics-ready datasets that
support dashboards, reporting, and future machine learning use cases.

**Objectives**
- Centralize healthcare data from source into a governed data platform
- Improve data quality and consistency through automated cleaning rules
- Track historical changes to patient records without losing data (SCD Type 2)
- Produce business-ready aggregated tables for hospital rankings, patient
  volume, and condition-based analysis
- Automate the entire flow and support scheduled batch processing
- Provide a foundation for BI dashboards and future MLOps use cases

---

## 2. Architecture

```
Data Source (CSV) → AWS S3 → Bronze (Delta) → Silver (Delta, SCD2) → Gold (Delta) → BI Dashboard
```

| Layer | Purpose | Key operations |
|---|---|---|
| **Bronze** | Preserve raw data exactly as received | No cleaning, no renaming — only ingestion metadata added, for full traceability |
| **Silver** | Ensure clean, reliable, deduplicated data | Null/duplicate removal, format standardization, type casting, **SCD Type 2 via MERGE INTO** |
| **Gold** | Business-ready insight tables | Aggregations: patient count per hospital, hospital ranking, condition contribution, admission type distribution, insurance breakdown |

---

## 3. Technology Stack

| Category | Technology |
|---|---|
| Ingestion | AWS S3 (Unity Catalog External Location, IAM-scoped access) |
| Processing | Python, PySpark |
| Analytical queries | Spark SQL |
| Storage & pipeline engine | Databricks + Delta Lake |
| Pipeline automation | Lakeflow Declarative Pipelines (DLT) |
| Change tracking | SCD Type 2 via `MERGE INTO` (manual notebook) and native `create_auto_cdc_flow` (automated pipeline) |
| Orchestration | Databricks Jobs (scheduled batch trigger) |
| Visualization | Databricks SQL Dashboard |
| Security | IAM least-privilege policy scoped to a single S3 bucket, read-only |

---

## 4. Repository Structure

```
healthcare-data-pipeline/
├── README.md                              <- this file
├── .gitignore
├── docs/
│   ├── Healthcare_Data_Pipeline_Documentation.pdf   <- original project spec
│   ├── Databricks_Stepwise_Guide.md                 <- full build walkthrough
│   └── screenshots/                                 <- evidence of each pipeline stage
├── data/
│   └── sample_patients_records.csv        <- 50-row sample (full dataset not committed)
├── src/
│   ├── local_reference_pipeline/          <- pandas-based reference implementation
│   │   ├── 01_bronze.py
│   │   ├── 02_silver.py
│   │   └── 03_gold.py
│   └── databricks_pipeline/
│       ├── manual_notebook/               <- hand-written MERGE INTO version
│       │   └── Bronze_Silver_Gold.py
│       └── automated_pipeline/            <- Lakeflow Declarative Pipeline (production version)
│           └── my_transformation.py
└── outputs/
    └── Healthcare_Gold_Layer_Insights.xlsx
```

---

## 5. Bronze Layer — Raw Ingestion

- Source: `s3://healthcare-raw-data-siddharth/raw/patients/patients_records.csv`
- Read as-is with `inferSchema=False` — no type coercion, no renaming
- Original column names (including spaces, e.g. `Date of Admission`) preserved
  using Delta's `columnMapping.mode = name`
- Only traceability metadata added: `_ingestion_timestamp`, `_source_file`
- Written to `healthcare_catalog.bronze.patients`

**Result:** 55,500 rows ingested, matching the source file exactly.

---

## 6. Silver Layer — Cleaning, Standardization & SCD Type 2

**Cleaning rules applied:**
- Removed exact duplicate records
- Dropped rows missing critical fields (Name, Date of Admission, Hospital)
- Standardized text casing (Name, Hospital, Doctor, Medical Condition, etc.)
- Cast Age, Billing Amount, Room Number to correct numeric types
- Standardized admission/discharge dates to proper date type
- Filtered out implausible values (negative billing, out-of-range age)
- Deduplicated on the SCD2 business key to prevent ambiguous merge matches

**SCD Type 2 (Slowly Changing Dimension):**

Rather than overwriting a patient record when it changes, Silver preserves
every version with `scd_effective_start_date`, `scd_effective_end_date`, and
`scd_is_current`, implemented two ways in this repo:

1. **Manual notebook** — explicit `MERGE INTO` logic (`whenMatchedUpdate` /
   `whenNotMatchedInsert`), demonstrating the underlying mechanics directly.
2. **Automated pipeline** — Databricks' native `create_auto_cdc_flow(...,
   stored_as_scd_type=2)`, which manages the same MERGE-based upsert logic
   declaratively, with `__START_AT` / `__END_AT` columns instead of hand-rolled
   ones.

**Result:** 54,860 clean rows (from 55,500 Bronze rows).

---

## 7. Gold Layer — Business Insights

Aggregated tables built with Spark SQL, filtered to current records only:

| Table | Description |
|---|---|
| `gold.patient_count_per_hospital` | Total patients per hospital |
| `gold.hospital_ranking` | Hospitals ranked by patient volume, with average billing |
| `gold.condition_contribution` | Patient share and average billing per medical condition |
| `gold.admission_type_distribution` | Elective vs. Urgent vs. Emergency breakdown |
| `gold.insurance_provider_breakdown` | Patient count and total billing per insurer |

> **Data note:** hospital names in this dataset are synthetically generated and
> nearly all unique (~39,800 distinct names across ~54,900 records). Hospital-
> level rankings are technically correct but should be read as demonstrating
> pipeline capability rather than real-world hospital performance.

---

## 8. Automation — Lakeflow Declarative Pipeline

The full Bronze → Silver → Gold flow is declared as a single pipeline
(`src/databricks_pipeline/automated_pipeline/my_transformation.py`), which:

- Automatically resolves the dependency graph and runs stages in order
- Enforces data-quality expectations (`@dp.expect_or_drop`) at the Silver stage
- Uses native SCD Type 2 tracking via `create_auto_cdc_flow`
- Was validated end-to-end with all five tables (Bronze, Silver clean, Silver
  SCD2, and both Gold tables) completing successfully

See `docs/screenshots/12_pipeline_graph_first_run.png` through
`17_final_performance_verified.png` for the verified run.

---

## 9. Scheduling — Batch Processing

The pipeline is configured to run on a **daily schedule** via Databricks'
built-in pipeline scheduler, which creates a backing Job that triggers a full
pipeline run automatically.

- **Trigger type:** Scheduled
- **Cadence:** Daily
- **Effect:** Bronze, Silver, and Gold tables refresh automatically without
  manual intervention, matching the "batch processing" requirement in the
  original project specification

> The current design uses batch triggers. The same Bronze/Silver/Gold logic
> can be extended to real-time processing by replacing the batch read with a
> Structured Streaming source (e.g. Kafka) — no change to the downstream
> transformation logic is required.

See `docs/screenshots/` for the schedule configuration.

---

## 10. Visualization — BI Dashboard

A **Databricks SQL Dashboard** ("Healthcare Insights Dashboard") was built
directly on top of the Gold layer tables, giving live, auto-refreshing
visuals with no manual export step:

- **Condition Contribution** — pie/bar chart of patient share by medical
  condition, sourced from `gold.condition_contribution`
- **Hospital Ranking** — bar chart of top hospitals by patient volume,
  sourced from `gold.hospital_ranking`

Because the dashboard queries Gold tables directly, it reflects fresh data
automatically every time the scheduled pipeline run completes — no manual
refresh required.

> The same Gold tables can be connected to Power BI or Tableau via
> Databricks' native connector if an external BI tool is required instead of
> the built-in dashboard.

See `docs/screenshots/` for the published dashboard.

---

## 11. Future Scope

**Real-time processing (Kafka):** the batch read in Bronze can be swapped for
a Structured Streaming read from a Kafka topic; the Bronze/Silver/Gold
transformation logic downstream is unchanged.

**MLOps:** Gold-layer data can support predictive use cases such as
identifying high-risk patients, forecasting hospital workload, and estimating
billing trends. The proposed lifecycle: train a model on Gold data → track
experiments and register the model with MLflow → deploy via Databricks Model
Serving → monitor for drift and retrain as needed.

---

## 12. Results Summary

| Metric | Value |
|---|---|
| Bronze rows ingested | 55,500 |
| Silver rows after cleaning | 54,860 |
| Rows removed (duplicates, invalid values) | 640 |
| Gold tables produced | 5 |
| Pipeline stages automated | 5 (Bronze, Silver clean, Silver SCD2, 2× Gold) |
| Schedule | Daily batch |
| Dashboard | Published, live against Gold tables |

---

## 13. How to Reproduce

1. Upload the source CSV to an S3 bucket
2. Create an IAM policy + user scoped to that bucket (read-only)
3. Connect the bucket to Databricks via a Unity Catalog External Location
4. Run `src/databricks_pipeline/manual_notebook/Bronze_Silver_Gold.py` for the
   step-by-step version, or deploy
   `src/databricks_pipeline/automated_pipeline/my_transformation.py` as a
   Lakeflow Declarative Pipeline for the automated version
5. Schedule the pipeline for daily batch runs
6. Build a Databricks SQL Dashboard against the resulting `gold.*` tables

Full walkthrough with explanations: [`docs/Databricks_Stepwise_Guide.md`](docs/Databricks_Stepwise_Guide.md)

---

## 14. Reference Implementation

`src/local_reference_pipeline/` contains a standalone pandas-based
implementation of the same Bronze/Silver/Gold logic, useful for local testing
or environments without Databricks access. It is not the production version —
the Databricks pipeline in `src/databricks_pipeline/` is the primary
deliverable of this project.

---

## License

This project uses a publicly available synthetic healthcare dataset for
educational purposes. No real patient data is included.
