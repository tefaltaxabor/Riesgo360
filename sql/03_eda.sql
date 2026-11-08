-- =============================================================
-- 03_eda.sql  ·  Análisis exploratorio
-- Cada consulta empieza con "-- name: <nombre>" para que
-- src/run_eda.py pueda ejecutarlas una por una.
-- =============================================================

-- name: tasa_impago_global
SELECT count(*)                          AS solicitudes,
       sum(impago)                       AS impagos,
       round(100.0 * avg(impago), 2)     AS tasa_impago_pct
FROM core.solicitudes;

-- name: impago_por_educacion
-- RANK() ordena los niveles educativos de mayor a menor riesgo.
SELECT c.nivel_educativo,
       count(*)                                           AS clientes,
       round(100.0 * avg(s.impago), 2)                    AS tasa_impago_pct,
       rank() OVER (ORDER BY avg(s.impago) DESC)          AS ranking_riesgo
FROM core.solicitudes s
JOIN core.clientes c USING (cliente_id)
GROUP BY c.nivel_educativo
ORDER BY ranking_riesgo;

-- name: impago_por_rango_edad
SELECT CASE
           WHEN c.edad_anios < 25 THEN '1) <25'
           WHEN c.edad_anios < 35 THEN '2) 25-34'
           WHEN c.edad_anios < 45 THEN '3) 35-44'
           WHEN c.edad_anios < 55 THEN '4) 45-54'
           ELSE                        '5) 55+'
       END                                   AS rango_edad,
       count(*)                              AS clientes,
       round(100.0 * avg(s.impago), 2)       AS tasa_impago_pct
FROM core.solicitudes s
JOIN core.clientes c USING (cliente_id)
GROUP BY rango_edad
ORDER BY rango_edad;

-- name: impago_por_quintil_ingreso
-- NTILE(5) divide a los clientes en cinco grupos de igual tamaño por ingreso.
WITH q AS (
    SELECT s.impago,
           c.ingreso_anual,
           ntile(5) OVER (ORDER BY c.ingreso_anual) AS quintil
    FROM core.solicitudes s
    JOIN core.clientes c USING (cliente_id)
)
SELECT quintil,
       round(min(ingreso_anual))           AS ingreso_min,
       round(max(ingreso_anual))           AS ingreso_max,
       round(100.0 * avg(impago), 2)       AS tasa_impago_pct
FROM q
GROUP BY quintil
ORDER BY quintil;

-- name: impago_vs_atrasos_buro
-- ¿Tener atrasos en otras entidades predice impago aquí?
WITH buro AS (
    SELECT cliente_id,
           max(dias_atraso) > 0     AS tiene_atraso_buro,
           count(*)                 AS creditos_buro
    FROM core.buro_creditos
    GROUP BY cliente_id
)
SELECT coalesce(CAST(b.tiene_atraso_buro AS VARCHAR), 'sin historial') AS atraso_en_buro,
       count(*)                                                      AS clientes,
       round(100.0 * avg(s.impago), 2)                               AS tasa_impago_pct
FROM core.solicitudes s
LEFT JOIN buro b USING (cliente_id)
GROUP BY atraso_en_buro
ORDER BY tasa_impago_pct DESC;

-- name: impago_vs_pagos_tardios
-- Porcentaje de cuotas pagadas tarde en el historial, agrupado en tramos.
WITH hist AS (
    SELECT cliente_id,
           avg(CASE WHEN dias_atraso_pago > 0 THEN 1 ELSE 0 END) AS pct_cuotas_tarde
    FROM core.pagos_cuotas
    GROUP BY cliente_id
)
SELECT CASE
           WHEN h.pct_cuotas_tarde IS NULL  THEN '0) sin historial'
           WHEN h.pct_cuotas_tarde = 0      THEN '1) nunca tarde'
           WHEN h.pct_cuotas_tarde < 0.10   THEN '2) <10% tarde'
           WHEN h.pct_cuotas_tarde < 0.30   THEN '3) 10-30% tarde'
           ELSE                                  '4) >=30% tarde'
       END                                   AS comportamiento_pago,
       count(*)                              AS clientes,
       round(100.0 * avg(s.impago), 2)       AS tasa_impago_pct
FROM core.solicitudes s
LEFT JOIN hist h USING (cliente_id)
GROUP BY comportamiento_pago
ORDER BY comportamiento_pago;

-- name: reclamos_por_categoria
-- SUM() OVER () calcula el total sin agrupar, para obtener el porcentaje.
SELECT categoria,
       count(*)                                              AS reclamos,
       round(100.0 * count(*) / sum(count(*)) OVER (), 1)    AS pct_del_total,
       round(100.0 * avg(CAST(respuesta_a_tiempo AS INT)), 1) AS pct_respuesta_a_tiempo
FROM core.reclamos
GROUP BY categoria
ORDER BY reclamos DESC;

-- name: top_problemas_por_categoria
-- Los 3 problemas más frecuentes dentro de cada categoría.
SELECT categoria, problema_original, reclamos
FROM (
    SELECT categoria,
           problema_original,
           count(*) AS reclamos,
           row_number() OVER (PARTITION BY categoria ORDER BY count(*) DESC) AS rn
    FROM core.reclamos
    GROUP BY categoria, problema_original
)
WHERE rn <= 3
ORDER BY categoria, reclamos DESC;

-- name: reclamos_mensuales
-- LAG() compara cada mes con el anterior.
WITH m AS (
    SELECT date_trunc('month', fecha) AS mes,
           count(*)                   AS reclamos
    FROM core.reclamos
    WHERE fecha IS NOT NULL
    GROUP BY mes
)
SELECT mes,
       reclamos,
       reclamos - lag(reclamos) OVER (ORDER BY mes) AS variacion_vs_mes_anterior
FROM m
ORDER BY mes;
