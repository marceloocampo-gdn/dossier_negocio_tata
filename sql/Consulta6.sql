WITH base AS (
    SELECT
        M.SOCI_SOCI_ID,
        V.TICKET,
        V.TIEM_DIA_ID,
        V.VNTA_IMPORTE_SIN_IVA,
        D.DEPT_NAME,
        C.CLASS_NAME,
        SC.SUB_NAME,
        LAA.ORIN                        AS ARTICULO_ID,
        LAA.ARTC_ARTC_DESC              AS ARTICULO_DESC
    FROM 
        MSTRDB.DWH.FT_VENTAS V
        INNER JOIN MSTRDB.DWH.FT_FDLN_MOVIMIENTOS M ON V.TICKET = M.TICKET
        INNER JOIN MSTRDB.DWH.LU_ARTC_ARTICULO LAA ON V.ARTC_ARTC_ID = LAA.ARTC_ARTC_ID
        INNER JOIN MSTRDB.DWH.ITEM_MASTER IM ON LAA.ORIN = IM.ITEM
        INNER JOIN MSTRDB.DWH.DEPS D ON IM.DEPT = D.DEPT
        INNER JOIN MSTRDB.DWH.CLASS C ON IM.CLASE = C.CLASE
        INNER JOIN MSTRDB.DWH.SUBCLASS SC ON IM.SUBCLASE = SC.SUBCLASE
        INNER JOIN MSTRDB.DWH.LU_GEOG_LOCAL AS L ON V.GEOG_LOCL_ID = L.GEOG_LOCL_ID AND L.GEOG_UNNG_ID = 2
    WHERE M.SOCI_SOCI_ID IS NOT NULL
      AND M.FDLN_MOVT_TIPO = 'RP'
      AND (
            V.TIEM_DIA_ID BETWEEN DATEADD('day', -30, CURRENT_DATE - 1)
                              AND CURRENT_DATE - 1
            OR
            V.TIEM_DIA_ID BETWEEN DATEADD('day', -30, DATEADD('year', -1, CURRENT_DATE - 1))
                              AND DATEADD('year', -1, CURRENT_DATE - 1)
          )
),

total_cadena AS (
    SELECT
        COUNT(DISTINCT CASE
            WHEN TIEM_DIA_ID BETWEEN DATEADD('day', -30, CURRENT_DATE - 1)
                                 AND CURRENT_DATE - 1
            THEN SOCI_SOCI_ID END)      AS TOTAL_SOCIOS_ACTUAL,

        COUNT(DISTINCT CASE
            WHEN TIEM_DIA_ID BETWEEN DATEADD('day', -30, DATEADD('year', -1, CURRENT_DATE - 1))
                                 AND DATEADD('year', -1, CURRENT_DATE - 1)
            THEN SOCI_SOCI_ID END)      AS TOTAL_SOCIOS_AA

    FROM base
)

