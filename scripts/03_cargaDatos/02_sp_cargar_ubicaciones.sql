USE FACTURACIONSOLUCIONESMAGNIFICAS;
GO

IF EXISTS (
    SELECT 1
    FROM SYS.OBJECTS
    WHERE NAME = 'SP_CARGAR_UBICACIONES'
      AND TYPE = 'P'
)
BEGIN
    DROP PROCEDURE DBO.SP_CARGAR_UBICACIONES;
END
GO

CREATE PROCEDURE DBO.SP_CARGAR_UBICACIONES
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF NOT EXISTS (
            SELECT 1
            FROM DBO.PROVINCIA
            WHERE CODIGO_PROVINCIA = 1
        )
        BEGIN
            INSERT INTO DBO.PROVINCIA (CODIGO_PROVINCIA, NOMBRE)
            VALUES (1, 'San Jose');
        END;

        IF NOT EXISTS (
            SELECT 1
            FROM DBO.CANTON
            WHERE CODIGO_PROVINCIA = 1
              AND CODIGO_CANTON = 1
        )
        BEGIN
            INSERT INTO DBO.CANTON (CODIGO_PROVINCIA, CODIGO_CANTON, NOMBRE)
            VALUES (1, 1, 'San Jose');
        END;

        IF NOT EXISTS (
            SELECT 1
            FROM DBO.DISTRITO
            WHERE CODIGO_PROVINCIA = 1
              AND CODIGO_CANTON = 1
              AND CODIGO_DISTRITO = 1
        )
        BEGIN
            INSERT INTO DBO.DISTRITO (
                CODIGO_PROVINCIA,
                CODIGO_CANTON,
                CODIGO_DISTRITO,
                NOMBRE
            )
            VALUES (1, 1, 1, 'Carmen');
        END;

        IF NOT EXISTS (
            SELECT 1
            FROM DBO.BARRIO
            WHERE CODIGO_PROVINCIA = 1
              AND CODIGO_CANTON = 1
              AND CODIGO_DISTRITO = 1
              AND CODIGO_BARRIO = 1
        )
        BEGIN
            INSERT INTO DBO.BARRIO (
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

EXEC DBO.SP_CARGAR_UBICACIONES;
GO

DROP PROCEDURE DBO.SP_CARGAR_UBICACIONES;
GO
