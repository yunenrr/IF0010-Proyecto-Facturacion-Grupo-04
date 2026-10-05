USE FACTURACIONSOLUCIONESMAGNIFICAS;
GO

IF EXISTS (
    SELECT 1
    FROM sys.objects
    WHERE name = 'SP_GENERAR_EMPRESAS'
      AND type = 'P'
)
BEGIN
    DROP PROCEDURE dbo.SP_GENERAR_EMPRESAS;
END
GO

CREATE PROCEDURE dbo.SP_GENERAR_EMPRESAS
    @TOTAL_OBJETIVO INT = 100
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF @TOTAL_OBJETIVO IS NULL OR @TOTAL_OBJETIVO < 100
            THROW 51201, 'Se deben generar al menos 100 empresas.', 1;

        IF NOT EXISTS (
            SELECT 1
            FROM dbo.DIRECCION
        )
            THROW 51202, 'Primero se deben generar direcciones.', 1;

        BEGIN TRANSACTION;

        DECLARE @ACTUAL BIGINT;
        DECLARE @CONTADOR INT = 1;
        DECLARE @CANTIDAD_DIRECCIONES INT;
        DECLARE @POSICION INT;
        DECLARE @ID_DIRECCION INT;

        DECLARE @CEDULA VARCHAR(20);
        DECLARE @NOMBRE VARCHAR(100);
        DECLARE @RAZON VARCHAR(150);
        DECLARE @TELEFONO VARCHAR(20);
        DECLARE @CORREO VARCHAR(100);

        SELECT @ACTUAL = COUNT_BIG(*)
        FROM dbo.EMPRESA;

        SELECT @CANTIDAD_DIRECCIONES = COUNT(*)
        FROM dbo.DIRECCION;

        WHILE @ACTUAL < @TOTAL_OBJETIVO
        BEGIN
            SET @CEDULA = CONCAT(
                '3-101-',
                RIGHT('000000000' + CONVERT(VARCHAR(9), @CONTADOR), 9)
            );

            IF NOT EXISTS (
                SELECT 1
                FROM dbo.EMPRESA
                WHERE CEDULA = @CEDULA
            )
            BEGIN
                SET @POSICION = CONVERT(INT, @ACTUAL % @CANTIDAD_DIRECCIONES);

                SELECT @ID_DIRECCION = D.ID_DIRECCION
                FROM dbo.DIRECCION AS D
                ORDER BY D.ID_DIRECCION
                OFFSET @POSICION ROWS
                FETCH NEXT 1 ROWS ONLY;

                SET @NOMBRE = CONCAT('Empresa de prueba ', @CONTADOR);
                SET @RAZON = CONCAT('Empresa de prueba ', @CONTADOR, ' S.A.');
                SET @TELEFONO = CONCAT(
                    '2',
                    RIGHT(
                        '0000000' + CONVERT(VARCHAR(7), @CONTADOR % 10000000),
                        7
                    )
                );
                SET @CORREO = CONCAT('empresa', @CONTADOR, '@correo.com');

                EXEC dbo.SP_CREAR_EMPRESA
                    @CEDULA = @CEDULA,
                    @NOMBRE_COMERCIAL = @NOMBRE,
                    @RAZON_SOCIAL = @RAZON,
                    @ID_DIRECCION = @ID_DIRECCION,
                    @TELEFONO = @TELEFONO,
                    @CORREO = @CORREO,
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

EXEC dbo.SP_GENERAR_EMPRESAS @TOTAL_OBJETIVO = 100;
GO

DROP PROCEDURE dbo.SP_GENERAR_EMPRESAS;
GO