-- NIVEL DEPARTAMENTO
SELECT
    'DEPARTAMENTO'                      AS NIVEL,
    b.DEPT_NAME                         AS DEPARTAMENTO,
    NULL                                AS CLASE,
    NULL                                AS SUBCLASE,
    NULL                                AS ARTICULO,

    t.TOTAL_SOCIOS_ACTUAL,
    t.TOTAL_SOCIOS_AA,

    COUNT(DISTINCT CASE
        WHEN b.TIEM_DIA_ID BETWEEN DATEADD('day', -30, CURRENT_DATE - 1)
                               AND CURRENT_DATE - 1
        THEN b.SOCI_SOCI_ID END)        AS SOCIOS_UNICOS_ACTUAL,

    COUNT(DISTINCT CASE
        WHEN b.TIEM_DIA_ID BETWEEN DATEADD('day', -30, CURRENT_DATE - 1)
                               AND CURRENT_DATE - 1
        THEN b.TICKET END)              AS TICKETS_UNICOS_ACTUAL,

    ROUND(SUM(CASE
        WHEN b.TIEM_DIA_ID BETWEEN DATEADD('day', -30, CURRENT_DATE - 1)
                               AND CURRENT_DATE - 1
        THEN b.VNTA_IMPORTE_SIN_IVA ELSE 0 END), 2) AS MONTO_TOTAL_ACTUAL,

    COUNT(DISTINCT CASE
        WHEN b.TIEM_DIA_ID BETWEEN DATEADD('day', -30, DATEADD('year', -1, CURRENT_DATE - 1))
                               AND DATEADD('year', -1, CURRENT_DATE - 1)
        THEN b.SOCI_SOCI_ID END)        AS SOCIOS_UNICOS_AA,

    COUNT(DISTINCT CASE
        WHEN b.TIEM_DIA_ID BETWEEN DATEADD('day', -30, DATEADD('year', -1, CURRENT_DATE - 1))
                               AND DATEADD('year', -1, CURRENT_DATE - 1)
        THEN b.TICKET END)              AS TICKETS_UNICOS_AA,

    ROUND(SUM(CASE
        WHEN b.TIEM_DIA_ID BETWEEN DATEADD('day', -30, DATEADD('year', -1, CURRENT_DATE - 1))
                               AND DATEADD('year', -1, CURRENT_DATE - 1)
        THEN b.VNTA_IMPORTE_SIN_IVA ELSE 0 END), 2) AS MONTO_TOTAL_AA,

    COUNT(DISTINCT CASE
        WHEN b.TIEM_DIA_ID BETWEEN DATEADD('day', -30, CURRENT_DATE - 1)
                               AND CURRENT_DATE - 1
        THEN b.SOCI_SOCI_ID END)
    - COUNT(DISTINCT CASE
        WHEN b.TIEM_DIA_ID BETWEEN DATEADD('day', -30, DATEADD('year', -1, CURRENT_DATE - 1))
                               AND DATEADD('year', -1, CURRENT_DATE - 1)
        THEN b.SOCI_SOCI_ID END)        AS VAR_SOCIOS_ABS,

    ROUND(
        (COUNT(DISTINCT CASE
            WHEN b.TIEM_DIA_ID BETWEEN DATEADD('day', -30, CURRENT_DATE - 1)
                                   AND CURRENT_DATE - 1
            THEN b.SOCI_SOCI_ID END)
        - COUNT(DISTINCT CASE
            WHEN b.TIEM_DIA_ID BETWEEN DATEADD('day', -30, DATEADD('year', -1, CURRENT_DATE - 1))
                                   AND DATEADD('year', -1, CURRENT_DATE - 1)
            THEN b.SOCI_SOCI_ID END))
        / NULLIF(COUNT(DISTINCT CASE
            WHEN b.TIEM_DIA_ID BETWEEN DATEADD('day', -30, DATEADD('year', -1, CURRENT_DATE - 1))
                                   AND DATEADD('year', -1, CURRENT_DATE - 1)
            THEN b.SOCI_SOCI_ID END), 0) * 100
    , 1)                                AS VAR_SOCIOS_PCT,

    ROUND(
        (SUM(CASE
            WHEN b.TIEM_DIA_ID BETWEEN DATEADD('day', -30, CURRENT_DATE - 1)
                                   AND CURRENT_DATE - 1
            THEN b.VNTA_IMPORTE_SIN_IVA ELSE 0 END)
        - SUM(CASE
            WHEN b.TIEM_DIA_ID BETWEEN DATEADD('day', -30, DATEADD('year', -1, CURRENT_DATE - 1))
                                   AND DATEADD('year', -1, CURRENT_DATE - 1)
            THEN b.VNTA_IMPORTE_SIN_IVA ELSE 0 END))
        / NULLIF(SUM(CASE
            WHEN b.TIEM_DIA_ID BETWEEN DATEADD('day', -30, DATEADD('year', -1, CURRENT_DATE - 1))
                                   AND DATEADD('year', -1, CURRENT_DATE - 1)
            THEN b.VNTA_IMPORTE_SIN_IVA ELSE 0 END), 0) * 100
    , 1)                                AS VAR_MONTO_PCT,

    ROUND(
        COUNT(DISTINCT CASE
            WHEN b.TIEM_DIA_ID BETWEEN DATEADD('day', -30, CURRENT_DATE - 1)
                                   AND CURRENT_DATE - 1
            THEN b.SOCI_SOCI_ID END)
        / NULLIF(t.TOTAL_SOCIOS_ACTUAL, 0) * 100
    , 1)                                AS PCT_PENETRACION_ACTUAL

FROM base b
CROSS JOIN total_cadena t
GROUP BY b.DEPT_NAME, t.TOTAL_SOCIOS_ACTUAL, t.TOTAL_SOCIOS_AA

UNION ALL

