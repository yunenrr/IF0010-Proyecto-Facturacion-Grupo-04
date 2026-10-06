USE FACTURACIONSOLUCIONESMAGNIFICAS;
GO

IF
    EXISTS (
        SELECT 1
        FROM SYS.OBJECTS
        WHERE
            NAME = 'PR_GENERAR_CLIENTES'
            AND TYPE = 'P'
    )
    BEGIN
        DROP PROCEDURE DBO.PR_GENERAR_CLIENTES;
    END
GO

CREATE PROCEDURE DBO.PR_GENERAR_CLIENTES
    @TOTAL_OBJETIVO INT = 50000
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF @TOTAL_OBJETIVO IS NULL OR @TOTAL_OBJETIVO < 50000
            THROW 50020, 'Se deben generar al menos 50000 clientes.', 1;

        IF (
            NOT EXISTS (
                SELECT 1
                FROM DBO.TIPOCLIENTE
                WHERE CODIGO = 'FISICA'
            )
            OR NOT EXISTS (
                SELECT 1
                FROM DBO.TIPOCLIENTE
                WHERE CODIGO = 'JURIDICA'
            )
        )
            THROW 50021, 'Primero cargue los tipos de cliente.', 1;

        IF
            NOT EXISTS (
                SELECT 1
                FROM DBO.DIRECCION
            )
            THROW 50022, 'Primero genere las direcciones.', 1;

        BEGIN TRANSACTION;

        DECLARE @ACTUAL BIGINT;
        DECLARE @CONTADOR INT = 1;
        DECLARE @CANTIDAD_DIRECCIONES INT;
        DECLARE @POSICION INT;
        DECLARE @CEDULA VARCHAR(20);
        DECLARE @TIPO_CLIENTE VARCHAR(10);
        DECLARE @NOMBRE VARCHAR(150);
        DECLARE @RAZON_SOCIAL VARCHAR(150);
        DECLARE @ID_DIRECCION INT;
        DECLARE @TELEFONO VARCHAR(20);
        DECLARE @CORREO VARCHAR(100);

        SELECT @ACTUAL = COUNT_BIG(*)
        FROM DBO.CLIENTE;

        SELECT @CANTIDAD_DIRECCIONES = COUNT(*)
        FROM DBO.DIRECCION;

        WHILE @ACTUAL < @TOTAL_OBJETIVO
            BEGIN
                SET @CEDULA = CONCAT(
                    'CLI',
                    RIGHT(
                        '00000000'
                        + CONVERT(VARCHAR(8), @CONTADOR),
                        8
                    )
                );

                IF
                    NOT EXISTS (
                        SELECT 1
                        FROM DBO.CLIENTE
                        WHERE CEDULA = @CEDULA
                    )
                    BEGIN
                        SET @POSICION = CONVERT(
                            INT,
                            @ACTUAL % @CANTIDAD_DIRECCIONES
                        );

                        SELECT
                            @ID_DIRECCION = DIRECCION.ID_DIRECCION
                        FROM DBO.DIRECCION AS DIRECCION
                        ORDER BY DIRECCION.ID_DIRECCION
                        OFFSET @POSICION ROWS
                        FETCH NEXT 1 ROWS ONLY;

                        IF @CONTADOR % 2 = 0
                            SET @TIPO_CLIENTE = 'FISICA';

                        IF @CONTADOR % 2 = 0
                            SET @NOMBRE = CONCAT(
                                'Cliente Fisico ',
                                @CONTADOR
                            );

                        IF @CONTADOR % 2 = 0
                            SET @RAZON_SOCIAL = 'NO APLICA';

                        IF @CONTADOR % 2 <> 0
                            SET @TIPO_CLIENTE = 'JURIDICA';

                        IF @CONTADOR % 2 <> 0
                            SET @NOMBRE = 'NO APLICA';

                        IF @CONTADOR % 2 <> 0
                            SET @RAZON_SOCIAL = CONCAT(
                                'Empresa Cliente ',
                                @CONTADOR,
                                ' S.A.'
                            );

                        SET @TELEFONO = CONCAT(
                            '8',
                            RIGHT(
                                '0000000'
                                + CONVERT(
                                    VARCHAR(7),
                                    @CONTADOR % 10000000
                                ),
                                7
                            )
                        );

                        SET @CORREO = CONCAT(
                            'cliente',
                            @CONTADOR,
                            '@correo.com'
                        );

                        EXEC DBO.PR_CREAR_CLIENTE
                            @CEDULA = @CEDULA,
                            @TIPO_CLIENTE = @TIPO_CLIENTE,
                            @NOMBRE = @NOMBRE,
                            @RAZON_SOCIAL = @RAZON_SOCIAL,
                            @ID_DIRECCION = @ID_DIRECCION,
                            @TELEFONO = @TELEFONO,
                            @CORREO = @CORREO;

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

EXEC DBO.PR_GENERAR_CLIENTES
    @TOTAL_OBJETIVO = 50000;
GO

DROP PROCEDURE DBO.PR_GENERAR_CLIENTES;
GO
