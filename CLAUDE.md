# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project overview

This is a learning project ("Projeto para treinar DBT") that builds a small ELT pipeline for the
Olist Brazilian e-commerce Kaggle dataset:

```
Kaggle CSVs (data/*.csv)
  -> src/ingestion/ingest_file_gcs.py   (DuckDB: CSV -> Parquet, upload to GCS bucket)
  -> src/ingestion/load_bigquery.py     (GCS Parquet -> BigQuery "raw_*" tables)
  -> dbt_olist/                         (dbt-bigquery: raw sources -> bronze views)
```

Both ingestion scripts and the dbt project talk to the same GCP project and use the dataset/bucket
names from `.env` (`PROJECT_ID`, `BUCKET_ID`, `DATASET_ID`) — they are not standalone tools, they are
sequential steps of one pipeline and rely on consistent naming across steps (see Architecture below).

## Commands

Python dependencies are managed with Poetry (`pyproject.toml` / `poetry.lock`), split into groups:
- default group: `python-dotenv`, `google-cloud-bigquery`, `google-cloud-storage`, `duckdb`
- `dbt` group: `dbt-bigquery`
- `download` group: `kagglehub`, `kaggle`

```bash
# Install everything (all groups)
poetry install --with dbt,download

# 1. Convert data/*.csv to Parquet and upload to the GCS bucket
poetry run python src/ingestion/ingest_file_gcs.py

# 2. Load the Parquet files from GCS into BigQuery raw_* tables
poetry run python src/ingestion/load_bigquery.py

# 3. Build/test the dbt bronze layer (run from dbt_olist/, needs a dbt profile named "dbt_olist")
cd dbt_olist
dbt run                       # build all models
dbt run --select bronze       # build only the bronze layer
dbt test                      # run all schema tests
dbt test --select bronze_orders   # run tests for a single model
```

Downloading the raw Kaggle CSVs into `data/` is documented step-by-step in
`data/download_data_kaglle_cli.md` (uses `poetry run kaggle datasets download -d olistbr/brazilian-ecommerce -p data --unzip`).

There is no lint/format/test tooling configured for the Python code (no ruff/pytest config in
`pyproject.toml`) and no dbt `packages.yml` — don't assume either exists.

### Docker

`Dockerfile` only packages step 1 of the pipeline (it installs deps with Poetry and its `CMD` runs
`src/ingestion/ingest_file_gcs.py`, copying in `src/` and `data/`). `docker-compose.yml` runs that
image as the `olist-ingest` service, loading secrets from `.env` and mounting
`./secrets/gcp-key.json` read-only to `/secrets/key.json` (`GOOGLE_APPLICATION_CREDENTIALS`).
`load_bigquery.py` and the dbt project are **not** part of the container — run them locally with Poetry.

```bash
docker compose build
docker compose up
```

## Required configuration (not checked into the repo)

- `.env` with `PROJECT_ID`, `BUCKET_ID`, `DATASET_ID` — read via `python-dotenv` by both ingestion
  scripts.
- `secrets/gcp-key.json` — GCP service account key (gitignored; mounted by docker-compose).
- A dbt profile named `dbt_olist` (per `dbt_olist/dbt_project.yml`'s `profile:` key) in the local
  `~/.dbt/profiles.yml`, pointing dbt-bigquery at the same `PROJECT_ID`/dataset.

## Architecture / naming conventions across the pipeline

The three stages are stitched together purely by filename/table-name conventions — there's no shared
config module, so if you rename something in one stage you must update the others:

1. **CSV -> Parquet -> GCS** (`ingest_file_gcs.py`): reads every `data/*.csv` (e.g.
   `olist_orders_dataset.csv`), converts with DuckDB (`read_csv_auto(..., all_varchar=true)`, so
   everything lands as strings) to `data/tmp_parquet/<stem>.parquet`, then uploads to the bucket as
   `<entity>.parquet` — the blob name strips both the `olist_` prefix and `_dataset` suffix (e.g.
   `orders.parquet`). The local Parquet temp file is deleted after upload.
2. **GCS -> BigQuery** (`load_bigquery.py`): lists blobs in the bucket, and for every `*.parquet`
   blob derives the BigQuery table name by replacing `olist` with `raw` in the blob name (so a blob
   would need to be named e.g. `olist_orders.parquet` for this substitution to produce `raw_orders` —
   note this expects the *pre-strip* naming, so check actual blob names in the bucket if this step
   misbehaves). Tables are created in `DATASET_ID` (creating the dataset first if missing) using
   `WRITE_TRUNCATE`, with schemas looked up in `src/ingestion/schema.py`'s `TABLE_SCHEMAS` dict keyed
   by the CSV stem (e.g. `olist_orders`, `olist_product_category_name_translation`). All schema
   fields are typed `STRING` — real typing happens later, in dbt.
3. **BigQuery -> dbt bronze** (`dbt_olist/models/bronze/`): `source.yml` declares the `olist` source
   in schema `olist_raw` with tables `raw_orders`, `raw_customers`, `raw_geolocation`,
   `raw_order_items`, `raw_order_payments`, `raw_products`, `raw_sellers` (note: no `raw_order_reviews`
   or `raw_product_category_name_translation` source/model exist yet even though those CSVs/schemas
   exist upstream). Each `bronze_<entity>.sql` model selects from `{{ source('olist', 'raw_<entity>') }}`,
   casts timestamp-looking string columns with `{{ dbt.type_timestamp() }}`, and is materialized as a
   `view` in the `bronze` schema (set via the `models.dbt_olist.bronze.+schema`/`+materialized` config
   in `dbt_project.yml`, not per-model). `schema.yml` in the same folder defines dbt tests
   (`unique`, `not_null`, `relationships`) per bronze model/column — this is the only "test suite" in
   the repo.

When adding a new entity to the pipeline, all three stages need touching: a `TABLE_SCHEMAS` entry,
a `source.yml` table entry, and a new `bronze_<entity>.sql` model (+ its tests in `schema.yml`).
