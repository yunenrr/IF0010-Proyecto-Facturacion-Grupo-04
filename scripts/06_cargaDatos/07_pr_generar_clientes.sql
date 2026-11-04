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

        IF
            NOT EXISTS (
                SELECT 1
                FROM DBO.DIRECCION
            )
            THROW 50023, 'Primero genere las direcciones.', 1;

        BEGIN TRANSACTION;

        DECLARE @ACTUAL BIGINT;
        DECLARE @CONTADOR INT = 1;
        DECLARE @NUMERO_TIPO INT;
        DECLARE @PROVINCIA INT;
        DECLARE @SEGUNDO_GRUPO INT;
        DECLARE @TERCER_GRUPO INT;
        DECLARE @CANTIDAD_DIRECCIONES INT;
        DECLARE @POSICION INT;
        DECLARE @CEDULA VARCHAR(20);
        DECLARE @TIPO_CLIENTE VARCHAR(10);
        DECLARE @NOMBRE VARCHAR(150);
        DECLARE @RAZON_SOCIAL VARCHAR(150);
        DECLARE @PRIMER_APELLIDO VARCHAR(100);
        DECLARE @SEGUNDO_APELLIDO VARCHAR(100);
        DECLARE @NOMBRE_COMERCIAL VARCHAR(150);
        DECLARE @ID_DIRECCION INT;
        DECLARE @TELEFONO VARCHAR(20);
        DECLARE @CORREO VARCHAR(100);

        SELECT @ACTUAL = COUNT_BIG(*)
        FROM DBO.CLIENTE;

        SELECT @CANTIDAD_DIRECCIONES = COUNT(*)
        FROM DBO.DIRECCION;

        WHILE @ACTUAL < @TOTAL_OBJETIVO
            BEGIN
                SET @NUMERO_TIPO = (
                    @CONTADOR + 1
                ) / 2;

                IF @CONTADOR % 2 = 0
                    SET @TIPO_CLIENTE = 'FISICA';

                IF @CONTADOR % 2 <> 0
                    SET @TIPO_CLIENTE = 'JURIDICA';

                IF @TIPO_CLIENTE = 'FISICA'
                    SET @PROVINCIA = (
                        (@NUMERO_TIPO - 1) % 7
                    ) + 1;

                IF @TIPO_CLIENTE = 'FISICA'
                    SET @SEGUNDO_GRUPO = 1000 + (
                        (@NUMERO_TIPO - 1) / 9999
                    );

                IF @TIPO_CLIENTE = 'FISICA'
                    SET @TERCER_GRUPO = (
                        (@NUMERO_TIPO - 1) % 9999
                    ) + 1;

                IF @TIPO_CLIENTE = 'FISICA'
                    SET @CEDULA = CONCAT(
                        @PROVINCIA,
                        '-',
                        RIGHT(
                            '0000'
                            + CONVERT(
                                VARCHAR(4),
                                @SEGUNDO_GRUPO
                            ),
                            4
                        ),
                        '-',
                        RIGHT(
                            '0000'
                            + CONVERT(
                                VARCHAR(4),
                                @TERCER_GRUPO
                            ),
                            4
                        )
                    );

                IF @TIPO_CLIENTE = 'JURIDICA'
                    SET @CEDULA = CONCAT(
                        '3-101-',
                        RIGHT(
                            '000000'
                            + CONVERT(
                                VARCHAR(6),
                                @NUMERO_TIPO
                            ),
                            6
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

                        SELECT @ID_DIRECCION = D.ID_DIRECCION
                        FROM DBO.DIRECCION AS D
                        ORDER BY
                            D.ID_DIRECCION
                            OFFSET @POSICION ROWS
                            FETCH NEXT 1 ROWS ONLY;

                        SET @NOMBRE = NULL;
                        SET @RAZON_SOCIAL = NULL;
                        SET @PRIMER_APELLIDO = NULL;
                        SET @SEGUNDO_APELLIDO = NULL;
                        SET @NOMBRE_COMERCIAL = NULL;

                        IF @TIPO_CLIENTE = 'FISICA'
                            BEGIN
                                SET @NOMBRE = CONCAT(
                                    'Nombre ',
                                    @NUMERO_TIPO
                                );

                                SET @PRIMER_APELLIDO = CONCAT(
                                    'ApellidoP ',
                                    @NUMERO_TIPO
                                );

                                SET @SEGUNDO_APELLIDO = CONCAT(
                                    'ApellidoS ',
                                    @NUMERO_TIPO
                                );
                            END;

                        IF @TIPO_CLIENTE = 'JURIDICA'
                            BEGIN
                                SET @RAZON_SOCIAL = CONCAT(
                                    'Empresa Cliente ',
                                    @NUMERO_TIPO,
                                    ' S.A.'
                                );

                                SET @NOMBRE_COMERCIAL = CONCAT(
                                    'Comercial Cliente ',
                                    @NUMERO_TIPO
                                );
                            END;

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
                            @CORREO = @CORREO,
                            @PRIMER_APELLIDO = @PRIMER_APELLIDO,
                            @SEGUNDO_APELLIDO = @SEGUNDO_APELLIDO,
                            @NOMBRE_COMERCIAL = @NOMBRE_COMERCIAL;

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
