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

        DECLARE @ACTUAL BIGINT;
        DECLARE @FALTANTES INT;
        DECLARE @CANTIDAD_DIRECCIONES INT;
        DECLARE @AHORA DATETIME2(0);

        BEGIN TRANSACTION;

        SELECT @ACTUAL = COUNT_BIG(*)
        FROM DBO.CLIENTE;

        IF @ACTUAL < @TOTAL_OBJETIVO
            BEGIN
                SET @FALTANTES = CONVERT(
                    INT,
                    @TOTAL_OBJETIVO - @ACTUAL
                );

                SET @AHORA = CONVERT(DATETIME2(0), SYSDATETIME());

                CREATE TABLE #DIRECCIONES (
                    NUMERO INT NOT NULL PRIMARY KEY,
                    ID_DIRECCION INT NOT NULL
                );

                INSERT INTO #DIRECCIONES (
                    NUMERO,
                    ID_DIRECCION
                )
                SELECT
                    ROW_NUMBER() OVER (
                        ORDER BY D.ID_DIRECCION
                    ) AS NUMERO,
                    D.ID_DIRECCION
                FROM DBO.DIRECCION AS D;

                SELECT @CANTIDAD_DIRECCIONES = COUNT(*)
                FROM #DIRECCIONES;

                CREATE TABLE #NUEVOS (
                    CONTADOR INT NOT NULL PRIMARY KEY,
                    CEDULA VARCHAR(20) NOT NULL UNIQUE,
                    NUMERO_TIPO INT NOT NULL,
                    NUMERO_DIRECCION INT NOT NULL
                );

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
                        (N.CONTADOR + 1) / 2 AS NUMERO_TIPO,
                        CASE
                            WHEN N.CONTADOR % 2 = 0
                                THEN CONCAT(
                                    (N.NUMERO_TIPO - 1) % 7 + 1,
                                    '-',
                                    RIGHT(
                                        '0000' + CONVERT(
                                            VARCHAR(4),
                                            1000 + (
                                                N.NUMERO_TIPO - 1
                                            ) / 9999
                                        ),
                                        4
                                    ),
                                    '-',
                                    RIGHT(
                                        '0000' + CONVERT(
                                            VARCHAR(4),
                                            (N.NUMERO_TIPO - 1) % 9999 + 1
                                        ),
                                        4
                                    )
                                )
                            ELSE CONCAT(
                                '3-101-',
                                RIGHT(
                                    '000000' + CONVERT(
                                        VARCHAR(6),
                                        N.NUMERO_TIPO
                                    ),
                                    6
                                )
                            )
                        END AS CEDULA
                    FROM (
                        SELECT
                            NUM.CONTADOR,
                            (NUM.CONTADOR + 1) / 2 AS NUMERO_TIPO
                        FROM NUMEROS AS NUM
                    ) AS N
                )

                INSERT INTO #NUEVOS (
                    CONTADOR,
                    CEDULA,
                    NUMERO_TIPO,
                    NUMERO_DIRECCION
                )
                SELECT TOP (@FALTANTES)
                    C.CONTADOR,
                    C.CEDULA,
                    C.NUMERO_TIPO,
                    CONVERT(
                        INT,
                        (
                            @ACTUAL
                            + ROW_NUMBER()
                                OVER (
                                    ORDER BY C.CONTADOR
                                )
                            - 1
                        ) % @CANTIDAD_DIRECCIONES + 1
                    ) AS NUMERO_DIRECCION
                FROM CANDIDATOS AS C
                WHERE
                    NOT EXISTS (
                        SELECT 1
                        FROM DBO.CLIENTE AS EXISTENTE
                        WHERE EXISTENTE.CEDULA = C.CEDULA
                    )
                ORDER BY C.CONTADOR;

                INSERT INTO DBO.CLIENTE (
                    CEDULA,
                    ID_DIRECCION,
                    TELEFONO,
                    CORREO,
                    FECHA_REGISTRO,
                    FECHA_ACTUALIZACION
                )
                SELECT
                    N.CEDULA,
                    D.ID_DIRECCION,
                    CONCAT(
                        '8',
                        RIGHT(
                            '0000000' + CONVERT(
                                VARCHAR(7),
                                N.CONTADOR % 10000000
                            ),
                            7
                        )
                    ) AS TELEFONO,
                    CONCAT(
                        'cliente',
                        N.CONTADOR,
                        '@correo.com'
                    ) AS CORREO,
                    @AHORA AS FECHA_REGISTRO,
                    @AHORA AS FECHA_ACTUALIZACION
                FROM #NUEVOS AS N
                INNER JOIN #DIRECCIONES AS D
                    ON N.NUMERO_DIRECCION = D.NUMERO;

                INSERT INTO DBO.CLIENTEFISICO (
                    CEDULA_CLIENTE,
                    NOMBRE,
                    PRIMER_APELLIDO,
                    SEGUNDO_APELLIDO
                )
                SELECT
                    N.CEDULA AS CEDULA_CLIENTE,
                    CONCAT('Nombre ', N.NUMERO_TIPO) AS NOMBRE,
                    CONCAT(
                        'ApellidoP ',
                        N.NUMERO_TIPO
                    ) AS PRIMER_APELLIDO,
                    CONCAT(
                        'ApellidoS ',
                        N.NUMERO_TIPO
                    ) AS SEGUNDO_APELLIDO
                FROM #NUEVOS AS N
                WHERE N.CONTADOR % 2 = 0;

                INSERT INTO DBO.CLIENTEJURIDICO (
                    CEDULA_CLIENTE,
                    RAZON_SOCIAL,
                    NOMBRE_COMERCIAL
                )
                SELECT
                    N.CEDULA AS CEDULA_CLIENTE,
                    CONCAT(
                        'Empresa Cliente ',
                        N.NUMERO_TIPO,
                        ' S.A.'
                    ) AS RAZON_SOCIAL,
                    CONCAT(
                        'Comercial Cliente ',
                        N.NUMERO_TIPO
                    ) AS NOMBRE_COMERCIAL
                FROM #NUEVOS AS N
                WHERE N.CONTADOR % 2 <> 0;
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