-- NIVEL CLASE
SELECT
    'CLASE'                             AS NIVEL,
    b.DEPT_NAME                         AS DEPARTAMENTO,
    b.CLASS_NAME                        AS CLASE,
    NULL                                AS SUBCLASE,
    NULL                                AS ARTICULO,
    t.TOTAL_SOCIOS_ACTUAL,
    t.TOTAL_SOCIOS_AA,

    COUNT(DISTINCT CASE
        WHEN b.TIEM_DIA_ID BETWEEN DATEADD('day', -30, CURRENT_DATE - 1)
                               AND CURRENT_DATE - 1
        THEN b.SOCI_SOCI_ID END)        AS SOCIOS_UNICOS_ACTUAL,

    COUNT(DISTINCT CASE
        WHEN b.TIEM_DIA_ID BETWEEN DATEADD('day', -30, CURRENT_DATE - 1)
                               AND CURRENT_DATE - 1
        THEN b.TICKET END)              AS TICKETS_UNICOS_ACTUAL,

    ROUND(SUM(CASE
        WHEN b.TIEM_DIA_ID BETWEEN DATEADD('day', -30, CURRENT_DATE - 1)
                               AND CURRENT_DATE - 1
        THEN b.VNTA_IMPORTE_SIN_IVA ELSE 0 END), 2) AS MONTO_TOTAL_ACTUAL,

    COUNT(DISTINCT CASE
        WHEN b.TIEM_DIA_ID BETWEEN DATEADD('day', -30, DATEADD('year', -1, CURRENT_DATE - 1))
                               AND DATEADD('year', -1, CURRENT_DATE - 1)
        THEN b.SOCI_SOCI_ID END)        AS SOCIOS_UNICOS_AA,

    COUNT(DISTINCT CASE
        WHEN b.TIEM_DIA_ID BETWEEN DATEADD('day', -30, DATEADD('year', -1, CURRENT_DATE - 1))
                               AND DATEADD('year', -1, CURRENT_DATE - 1)
        THEN b.TICKET END)              AS TICKETS_UNICOS_AA,

    ROUND(SUM(CASE
        WHEN b.TIEM_DIA_ID BETWEEN DATEADD('day', -30, DATEADD('year', -1, CURRENT_DATE - 1))
                               AND DATEADD('year', -1, CURRENT_DATE - 1)
        THEN b.VNTA_IMPORTE_SIN_IVA ELSE 0 END), 2) AS MONTO_TOTAL_AA,

    COUNT(DISTINCT CASE
        WHEN b.TIEM_DIA_ID BETWEEN DATEADD('day', -30, CURRENT_DATE - 1)
                               AND CURRENT_DATE - 1
        THEN b.SOCI_SOCI_ID END)
    - COUNT(DISTINCT CASE
        WHEN b.TIEM_DIA_ID BETWEEN DATEADD('day', -30, DATEADD('year', -1, CURRENT_DATE - 1))
                               AND DATEADD('year', -1, CURRENT_DATE - 1)
        THEN b.SOCI_SOCI_ID END)        AS VAR_SOCIOS_ABS,

    ROUND(
        (COUNT(DISTINCT CASE
            WHEN b.TIEM_DIA_ID BETWEEN DATEADD('day', -30, CURRENT_DATE - 1)
                                   AND CURRENT_DATE - 1
            THEN b.SOCI_SOCI_ID END)
        - COUNT(DISTINCT CASE
            WHEN b.TIEM_DIA_ID BETWEEN DATEADD('day', -30, DATEADD('year', -1, CURRENT_DATE - 1))
                                   AND DATEADD('year', -1, CURRENT_DATE - 1)
            THEN b.SOCI_SOCI_ID END))
        / NULLIF(COUNT(DISTINCT CASE
            WHEN b.TIEM_DIA_ID BETWEEN DATEADD('day', -30, DATEADD('year', -1, CURRENT_DATE - 1))
                                   AND DATEADD('year', -1, CURRENT_DATE - 1)
            THEN b.SOCI_SOCI_ID END), 0) * 100
    , 1)                                AS VAR_SOCIOS_PCT,

    ROUND(
        (SUM(CASE
            WHEN b.TIEM_DIA_ID BETWEEN DATEADD('day', -30, CURRENT_DATE - 1)
                                   AND CURRENT_DATE - 1
            THEN b.VNTA_IMPORTE_SIN_IVA ELSE 0 END)
        - SUM(CASE
            WHEN b.TIEM_DIA_ID BETWEEN DATEADD('day', -30, DATEADD('year', -1, CURRENT_DATE - 1))
                                   AND DATEADD('year', -1, CURRENT_DATE - 1)
            THEN b.VNTA_IMPORTE_SIN_IVA ELSE 0 END))
        / NULLIF(SUM(CASE
            WHEN b.TIEM_DIA_ID BETWEEN DATEADD('day', -30, DATEADD('year', -1, CURRENT_DATE - 1))
                                   AND DATEADD('year', -1, CURRENT_DATE - 1)
            THEN b.VNTA_IMPORTE_SIN_IVA ELSE 0 END), 0) * 100
    , 1)                                AS VAR_MONTO_PCT,

    ROUND(
        COUNT(DISTINCT CASE
            WHEN b.TIEM_DIA_ID BETWEEN DATEADD('day', -30, CURRENT_DATE - 1)
                                   AND CURRENT_DATE - 1
            THEN b.SOCI_SOCI_ID END)
        / NULLIF(t.TOTAL_SOCIOS_ACTUAL, 0) * 100
    , 1)                                AS PCT_PENETRACION_ACTUAL

