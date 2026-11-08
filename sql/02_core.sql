-- =============================================================
-- 02_core.sql  ·  Capa CORE: modelo de datos limpio, en español
-- =============================================================
CREATE SCHEMA IF NOT EXISTS core;

-- Clientes ----------------------------------------------------------
-- Home Credit guarda las fechas como "días antes de la solicitud"
-- (números negativos). 365243 en DAYS_EMPLOYED es un valor centinela
-- ("sin empleo registrado") y se convierte en NULL.
CREATE OR REPLACE TABLE core.clientes AS
SELECT
    SK_ID_CURR                                   AS cliente_id,
    CODE_GENDER                                  AS genero,
    ROUND(-DAYS_BIRTH / 365.25, 1)               AS edad_anios,
    CASE WHEN DAYS_EMPLOYED = 365243 THEN NULL
         ELSE ROUND(-DAYS_EMPLOYED / 365.25, 1) END
                                                 AS antiguedad_laboral_anios,
    AMT_INCOME_TOTAL                             AS ingreso_anual,
    NAME_INCOME_TYPE                             AS tipo_ingreso,
    NAME_EDUCATION_TYPE                          AS nivel_educativo,
    NAME_FAMILY_STATUS                           AS estado_civil,
    NAME_HOUSING_TYPE                            AS tipo_vivienda,
    CNT_CHILDREN                                 AS num_hijos,
    FLAG_OWN_CAR = 'Y'                           AS tiene_auto,
    FLAG_OWN_REALTY = 'Y'                        AS tiene_inmueble,
    REGION_RATING_CLIENT                         AS calificacion_region
FROM raw.application_train;

-- Solicitudes de crédito actuales (con la variable objetivo) --------
CREATE OR REPLACE TABLE core.solicitudes AS
SELECT
    SK_ID_CURR          AS solicitud_id,
    SK_ID_CURR          AS cliente_id,
    NAME_CONTRACT_TYPE  AS tipo_contrato,
    AMT_CREDIT          AS monto_credito,
    AMT_ANNUITY         AS cuota_anual,
    AMT_GOODS_PRICE     AS precio_bien,
    EXT_SOURCE_1        AS puntaje_externo_1,
    EXT_SOURCE_2        AS puntaje_externo_2,
    EXT_SOURCE_3        AS puntaje_externo_3,
    TARGET              AS impago            -- 1 = tuvo dificultades de pago
FROM raw.application_train;

-- Créditos en otras entidades (equivalente a la central de riesgos) --
CREATE OR REPLACE TABLE core.buro_creditos AS
SELECT
    SK_ID_BUREAU            AS buro_id,
    SK_ID_CURR              AS cliente_id,
    CREDIT_ACTIVE           AS estado,
    CREDIT_TYPE             AS tipo_credito,
    -DAYS_CREDIT            AS dias_desde_otorgamiento,
    CREDIT_DAY_OVERDUE      AS dias_atraso,
    AMT_CREDIT_SUM          AS monto_credito,
    AMT_CREDIT_SUM_DEBT     AS deuda_actual,
    AMT_CREDIT_SUM_OVERDUE  AS monto_vencido
FROM raw.bureau;

-- Solicitudes anteriores del cliente con la misma entidad -----------
CREATE OR REPLACE TABLE core.solicitudes_previas AS
SELECT
    SK_ID_PREV            AS previa_id,
    SK_ID_CURR            AS cliente_id,
    NAME_CONTRACT_TYPE    AS tipo_contrato,
    AMT_APPLICATION       AS monto_solicitado,
    AMT_CREDIT            AS monto_otorgado,
    NAME_CONTRACT_STATUS  AS estado,
    -DAYS_DECISION        AS dias_desde_decision
FROM raw.previous_application;

-- Historial de pago de cuotas -----------------------------------------
CREATE OR REPLACE TABLE core.pagos_cuotas AS
SELECT
    SK_ID_PREV                            AS previa_id,
    SK_ID_CURR                            AS cliente_id,
    NUM_INSTALMENT_NUMBER                 AS numero_cuota,
    AMT_INSTALMENT                        AS monto_cuota,
    AMT_PAYMENT                           AS monto_pagado,
    DAYS_ENTRY_PAYMENT - DAYS_INSTALMENT  AS dias_atraso_pago   -- > 0 = pagó tarde
FROM raw.installments_payments;

-- Reclamos --------------------------------------------------------------
-- Los reclamos de la CFPB no pertenecen a los clientes de Home Credit.
-- Para tener un solo "banco", cada reclamo se asigna a un cliente de forma
-- determinista (hash del ID). Esta relación es SIMULADA y el README lo dice.
CREATE OR REPLACE TABLE core.reclamos AS
WITH clientes_idx AS (
    SELECT cliente_id,
           row_number() OVER (ORDER BY cliente_id) - 1 AS idx
    FROM core.clientes
),
total AS (SELECT count(*) AS n FROM clientes_idx)
SELECT
    CAST(r."Complaint ID" AS BIGINT)        AS reclamo_id,
    c.cliente_id,
    TRY_CAST(r."Date received" AS DATE)     AS fecha,
    CASE
        WHEN r."Product" LIKE 'Credit card%'         THEN 'Tarjeta de crédito'
        WHEN r."Product" LIKE 'Checking or savings%' THEN 'Cuentas y depósitos'
        WHEN r."Product" LIKE 'Credit reporting%'    THEN 'Centrales de riesgo'
        WHEN r."Product" LIKE 'Debt collection%'     THEN 'Cobranza'
        WHEN r."Product" LIKE 'Mortgage%'            THEN 'Hipotecario'
        WHEN r."Product" LIKE 'Money transfer%'      THEN 'Transferencias y pagos'
        WHEN r."Product" ILIKE '%loan%'              THEN 'Préstamos'
        ELSE 'Otros'
    END                                     AS categoria,
    r."Product"                             AS producto_original,
    r."Issue"                               AS problema_original,
    r."Consumer complaint narrative"        AS texto,
    r."Submitted via"                       AS canal,
    r."Company response to consumer"        AS respuesta_empresa,
    r."Timely response?" = 'Yes'            AS respuesta_a_tiempo,
    'en'                                    AS idioma,
    'cfpb'                                  AS fuente
FROM raw.complaints r
CROSS JOIN total t
JOIN clientes_idx c
  ON c.idx = hash(r."Complaint ID") % t.n;
