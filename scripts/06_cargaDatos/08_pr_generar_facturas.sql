USE FACTURACIONSOLUCIONESMAGNIFICAS;
GO

IF
    EXISTS (
        SELECT 1
        FROM SYS.OBJECTS
        WHERE
            NAME = 'PR_GENERAR_FACTURAS'
            AND TYPE = 'P'
    )
    BEGIN
        DROP PROCEDURE DBO.PR_GENERAR_FACTURAS;
    END
GO

CREATE PROCEDURE DBO.PR_GENERAR_FACTURAS
    @TOTAL_OBJETIVO INT = 500000
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF @TOTAL_OBJETIVO IS NULL OR @TOTAL_OBJETIVO < 500000
            THROW 52401, 'Se deben generar al menos 500000 facturas.', 1;

        IF
            NOT EXISTS (
                SELECT 1
                FROM DBO.EMPRESA
                WHERE ACTIVO = 1
            )
            THROW 52402, 'No existen empresas activas.', 1;

        IF
            NOT EXISTS (
                SELECT 1
                FROM DBO.CLIENTE
            )
            THROW 52403, 'No existen clientes.', 1;

        IF
            NOT EXISTS (
                SELECT 1
                FROM DBO.TIPODOCUMENTO
            )
            THROW 52404, 'No existen tipos de documento.', 1;

        IF
            NOT EXISTS (
                SELECT 1
                FROM DBO.MONEDA
            )
            THROW 52405, 'No existen monedas.', 1;

        IF
            NOT EXISTS (
                SELECT 1
                FROM DBO.ESTADOFACTURA
            )
            THROW 52406, 'No existen estados de factura.', 1;

        IF (
            (
                SELECT COUNT(*)
                FROM DBO.PRODUCTO
                WHERE ACTIVO = 1
            ) + (
                SELECT COUNT(*)
                FROM DBO.SERVICIO
                WHERE ACTIVO = 1
            )
        ) < 5
            THROW 52407, 'Se necesitan al menos cinco articulos activos.', 1;

        DECLARE @ACTUAL BIGINT;
        DECLARE @FALTANTES INT;
        DECLARE @LOTE INT;
        DECLARE @TAMANO_LOTE INT = 20000;
        DECLARE @AHORA DATETIME2(0);
        DECLARE @CANTIDAD_EMPRESAS INT;
        DECLARE @CANTIDAD_CLIENTES INT;
        DECLARE @CANTIDAD_TIPOS INT;
        DECLARE @CANTIDAD_MONEDAS INT;
        DECLARE @CANTIDAD_ESTADOS INT;
        DECLARE @CANTIDAD_ARTICULOS INT;

        SET @AHORA = CONVERT(
            DATETIME2(0),
            SYSDATETIME()
        );

        SELECT @ACTUAL = COUNT_BIG(*)
        FROM DBO.FACTURA;

        IF @ACTUAL >= @TOTAL_OBJETIVO
            RETURN;

        CREATE TABLE #EMPRESAS (
            NUMERO INT NOT NULL PRIMARY KEY,
            CEDULA VARCHAR(20) NOT NULL
        );

        CREATE TABLE #CLIENTES (
            NUMERO INT NOT NULL PRIMARY KEY,
            CEDULA VARCHAR(20) NOT NULL
        );

        CREATE TABLE #TIPOS (
            NUMERO INT NOT NULL PRIMARY KEY,
            CODIGO VARCHAR(10) NOT NULL
        );

        CREATE TABLE #MONEDAS (
            NUMERO INT NOT NULL PRIMARY KEY,
            CODIGO CHAR(3) NOT NULL
        );

        CREATE TABLE #ESTADOS (
            NUMERO INT NOT NULL PRIMARY KEY,
            ESTADO VARCHAR(20) NOT NULL
        );

        CREATE TABLE #ARTICULOS (
            NUMERO INT NOT NULL PRIMARY KEY,
            CODIGO VARCHAR(30) NOT NULL,
            TIPO CHAR(1) NOT NULL,
            DESCRIPCION VARCHAR(200) NOT NULL,
            PRECIO_UNITARIO DECIMAL(18, 2) NOT NULL,
            PORCENTAJE_IMPUESTO DECIMAL(5, 2) NOT NULL
        );

        INSERT INTO #EMPRESAS (
            NUMERO,
            CEDULA
        )
        SELECT
            ROW_NUMBER() OVER (
                ORDER BY E.CEDULA
            ) AS NUMERO,
            E.CEDULA
        FROM DBO.EMPRESA AS E
        WHERE E.ACTIVO = 1;

        INSERT INTO #CLIENTES (
            NUMERO,
            CEDULA
        )
        SELECT
            ROW_NUMBER() OVER (
                ORDER BY C.CEDULA
            ) AS NUMERO,
            C.CEDULA
        FROM DBO.CLIENTE AS C;

        INSERT INTO #TIPOS (
            NUMERO,
            CODIGO
        )
        SELECT
            ROW_NUMBER() OVER (
                ORDER BY T.CODIGO
            ) AS NUMERO,
            T.CODIGO
        FROM DBO.TIPODOCUMENTO AS T;

        INSERT INTO #MONEDAS (
            NUMERO,
            CODIGO
        )
        SELECT
            ROW_NUMBER() OVER (
                ORDER BY M.CODIGO
            ) AS NUMERO,
            M.CODIGO
        FROM DBO.MONEDA AS M;

        INSERT INTO #ESTADOS (
            NUMERO,
            ESTADO
        )
        SELECT
            ROW_NUMBER() OVER (
                ORDER BY E.ESTADO
            ) AS NUMERO,
            E.ESTADO
        FROM DBO.ESTADOFACTURA AS E;

        INSERT INTO #ARTICULOS (
            NUMERO,
            CODIGO,
            TIPO,
            DESCRIPCION,
            PRECIO_UNITARIO,
            PORCENTAJE_IMPUESTO
        )
        SELECT
            ROW_NUMBER() OVER (
                ORDER BY A.TIPO, A.CODIGO
            ) AS NUMERO,
            A.CODIGO,
            A.TIPO,
            A.DESCRIPCION,
            A.PRECIO_UNITARIO,
            A.PORCENTAJE_IMPUESTO
        FROM (
            SELECT
                P.CODIGO,
                CONVERT(CHAR(1), 'P') AS TIPO,
                P.DESCRIPCION,
                P.PRECIO_UNITARIO,
                P.PORCENTAJE_IMPUESTO
            FROM DBO.PRODUCTO AS P
            WHERE P.ACTIVO = 1

            UNION ALL

            SELECT
                S.CODIGO,
                CONVERT(CHAR(1), 'S') AS TIPO,
                S.DESCRIPCION,
                S.PRECIO_UNITARIO,
                S.PORCENTAJE_IMPUESTO
            FROM DBO.SERVICIO AS S
            WHERE S.ACTIVO = 1
        ) AS A;

        SELECT @CANTIDAD_EMPRESAS = COUNT(*)
        FROM #EMPRESAS;

        SELECT @CANTIDAD_CLIENTES = COUNT(*)
        FROM #CLIENTES;

        SELECT @CANTIDAD_TIPOS = COUNT(*)
        FROM #TIPOS;

        SELECT @CANTIDAD_MONEDAS = COUNT(*)
        FROM #MONEDAS;

        SELECT @CANTIDAD_ESTADOS = COUNT(*)
        FROM #ESTADOS;

        SELECT @CANTIDAD_ARTICULOS = COUNT(*)
        FROM #ARTICULOS;

        CREATE TABLE #NUMEROS (
            NUMERO INT NOT NULL PRIMARY KEY
        );

        INSERT INTO #NUMEROS (NUMERO)
        SELECT TOP (@TAMANO_LOTE)
            ROW_NUMBER() OVER (
                ORDER BY (SELECT NULL)
            ) AS NUMERO
        FROM SYS.ALL_OBJECTS AS A
        CROSS JOIN SYS.ALL_OBJECTS AS B;

        CREATE TABLE #NUEVAS_FACTURAS (
            ID_FACTURA BIGINT NOT NULL PRIMARY KEY
        );

        CREATE TABLE #DETALLES_LOTE (
            ID_FACTURA BIGINT NOT NULL,
            NUMERO_LINEA INT NOT NULL,
            CODIGO VARCHAR(30) NOT NULL,
            TIPO CHAR(1) NOT NULL,
            DESCRIPCION VARCHAR(200) NOT NULL,
            CANTIDAD DECIMAL(18, 4) NOT NULL,
            PRECIO_UNITARIO DECIMAL(18, 2) NOT NULL,
            PORCENTAJE_IMPUESTO DECIMAL(5, 2) NOT NULL,
            SUBTOTAL DECIMAL(18, 2) NOT NULL,
            MONTO_DESCUENTO DECIMAL(18, 2) NOT NULL,
            MONTO_IMPUESTO DECIMAL(18, 2) NOT NULL,
            TOTAL_LINEA DECIMAL(18, 2) NOT NULL,
            PRIMARY KEY (ID_FACTURA, NUMERO_LINEA)
        );

        WHILE @ACTUAL < @TOTAL_OBJETIVO
            BEGIN
                SET @FALTANTES = CONVERT(
                    INT,
                    @TOTAL_OBJETIVO - @ACTUAL
                );

                SET @LOTE = CASE
                    WHEN @FALTANTES > @TAMANO_LOTE
                        THEN @TAMANO_LOTE
                    ELSE @FALTANTES
                END;

                TRUNCATE TABLE #NUEVAS_FACTURAS;
                TRUNCATE TABLE #DETALLES_LOTE;

                BEGIN TRANSACTION;

                WITH NUMEROS AS (
                    SELECT
                        N.NUMERO,
                        DATEADD(
                            SECOND,
                            -CONVERT(INT, (N.NUMERO + @ACTUAL) * 60),
                            @AHORA
                        ) AS FECHA_EMISION
                    FROM #NUMEROS AS N
                    WHERE N.NUMERO <= @LOTE
                )

                INSERT INTO DBO.FACTURA (
                    IDENTIFICADOR_COMPROBANTE,
                    CEDULA_EMPRESA,
                    CEDULA_CLIENTE,
                    CODIGO_TIPO_DOCUMENTO,
                    CODIGO_MONEDA,
                    ESTADO_FACTURA,
                    FECHA_EMISION,
                    SUBTOTAL,
                    TOTAL_DESCUENTOS,
                    TOTAL_IMPUESTOS,
                    TOTAL,
                    OBSERVACIONES,
                    FECHA_CREACION,
                    FECHA_MODIFICACION
                )
                OUTPUT INSERTED.ID_FACTURA
                INTO
                    #NUEVAS_FACTURAS (
                        ID_FACTURA
                    )
                SELECT
                    CONCAT(
                        CONVERT(CHAR(8), N.FECHA_EMISION, 112),
                        REPLACE(
                            CONVERT(CHAR(8), N.FECHA_EMISION, 108),
                            ':',
                            ''
                        ),
                        '-',
                        TRIM(T.CODIGO)
                    ) AS IDENTIFICADOR_COMPROBANTE,
                    E.CEDULA AS CEDULA_EMPRESA,
                    C.CEDULA AS CEDULA_CLIENTE,
                    T.CODIGO AS CODIGO_TIPO_DOCUMENTO,
                    M.CODIGO AS CODIGO_MONEDA,
                    EF.ESTADO AS ESTADO_FACTURA,
                    N.FECHA_EMISION,
                    0 AS SUBTOTAL,
                    0 AS TOTAL_DESCUENTOS,
                    0 AS TOTAL_IMPUESTOS,
                    0 AS TOTAL,
                    'Factura generada para datos' AS OBSERVACIONES,
                    @AHORA AS FECHA_CREACION,
                    @AHORA AS FECHA_MODIFICACION
                FROM NUMEROS AS N
                INNER JOIN #EMPRESAS AS E
                    ON E.NUMERO = (
                        (
                            N.NUMERO
                            + @ACTUAL
                            - 1
                        ) % @CANTIDAD_EMPRESAS
                    ) + 1
                INNER JOIN #CLIENTES AS C
                    ON C.NUMERO = (
                        (
                            N.NUMERO
                            + @ACTUAL
                            - 1
                        ) % @CANTIDAD_CLIENTES
                    ) + 1
                INNER JOIN #TIPOS AS T
                    ON T.NUMERO = (
                        (
                            N.NUMERO
                            + @ACTUAL
                            - 1
                        ) % @CANTIDAD_TIPOS
                    ) + 1
                INNER JOIN #MONEDAS AS M
                    ON M.NUMERO = (
                        (
                            N.NUMERO
                            + @ACTUAL
                            - 1
                        ) % @CANTIDAD_MONEDAS
                    ) + 1
                INNER JOIN #ESTADOS AS EF
                    ON EF.NUMERO = (
                        (
                            N.NUMERO
                            + @ACTUAL
                            - 1
                        ) % @CANTIDAD_ESTADOS
                    ) + 1;

                WITH DETALLES_BASE AS (
                    SELECT
                        NF.ID_FACTURA,
                        L.NUMERO_LINEA,
                        P.CODIGO,
                        P.TIPO,
                        P.DESCRIPCION,
                        P.PRECIO_UNITARIO,
                        P.PORCENTAJE_IMPUESTO,
                        CONVERT(
                            DECIMAL(18, 4),
                            1
                            + (
                                NF.ID_FACTURA
                                + L.NUMERO_LINEA
                            ) % 5
                        ) AS CANTIDAD,
                        CASE
                            WHEN L.NUMERO_LINEA % 3 = 0
                                THEN 10
                            WHEN L.NUMERO_LINEA % 2 = 0
                                THEN 5
                            ELSE 0
                        END AS PORCENTAJE_DESCUENTO
                    FROM #NUEVAS_FACTURAS AS NF
                    CROSS JOIN (
                        VALUES
                        (1),
                        (2),
                        (3),
                        (4),
                        (5)
                    ) AS L(NUMERO_LINEA)
                    INNER JOIN #ARTICULOS AS P
                        ON P.NUMERO = (
                            (
                                NF.ID_FACTURA
                                + L.NUMERO_LINEA
                                - 1
                            ) % @CANTIDAD_ARTICULOS
                        ) + 1
                    WHERE L.NUMERO_LINEA <= (
                        3 + NF.ID_FACTURA % 3
                    )
                ),

                DETALLES_CALCULADOS AS (
                    SELECT
                        D.ID_FACTURA,
                        D.NUMERO_LINEA,
                        D.CODIGO,
                        D.TIPO,
                        D.DESCRIPCION,
                        D.PRECIO_UNITARIO,
                        D.PORCENTAJE_IMPUESTO,
                        D.CANTIDAD,
                        D.PORCENTAJE_DESCUENTO,
                        ROUND(
                            D.CANTIDAD
                            * D.PRECIO_UNITARIO,
                            2
                        ) AS SUBTOTAL
                    FROM DETALLES_BASE AS D
                ),

                DESCUENTOS_CALCULADOS AS (
                    SELECT
                        D.ID_FACTURA,
                        D.NUMERO_LINEA,
                        D.CODIGO,
                        D.TIPO,
                        D.DESCRIPCION,
                        D.CANTIDAD,
                        D.PRECIO_UNITARIO,
                        D.PORCENTAJE_IMPUESTO,
                        D.SUBTOTAL,
                        ROUND(
                            D.SUBTOTAL
                            * D.PORCENTAJE_DESCUENTO
                            / 100.0,
                            2
                        ) AS MONTO_DESCUENTO
                    FROM DETALLES_CALCULADOS AS D
                ),

                IMPUESTOS_CALCULADOS AS (
                    SELECT
                        D.ID_FACTURA,
                        D.NUMERO_LINEA,
                        D.CODIGO,
                        D.TIPO,
                        D.DESCRIPCION,
                        D.CANTIDAD,
                        D.PRECIO_UNITARIO,
                        D.PORCENTAJE_IMPUESTO,
                        D.SUBTOTAL,
                        D.MONTO_DESCUENTO,
                        ROUND(
                            (D.SUBTOTAL - D.MONTO_DESCUENTO)
                            * D.PORCENTAJE_IMPUESTO
                            / 100.0,
                            2
                        ) AS MONTO_IMPUESTO
                    FROM DESCUENTOS_CALCULADOS AS D
                )

                INSERT INTO #DETALLES_LOTE (
                    ID_FACTURA,
                    NUMERO_LINEA,
                    CODIGO,
                    TIPO,
                    DESCRIPCION,
                    CANTIDAD,
                    PRECIO_UNITARIO,
                    PORCENTAJE_IMPUESTO,
                    SUBTOTAL,
                    MONTO_DESCUENTO,
                    MONTO_IMPUESTO,
                    TOTAL_LINEA
                )
                SELECT
                    D.ID_FACTURA,
                    D.NUMERO_LINEA,
                    D.CODIGO,
                    D.TIPO,
                    D.DESCRIPCION,
                    D.CANTIDAD,
                    D.PRECIO_UNITARIO,
                    D.PORCENTAJE_IMPUESTO,
                    D.SUBTOTAL,
                    D.MONTO_DESCUENTO,
                    D.MONTO_IMPUESTO,
                    (
                        D.SUBTOTAL - D.MONTO_DESCUENTO + D.MONTO_IMPUESTO
                    ) AS TOTAL_LINEA
                FROM IMPUESTOS_CALCULADOS AS D;

                INSERT INTO DBO.DETALLEFACTURA (
                    ID_FACTURA,
                    NUMERO_LINEA,
                    DESCRIPCION,
                    CANTIDAD,
                    PRECIO_UNITARIO,
                    PORCENTAJE_IMPUESTO,
                    SUBTOTAL,
                    MONTO_DESCUENTO,
                    MONTO_IMPUESTO,
                    TOTAL_LINEA
                )
                SELECT
                    D.ID_FACTURA,
                    D.NUMERO_LINEA,
                    D.DESCRIPCION,
                    D.CANTIDAD,
                    D.PRECIO_UNITARIO,
                    D.PORCENTAJE_IMPUESTO,
                    D.SUBTOTAL,
                    D.MONTO_DESCUENTO,
                    D.MONTO_IMPUESTO,
                    D.TOTAL_LINEA
                FROM #DETALLES_LOTE AS D;

                INSERT INTO DBO.DETALLEPRODUCTO (
                    ID_FACTURA,
                    NUMERO_LINEA,
                    CODIGO_PRODUCTO
                )
                SELECT
                    D.ID_FACTURA,
                    D.NUMERO_LINEA,
                    D.CODIGO
                FROM #DETALLES_LOTE AS D
                WHERE D.TIPO = 'P';

                INSERT INTO DBO.DETALLESERVICIO (
                    ID_FACTURA,
                    NUMERO_LINEA,
                    CODIGO_SERVICIO
                )
                SELECT
                    D.ID_FACTURA,
                    D.NUMERO_LINEA,
                    D.CODIGO
                FROM #DETALLES_LOTE AS D
                WHERE D.TIPO = 'S';

                WITH TOTALES AS (
                    SELECT
                        D.ID_FACTURA,
                        SUM(
                            D.SUBTOTAL
                        ) AS SUBTOTAL,
                        SUM(
                            D.MONTO_DESCUENTO
                        ) AS TOTAL_DESCUENTOS,
                        SUM(
                            D.MONTO_IMPUESTO
                        ) AS TOTAL_IMPUESTOS,
                        SUM(
                            D.TOTAL_LINEA
                        ) AS TOTAL
                    FROM #DETALLES_LOTE AS D
                    GROUP BY D.ID_FACTURA
                )

                UPDATE F
                SET
                    F.SUBTOTAL = TOT.SUBTOTAL,
                    F.TOTAL_DESCUENTOS = TOT.TOTAL_DESCUENTOS,
                    F.TOTAL_IMPUESTOS = TOT.TOTAL_IMPUESTOS,
                    F.TOTAL = TOT.TOTAL,
                    F.FECHA_MODIFICACION = @AHORA
                FROM DBO.FACTURA AS F
                INNER JOIN TOTALES AS TOT
                    ON F.ID_FACTURA = TOT.ID_FACTURA;

                COMMIT TRANSACTION;

                SET @ACTUAL = @ACTUAL + @LOTE;
            END;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH;
END;
GO

EXEC DBO.PR_GENERAR_FACTURAS
    @TOTAL_OBJETIVO = 500000;
GO

DROP PROCEDURE DBO.PR_GENERAR_FACTURAS;
GO
