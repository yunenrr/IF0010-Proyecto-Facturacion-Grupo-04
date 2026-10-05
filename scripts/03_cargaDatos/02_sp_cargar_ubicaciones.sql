USE FACTURACIONSOLUCIONESMAGNIFICAS;
GO

IF EXISTS (
    SELECT 1
    FROM sys.objects
    WHERE name = 'SP_CARGAR_UBICACIONES'
      AND type = 'P'
)
BEGIN
    DROP PROCEDURE dbo.SP_CARGAR_UBICACIONES;
END
GO

CREATE PROCEDURE dbo.SP_CARGAR_UBICACIONES
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF NOT EXISTS (
            SELECT 1
            FROM dbo.PROVINCIA
            WHERE CODIGO_PROVINCIA = 1
        )
        BEGIN
            INSERT INTO dbo.PROVINCIA (CODIGO_PROVINCIA, NOMBRE)
            VALUES (1, 'San Jose');
        END;

        IF NOT EXISTS (
            SELECT 1
            FROM dbo.CANTON
            WHERE CODIGO_PROVINCIA = 1
              AND CODIGO_CANTON = 1
        )
        BEGIN
            INSERT INTO dbo.CANTON (CODIGO_PROVINCIA, CODIGO_CANTON, NOMBRE)
            VALUES (1, 1, 'San Jose');
        END;

        IF NOT EXISTS (
            SELECT 1
            FROM dbo.DISTRITO
            WHERE CODIGO_PROVINCIA = 1
              AND CODIGO_CANTON = 1
              AND CODIGO_DISTRITO = 1
        )
        BEGIN
            INSERT INTO dbo.DISTRITO (
                CODIGO_PROVINCIA,
                CODIGO_CANTON,
                CODIGO_DISTRITO,
                NOMBRE
            )
            VALUES (1, 1, 1, 'Carmen');
        END;

        IF NOT EXISTS (
            SELECT 1
            FROM dbo.BARRIO
            WHERE CODIGO_PROVINCIA = 1
              AND CODIGO_CANTON = 1
              AND CODIGO_DISTRITO = 1
              AND CODIGO_BARRIO = 1
        )
        BEGIN
            INSERT INTO dbo.BARRIO (
                CODIGO_PROVINCIA,
                CODIGO_CANTON,
                CODIGO_DISTRITO,
                CODIGO_BARRIO,
                NOMBRE
            )
            VALUES (1, 1, 1, 1, 'Barrio Central');
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

EXEC dbo.SP_CARGAR_UBICACIONES;
GO

DROP PROCEDURE dbo.SP_CARGAR_UBICACIONES;
GO
