USE FACTURACIONSOLUCIONESMAGNIFICAS;
GO

IF
    EXISTS (
        SELECT 1
        FROM SYS.OBJECTS
        WHERE
            NAME = 'PR_GENERAR_DIRECCIONES'
            AND TYPE = 'P'
    )
    BEGIN
        DROP PROCEDURE DBO.PR_GENERAR_DIRECCIONES;
    END
GO

CREATE PROCEDURE DBO.PR_GENERAR_DIRECCIONES
    @TOTAL_OBJETIVO INT = 500
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF @TOTAL_OBJETIVO IS NULL OR @TOTAL_OBJETIVO <= 0
            THROW 51001, 'La cantidad debe ser mayor que cero.', 1;

        IF
            NOT EXISTS (
                SELECT 1
                FROM DBO.BARRIO
            )
            THROW 51002, 'Primero cargue las ubicaciones.', 1;

        BEGIN TRANSACTION;

        DECLARE @ACTUAL BIGINT;
        DECLARE @CODIGO_PROVINCIA INT;
        DECLARE @CODIGO_CANTON INT;
        DECLARE @CODIGO_DISTRITO INT;
        DECLARE @CODIGO_BARRIO INT;

        SELECT @ACTUAL = COUNT_BIG(*)
        FROM DBO.DIRECCION;

        SELECT TOP (1)
            @CODIGO_PROVINCIA = BARRIO.CODIGO_PROVINCIA,
            @CODIGO_CANTON = BARRIO.CODIGO_CANTON,
            @CODIGO_DISTRITO = BARRIO.CODIGO_DISTRITO,
            @CODIGO_BARRIO = BARRIO.CODIGO_BARRIO
        FROM DBO.BARRIO AS BARRIO
        ORDER BY
            BARRIO.CODIGO_PROVINCIA,
            BARRIO.CODIGO_CANTON,
            BARRIO.CODIGO_DISTRITO,
            BARRIO.CODIGO_BARRIO;

        WHILE @ACTUAL < @TOTAL_OBJETIVO
            BEGIN
                INSERT INTO DBO.DIRECCION (
                    CODIGO_PROVINCIA,
                    CODIGO_CANTON,
                    CODIGO_DISTRITO,
                    CODIGO_BARRIO,
                    SENAS_EXACTAS
                )
                VALUES (
                    @CODIGO_PROVINCIA,
                    @CODIGO_CANTON,
                    @CODIGO_DISTRITO,
                    @CODIGO_BARRIO,
                    CONCAT(
                        'Direccion de prueba numero ',
                        @ACTUAL + 1
                    )
                );

                SET @ACTUAL = @ACTUAL + 1;
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

EXEC DBO.PR_GENERAR_DIRECCIONES
    @TOTAL_OBJETIVO = 500;
GO

DROP PROCEDURE DBO.PR_GENERAR_DIRECCIONES;
GO