FROM base b
CROSS JOIN total_cadena t
GROUP BY b.DEPT_NAME, b.CLASS_NAME, t.TOTAL_SOCIOS_ACTUAL, t.TOTAL_SOCIOS_AA

UNION ALL

-- NIVEL SUBCLASE
SELECT
    'SUBCLASE'                          AS NIVEL,
    b.DEPT_NAME                         AS DEPARTAMENTO,
    b.CLASS_NAME                        AS CLASE,
    b.SUB_NAME                          AS SUBCLASE,
    NULL                                AS ARTICULO,
    t.TOTAL_SOCIOS_ACTUAL,
    t.TOTAL_SOCIOS_AA,

    COUNT(DISTINCT CASE
        WHEN b.TIEM_DIA_ID BETWEEN DATEADD('day', -30, CURRENT_DATE - 1)
                               AND CURRENT_DATE - 1
        THEN b.SOCI_SOCI_ID END)        AS SOCIOS_UNICOS_ACTUAL,

    COUNT(DISTINCT CASE
        WHEN b.TIEM_DIA_ID BETWEEN DATEADD('day', -30, CURRENT_DATE - 1)
                               AND CURRENT_DATE - 1
        THEN b.TICKET END)              AS TICKETS_UNICOS_ACTUAL,

    ROUND(SUM(CASE
        WHEN b.TIEM_DIA_ID BETWEEN DATEADD('day', -30, CURRENT_DATE - 1)
                               AND CURRENT_DATE - 1
        THEN b.VNTA_IMPORTE_SIN_IVA ELSE 0 END), 2) AS MONTO_TOTAL_ACTUAL,

    COUNT(DISTINCT CASE
        WHEN b.TIEM_DIA_ID BETWEEN DATEADD('day', -30, DATEADD('year', -1, CURRENT_DATE - 1))
                               AND DATEADD('year', -1, CURRENT_DATE - 1)
        THEN b.SOCI_SOCI_ID END)        AS SOCIOS_UNICOS_AA,

    COUNT(DISTINCT CASE
        WHEN b.TIEM_DIA_ID BETWEEN DATEADD('day', -30, DATEADD('year', -1, CURRENT_DATE - 1))
                               AND DATEADD('year', -1, CURRENT_DATE - 1)
        THEN b.TICKET END)              AS TICKETS_UNICOS_AA,

    ROUND(SUM(CASE
        WHEN b.TIEM_DIA_ID BETWEEN DATEADD('day', -30, DATEADD('year', -1, CURRENT_DATE - 1))
                               AND DATEADD('year', -1, CURRENT_DATE - 1)
        THEN b.VNTA_IMPORTE_SIN_IVA ELSE 0 END), 2) AS MONTO_TOTAL_AA,

    COUNT(DISTINCT CASE
        WHEN b.TIEM_DIA_ID BETWEEN DATEADD('day', -30, CURRENT_DATE - 1)
                               AND CURRENT_DATE - 1
        THEN b.SOCI_SOCI_ID END)
    - COUNT(DISTINCT CASE
        WHEN b.TIEM_DIA_ID BETWEEN DATEADD('day', -30, DATEADD('year', -1, CURRENT_DATE - 1))
                               AND DATEADD('year', -1, CURRENT_DATE - 1)
        THEN b.SOCI_SOCI_ID END)        AS VAR_SOCIOS_ABS,

    ROUND(
        (COUNT(DISTINCT CASE
            WHEN b.TIEM_DIA_ID BETWEEN DATEADD('day', -30, CURRENT_DATE - 1)
                                   AND CURRENT_DATE - 1
            THEN b.SOCI_SOCI_ID END)
        - COUNT(DISTINCT CASE
            WHEN b.TIEM_DIA_ID BETWEEN DATEADD('day', -30, DATEADD('year', -1, CURRENT_DATE - 1))
                                   AND DATEADD('year', -1, CURRENT_DATE - 1)
            THEN b.SOCI_SOCI_ID END))
        / NULLIF(COUNT(DISTINCT CASE
            WHEN b.TIEM_DIA_ID BETWEEN DATEADD('day', -30, DATEADD('year', -1, CURRENT_DATE - 1))
                                   AND DATEADD('year', -1, CURRENT_DATE - 1)
            THEN b.SOCI_SOCI_ID END), 0) * 100
    , 1)                                AS VAR_SOCIOS_PCT,

    ROUND(
        (SUM(CASE
            WHEN b.TIEM_DIA_ID BETWEEN DATEADD('day', -30, CURRENT_DATE - 1)
                                   AND CURRENT_DATE - 1
            THEN b.VNTA_IMPORTE_SIN_IVA ELSE 0 END)
        - SUM(CASE
            WHEN b.TIEM_DIA_ID BETWEEN DATEADD('day', -30, DATEADD('year', -1, CURRENT_DATE - 1))
                                   AND DATEADD('year', -1, CURRENT_DATE - 1)
            THEN b.VNTA_IMPORTE_SIN_IVA ELSE 0 END))
        / NULLIF(SUM(CASE
            WHEN b.TIEM_DIA_ID BETWEEN DATEADD('day', -30, DATEADD('year', -1, CURRENT_DATE - 1))
                                   AND DATEADD('year', -1, CURRENT_DATE - 1)
            THEN b.VNTA_IMPORTE_SIN_IVA ELSE 0 END), 0) * 100
    , 1)                                AS VAR_MONTO_PCT,

    ROUND(
        COUNT(DISTINCT CASE
            WHEN b.TIEM_DIA_ID BETWEEN DATEADD('day', -30, CURRENT_DATE - 1)
                                   AND CURRENT_DATE - 1
            THEN b.SOCI_SOCI_ID END)
        / NULLIF(t.TOTAL_SOCIOS_ACTUAL, 0) * 100
    , 1)                                AS PCT_PENETRACION_ACTUAL

