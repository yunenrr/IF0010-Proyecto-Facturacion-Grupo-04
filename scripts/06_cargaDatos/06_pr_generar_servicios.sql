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

        BEGIN TRANSACTION;

        DECLARE @ACTUAL BIGINT;
        DECLARE @CONTADOR INT = 1;
        DECLARE @CODIGO VARCHAR(30);
        DECLARE @DESCRIPCION VARCHAR(200);
        DECLARE @PRECIO DECIMAL(18, 2);
        DECLARE @IMPUESTO DECIMAL(5, 2);

        SELECT @ACTUAL = COUNT_BIG(*)
        FROM DBO.SERVICIO;

        WHILE @ACTUAL < @TOTAL_OBJETIVO
            BEGIN
                SET @CODIGO = CONCAT(
                    'SERV-GENERADO-',
                    @CONTADOR
                );

                IF
                    NOT EXISTS (
                        SELECT 1
                        FROM DBO.SERVICIO
                        WHERE CODIGO = @CODIGO
                    )
                    BEGIN
                        SET @DESCRIPCION = CONCAT(
                            CASE @CONTADOR % 4
                                WHEN 0 THEN 'Mantenimiento '
                                WHEN 1 THEN 'Instalacion '
                                WHEN 2 THEN 'Asesoria '
                                ELSE 'Soporte tecnico '
                            END,
                            @CONTADOR
                        );

                        SET @PRECIO = CONVERT(
                            DECIMAL(18, 2),
                            5000 + (@CONTADOR % 200) * 250
                        );

                        SET @IMPUESTO = CASE @CONTADOR % 4
                            WHEN 0 THEN 0
                            WHEN 1 THEN 1
                            WHEN 2 THEN 4
                            ELSE 13
                        END;

                        EXEC DBO.PR_CREAR_SERVICIO
                            @CODIGO = @CODIGO,
                            @DESCRIPCION = @DESCRIPCION,
                            @PRECIO_UNITARIO = @PRECIO,
                            @PORCENTAJE_IMPUESTO = @IMPUESTO,
                            @ACTIVO = 1;

                        SET @ACTUAL = @ACTUAL + 1;
                    END;

                SET @CONTADOR = @CONTADOR + 1;
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
