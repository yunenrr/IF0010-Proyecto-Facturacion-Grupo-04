USE FACTURACIONSOLUCIONESMAGNIFICAS;
GO

IF EXISTS (
    SELECT 1
    FROM sys.objects
    WHERE name = 'SP_GENERAR_DIRECCIONES'
      AND type = 'P'
)
BEGIN
    DROP PROCEDURE dbo.SP_GENERAR_DIRECCIONES;
END
GO

CREATE PROCEDURE dbo.SP_GENERAR_DIRECCIONES
    @TOTAL_OBJETIVO INT = 500
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF @TOTAL_OBJETIVO IS NULL OR @TOTAL_OBJETIVO <= 0
            THROW 51001, 'La cantidad de direcciones debe ser mayor que cero.', 1;

        IF NOT EXISTS (
            SELECT 1
            FROM dbo.BARRIO
        )
            THROW 51002, 'Primero se deben cargar las ubicaciones.', 1;

        BEGIN TRANSACTION;

        DECLARE @ACTUAL BIGINT;
        DECLARE @CODIGO_PROVINCIA INT;
        DECLARE @CODIGO_CANTON INT;
        DECLARE @CODIGO_DISTRITO INT;
        DECLARE @CODIGO_BARRIO INT;

        SELECT @ACTUAL = COUNT_BIG(*)
        FROM dbo.DIRECCION;

        SELECT TOP (1)
            @CODIGO_PROVINCIA = B.CODIGO_PROVINCIA,
            @CODIGO_CANTON = B.CODIGO_CANTON,
            @CODIGO_DISTRITO = B.CODIGO_DISTRITO,
            @CODIGO_BARRIO = B.CODIGO_BARRIO
        FROM dbo.BARRIO AS B
        ORDER BY
            B.CODIGO_PROVINCIA,
            B.CODIGO_CANTON,
            B.CODIGO_DISTRITO,
            B.CODIGO_BARRIO;

        WHILE @ACTUAL < @TOTAL_OBJETIVO
        BEGIN
            INSERT INTO dbo.DIRECCION (
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
                CONCAT('Direccion de prueba numero ', @ACTUAL + 1)
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

EXEC dbo.SP_GENERAR_DIRECCIONES @TOTAL_OBJETIVO = 500;
GO

DROP PROCEDURE dbo.SP_GENERAR_DIRECCIONES;
GO