FROM base b
CROSS JOIN total_cadena t
GROUP BY b.DEPT_NAME, b.CLASS_NAME, b.SUB_NAME, t.TOTAL_SOCIOS_ACTUAL, t.TOTAL_SOCIOS_AA

UNION ALL

-- NIVEL ARTICULO  (nuevo)
SELECT
    'ARTICULO'                          AS NIVEL,
    b.DEPT_NAME                         AS DEPARTAMENTO,
    b.CLASS_NAME                        AS CLASE,
    b.SUB_NAME                          AS SUBCLASE,
    b.ARTICULO_DESC                     AS ARTICULO,
    t.TOTAL_SOCIOS_ACTUAL,
    t.TOTAL_SOCIOS_AA,

    COUNT(DISTINCT CASE
        WHEN b.TIEM_DIA_ID BETWEEN DATEADD('day', -30, CURRENT_DATE - 1)
                               AND CURRENT_DATE - 1
        THEN b.SOCI_SOCI_ID END)        AS SOCIOS_UNICOS_ACTUAL,

    COUNT(DISTINCT CASE
        WHEN b.TIEM_DIA_ID BETWEEN DATEADD('day', -30, CURRENT_DATE - 1)
                               AND CURRENT_DATE - 1
        THEN b.TICKET END)              AS TICKETS_UNICOS_ACTUAL,

    ROUND(SUM(CASE
        WHEN b.TIEM_DIA_ID BETWEEN DATEADD('day', -30, CURRENT_DATE - 1)
                               AND CURRENT_DATE - 1
        THEN b.VNTA_IMPORTE_SIN_IVA ELSE 0 END), 2) AS MONTO_TOTAL_ACTUAL,

    COUNT(DISTINCT CASE
        WHEN b.TIEM_DIA_ID BETWEEN DATEADD('day', -30, DATEADD('year', -1, CURRENT_DATE - 1))
                               AND DATEADD('year', -1, CURRENT_DATE - 1)
        THEN b.SOCI_SOCI_ID END)        AS SOCIOS_UNICOS_AA,

    COUNT(DISTINCT CASE
        WHEN b.TIEM_DIA_ID BETWEEN DATEADD('day', -30, DATEADD('year', -1, CURRENT_DATE - 1))
                               AND DATEADD('year', -1, CURRENT_DATE - 1)
        THEN b.TICKET END)              AS TICKETS_UNICOS_AA,

    ROUND(SUM(CASE
        WHEN b.TIEM_DIA_ID BETWEEN DATEADD('day', -30, DATEADD('year', -1, CURRENT_DATE - 1))
                               AND DATEADD('year', -1, CURRENT_DATE - 1)
        THEN b.VNTA_IMPORTE_SIN_IVA ELSE 0 END), 2) AS MONTO_TOTAL_AA,

    COUNT(DISTINCT CASE
        WHEN b.TIEM_DIA_ID BETWEEN DATEADD('day', -30, CURRENT_DATE - 1)
                               AND CURRENT_DATE - 1
        THEN b.SOCI_SOCI_ID END)
    - COUNT(DISTINCT CASE
        WHEN b.TIEM_DIA_ID BETWEEN DATEADD('day', -30, DATEADD('year', -1, CURRENT_DATE - 1))
                               AND DATEADD('year', -1, CURRENT_DATE - 1)
        THEN b.SOCI_SOCI_ID END)        AS VAR_SOCIOS_ABS,

    ROUND(
        (COUNT(DISTINCT CASE
            WHEN b.TIEM_DIA_ID BETWEEN DATEADD('day', -30, CURRENT_DATE - 1)
                                   AND CURRENT_DATE - 1
            THEN b.SOCI_SOCI_ID END)
        - COUNT(DISTINCT CASE
            WHEN b.TIEM_DIA_ID BETWEEN DATEADD('day', -30, DATEADD('year', -1, CURRENT_DATE - 1))
                                   AND DATEADD('year', -1, CURRENT_DATE - 1)
            THEN b.SOCI_SOCI_ID END))
        / NULLIF(COUNT(DISTINCT CASE
            WHEN b.TIEM_DIA_ID BETWEEN DATEADD('day', -30, DATEADD('year', -1, CURRENT_DATE - 1))
                                   AND DATEADD('year', -1, CURRENT_DATE - 1)
            THEN b.SOCI_SOCI_ID END), 0) * 100
    , 1)                                AS VAR_SOCIOS_PCT,

    ROUND(
        (SUM(CASE
            WHEN b.TIEM_DIA_ID BETWEEN DATEADD('day', -30, CURRENT_DATE - 1)
                                   AND CURRENT_DATE - 1
            THEN b.VNTA_IMPORTE_SIN_IVA ELSE 0 END)
        - SUM(CASE
            WHEN b.TIEM_DIA_ID BETWEEN DATEADD('day', -30, DATEADD('year', -1, CURRENT_DATE - 1))
                                   AND DATEADD('year', -1, CURRENT_DATE - 1)
            THEN b.VNTA_IMPORTE_SIN_IVA ELSE 0 END))
        / NULLIF(SUM(CASE
            WHEN b.TIEM_DIA_ID BETWEEN DATEADD('day', -30, DATEADD('year', -1, CURRENT_DATE - 1))
                                   AND DATEADD('year', -1, CURRENT_DATE - 1)
            THEN b.VNTA_IMPORTE_SIN_IVA ELSE 0 END), 0) * 100
    , 1)                                AS VAR_MONTO_PCT,

    -- Penetracion del articulo sobre el TOTAL de la cadena
    ROUND(
        COUNT(DISTINCT CASE
            WHEN b.TIEM_DIA_ID BETWEEN DATEADD('day', -30, CURRENT_DATE - 1)
                                   AND CURRENT_DATE - 1
            THEN b.SOCI_SOCI_ID END)
        / NULLIF(t.TOTAL_SOCIOS_ACTUAL, 0) * 100
    , 1)                                AS PCT_PENETRACION_ACTUAL

FROM base b
CROSS JOIN total_cadena t
GROUP BY b.DEPT_NAME, b.CLASS_NAME, b.SUB_NAME, b.ARTICULO_ID, b.ARTICULO_DESC, t.TOTAL_SOCIOS_ACTUAL, t.TOTAL_SOCIOS_AA

ORDER BY DEPARTAMENTO DESC, CLASE DESC, SUBCLASE DESC, ARTICULO DESC;