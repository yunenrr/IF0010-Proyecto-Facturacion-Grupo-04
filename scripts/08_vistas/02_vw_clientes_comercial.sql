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
    CONVERT(VARCHAR(20), C.CEDULA) AS [Cedula],
    CASE
        WHEN CJ.CEDULA_CLIENTE IS NOT NULL
            THEN CJ.RAZON_SOCIAL
        ELSE CONCAT(
            CF.NOMBRE,
            ' ',
            CF.PRIMER_APELLIDO,
            ' ',
            CF.SEGUNDO_APELLIDO
        )
    END AS [NombreORazonSocial],
    ISNULL(
        F.CANTIDAD_FACTURAS,
        0
    ) AS [CantidadFacturas],
    CASE
        WHEN
            ISNULL(
                F.COMPRAS_ULTIMOS_6_MESES,
                0
            ) > 5
            THEN N'Sí'
        ELSE N'No'
    END AS [ClienteFrecuente]
FROM DBO.CLIENTE AS C
LEFT JOIN DBO.CLIENTEFISICO AS CF
    ON C.CEDULA = CF.CEDULA_CLIENTE
LEFT JOIN DBO.CLIENTEJURIDICO AS CJ
    ON C.CEDULA = CJ.CEDULA_CLIENTE
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
    WHERE F.FECHA_EMISION <= SYSDATETIME()
    GROUP BY F.CEDULA_CLIENTE
) AS F
    ON C.CEDULA = F.CEDULA_CLIENTE;
GO
