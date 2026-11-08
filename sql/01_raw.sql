-- =============================================================
-- 01_raw.sql  ·  Capa RAW: datos tal como vienen de la fuente
-- Se ejecuta desde la raíz del repositorio (src/build_db.py).
-- =============================================================
CREATE SCHEMA IF NOT EXISTS raw;

-- Home Credit Default Risk (Kaggle) ------------------------------
CREATE OR REPLACE TABLE raw.application_train AS
SELECT * FROM read_csv_auto('data/raw/application_train.csv');

CREATE OR REPLACE TABLE raw.bureau AS
SELECT * FROM read_csv_auto('data/raw/bureau.csv');

CREATE OR REPLACE TABLE raw.previous_application AS
SELECT * FROM read_csv_auto('data/raw/previous_application.csv');

CREATE OR REPLACE TABLE raw.installments_payments AS
SELECT * FROM read_csv_auto('data/raw/installments_payments.csv');

-- CFPB Consumer Complaints ----------------------------------------
-- El archivo completo pesa varios GB. Nos quedamos con reclamos que
-- tienen texto, desde 2022, y como máximo 8 000 por producto para
-- que ninguna categoría domine el dataset.
CREATE OR REPLACE TABLE raw.complaints AS
SELECT *
FROM read_csv('data/raw/complaints.csv',
              header = true,
              all_varchar = true,
              max_line_size = 4000000)
WHERE "Consumer complaint narrative" IS NOT NULL
  AND "Date received" >= '2022-01-01'
QUALIFY row_number() OVER (
            PARTITION BY "Product"
            ORDER BY hash("Complaint ID")
        ) <= 8000;
