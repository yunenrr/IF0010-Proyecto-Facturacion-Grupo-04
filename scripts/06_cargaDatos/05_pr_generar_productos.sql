USE FACTURACIONSOLUCIONESMAGNIFICAS;
GO

IF
    EXISTS (
        SELECT 1
        FROM SYS.OBJECTS
        WHERE
            NAME = 'PR_GENERAR_PRODUCTOS'
            AND TYPE = 'P'
    )
    BEGIN
        DROP PROCEDURE DBO.PR_GENERAR_PRODUCTOS;
    END
GO

CREATE PROCEDURE DBO.PR_GENERAR_PRODUCTOS
    @TOTAL_OBJETIVO INT = 500
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF @TOTAL_OBJETIVO IS NULL OR @TOTAL_OBJETIVO < 500
            THROW 51401, 'Se deben generar al menos 500 productos.', 1;

        IF (
            NOT EXISTS (
                SELECT 1
                FROM DBO.TIPOPRODUCTO
                WHERE CODIGO = 'FISICO'
            )
            OR NOT EXISTS (
                SELECT 1
                FROM DBO.TIPOPRODUCTO
                WHERE CODIGO = 'DIGITAL'
            )
        )
            THROW 51402, 'Primero cargue los tipos de producto.', 1;

        DECLARE @ACTUAL BIGINT;
        DECLARE @FALTANTES INT;
        DECLARE @AHORA DATETIME2(0);

        BEGIN TRANSACTION;

        SELECT @ACTUAL = COUNT_BIG(*)
        FROM DBO.PRODUCTO;

        IF @ACTUAL < @TOTAL_OBJETIVO
            BEGIN
                SET @FALTANTES = CONVERT(
                    INT,
                    @TOTAL_OBJETIVO - @ACTUAL
                );

                SET @AHORA = CONVERT(DATETIME2(0), SYSDATETIME());

                WITH NUMEROS AS (
                    SELECT TOP (@TOTAL_OBJETIVO + @ACTUAL)
                        ROW_NUMBER() OVER (
                            ORDER BY (SELECT NULL)
                        ) AS CONTADOR
                    FROM SYS.ALL_OBJECTS AS A
                    CROSS JOIN SYS.ALL_OBJECTS AS B
                ),

                CANDIDATOS AS (
                    SELECT
                        N.CONTADOR,
                        CONCAT(
                            'PROD-GENERADO-',
                            N.CONTADOR
                        ) AS CODIGO,
                        CASE
                            WHEN N.CONTADOR % 2 = 0 THEN 'DIGITAL'
                            ELSE 'FISICO'
                        END AS TIPO
                    FROM NUMEROS AS N
                )

                INSERT INTO DBO.PRODUCTO (
                    CODIGO,
                    DESCRIPCION,
                    ID_TIPO_PRODUCTO,
                    CANTIDAD_DISPONIBLE,
                    PRECIO_UNITARIO,
                    PORCENTAJE_IMPUESTO,
                    FECHA_CREACION,
                    FECHA_MODIFICACION,
                    ACTIVO
                )
                SELECT TOP (@FALTANTES)
                    C.CODIGO,
                    CONCAT('Producto de prueba ', C.CONTADOR) AS DESCRIPCION,
                    TP.ID_TIPO_PRODUCTO,
                    CASE
                        WHEN C.TIPO = 'FISICO'
                            THEN 10 + C.CONTADOR % 491
                        ELSE 0
                    END AS CANTIDAD_DISPONIBLE,
                    CONVERT(
                        DECIMAL(18, 2),
                        100 + (C.CONTADOR % 1000) * 25.50
                    ) AS PRECIO_UNITARIO,
                    CASE C.CONTADOR % 4
                        WHEN 0 THEN 0
                        WHEN 1 THEN 1
                        WHEN 2 THEN 4
                        ELSE 13
                    END AS PORCENTAJE_IMPUESTO,
                    @AHORA AS FECHA_CREACION,
                    @AHORA AS FECHA_MODIFICACION,
                    1 AS ACTIVO
                FROM CANDIDATOS AS C
                INNER JOIN DBO.TIPOPRODUCTO AS TP
                    ON C.TIPO = TP.CODIGO
                WHERE
                    NOT EXISTS (
                        SELECT 1
                        FROM DBO.PRODUCTO AS P
                        WHERE P.CODIGO = C.CODIGO
                    )
                ORDER BY C.CONTADOR;
            END;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH;
END;
GO

EXEC DBO.PR_GENERAR_PRODUCTOS
    @TOTAL_OBJETIVO = 500;
GO

DROP PROCEDURE DBO.PR_GENERAR_PRODUCTOS;
GO
