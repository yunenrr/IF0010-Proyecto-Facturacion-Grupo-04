USE FACTURACIONSOLUCIONESMAGNIFICAS;
GO

IF
    EXISTS (
        SELECT 1
        FROM SYS.OBJECTS
        WHERE
            NAME = 'PR_GENERAR_SERVICIOS'
            AND TYPE = 'P'
    )
    BEGIN
        DROP PROCEDURE DBO.PR_GENERAR_SERVICIOS;
    END
GO

CREATE PROCEDURE DBO.PR_GENERAR_SERVICIOS
    @TOTAL_OBJETIVO INT = 500
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF @TOTAL_OBJETIVO IS NULL OR @TOTAL_OBJETIVO < 500
            THROW 51601, 'Se deben generar al menos 500 servicios.', 1;

        DECLARE @ACTUAL BIGINT;
        DECLARE @FALTANTES INT;
        DECLARE @AHORA DATETIME2(0);

        BEGIN TRANSACTION;

        SELECT @ACTUAL = COUNT_BIG(*)
        FROM DBO.SERVICIO;

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
                )

                INSERT INTO DBO.SERVICIO (
                    CODIGO,
                    DESCRIPCION,
                    PRECIO_UNITARIO,
                    PORCENTAJE_IMPUESTO,
                    FECHA_CREACION,
                    FECHA_MODIFICACION,
                    ACTIVO
                )
                SELECT TOP (@FALTANTES)
                    CONCAT(
                        'SERV-GENERADO-',
                        N.CONTADOR
                    ) AS CODIGO,
                    CONCAT(
                        CASE N.CONTADOR % 4
                            WHEN 0 THEN 'Mantenimiento '
                            WHEN 1 THEN 'Instalacion '
                            WHEN 2 THEN 'Asesoria '
                            ELSE 'Soporte tecnico '
                        END,
                        N.CONTADOR
                    ) AS DESCRIPCION,
                    CONVERT(
                        DECIMAL(18, 2),
                        5000 + (N.CONTADOR % 200) * 250
                    ) AS PRECIO_UNITARIO,
                    CASE N.CONTADOR % 4
                        WHEN 0 THEN 0
                        WHEN 1 THEN 1
                        WHEN 2 THEN 4
                        ELSE 13
                    END AS PORCENTAJE_IMPUESTO,
                    @AHORA AS FECHA_CREACION,
                    @AHORA AS FECHA_MODIFICACION,
                    1 AS ACTIVO
                FROM NUMEROS AS N
                WHERE
                    NOT EXISTS (
                        SELECT 1
                        FROM DBO.SERVICIO AS S
                        WHERE S.CODIGO = CONCAT(
                            'SERV-GENERADO-',
                            N.CONTADOR
                        )
                    )
                ORDER BY N.CONTADOR;
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

EXEC DBO.PR_GENERAR_SERVICIOS
    @TOTAL_OBJETIVO = 500;
GO

DROP PROCEDURE DBO.PR_GENERAR_SERVICIOS;
GO
