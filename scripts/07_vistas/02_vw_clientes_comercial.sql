USE FACTURACIONSOLUCIONESMAGNIFICAS;
GO

IF
    EXISTS (
        SELECT 1
        FROM SYS.OBJECTS
        WHERE
            NAME = 'VW_CLIENTES_COMERCIAL'
            AND TYPE = 'V'
    )
    BEGIN
        DROP VIEW DBO.VW_CLIENTES_COMERCIAL;
    END
GO

CREATE VIEW DBO.VW_CLIENTES_COMERCIAL
AS
SELECT
    C.CEDULA,
    CASE
        WHEN TC.CODIGO = 'JURIDICA'
            THEN C.RAZON_SOCIAL
        ELSE C.NOMBRE
    END AS NOMBRE_O_RAZON_SOCIAL,
    ISNULL(
        F.CANTIDAD_FACTURAS,
        0
    ) AS CANTIDAD_FACTURAS,
    CASE
        WHEN
            ISNULL(
                F.COMPRAS_ULTIMOS_6_MESES,
                0
            ) > 5
            THEN N'Sí'
        ELSE N'No'
    END AS CLIENTE_FRECUENTE
FROM DBO.CLIENTE AS C
INNER JOIN DBO.TIPOCLIENTE AS TC
    ON C.ID_TIPO_CLIENTE = TC.ID_TIPO_CLIENTE
LEFT JOIN (
    SELECT
        F.CEDULA_CLIENTE,
        COUNT(*) AS CANTIDAD_FACTURAS,
        SUM(
            CASE
                WHEN
                    F.FECHA_EMISION >= DATEADD(
                        MONTH,
                        -6,
                        SYSDATETIME()
                    )
                    AND F.FECHA_EMISION <= SYSDATETIME()
                    THEN 1
                ELSE 0
            END
        ) AS COMPRAS_ULTIMOS_6_MESES
    FROM DBO.FACTURA AS F
    GROUP BY F.CEDULA_CLIENTE
) AS F
    ON C.CEDULA = F.CEDULA_CLIENTE;
GO
