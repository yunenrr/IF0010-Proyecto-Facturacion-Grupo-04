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
            SELECT COUNT(*)
            FROM DBO.PRODUCTO
            WHERE ACTIVO = 1
        ) < 5
            THROW 52407, 'Se necesitan al menos cinco productos activos.', 1;

        DECLARE @ACTUAL BIGINT;
        DECLARE @FALTANTES INT;
        DECLARE @LOTE INT;
        DECLARE @TAMANO_LOTE INT = 10000;
        DECLARE @AHORA DATETIME2(0);
        DECLARE @CANTIDAD_EMPRESAS INT;
        DECLARE @CANTIDAD_CLIENTES INT;
        DECLARE @CANTIDAD_TIPOS INT;
        DECLARE @CANTIDAD_MONEDAS INT;
        DECLARE @CANTIDAD_ESTADOS INT;
        DECLARE @CANTIDAD_PRODUCTOS INT;

        SET @AHORA = CONVERT(
            DATETIME2(0),
            SYSDATETIME()
        );

        SELECT @ACTUAL = COUNT_BIG(*)
        FROM DBO.FACTURA;

        IF @ACTUAL >= @TOTAL_OBJETIVO
            RETURN;

        CREATE TABLE #EMPRESAS (
            NUMERO INT NOT NULL,
            CEDULA VARCHAR(20) NOT NULL
        );

        CREATE TABLE #CLIENTES (
            NUMERO INT NOT NULL,
            CEDULA VARCHAR(20) NOT NULL
        );

        CREATE TABLE #TIPOS (
            NUMERO INT NOT NULL,
            CODIGO VARCHAR(10) NOT NULL
        );

        CREATE TABLE #MONEDAS (
            NUMERO INT NOT NULL,
            CODIGO CHAR(3) NOT NULL
        );

        CREATE TABLE #ESTADOS (
            NUMERO INT NOT NULL,
            ESTADO VARCHAR(20) NOT NULL
        );

        CREATE TABLE #PRODUCTOS (
            NUMERO INT NOT NULL,
            CODIGO VARCHAR(30) NOT NULL,
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

        INSERT INTO #PRODUCTOS (
            NUMERO,
            CODIGO,
            DESCRIPCION,
            PRECIO_UNITARIO,
            PORCENTAJE_IMPUESTO
        )
        SELECT
            ROW_NUMBER() OVER (
                ORDER BY P.CODIGO
            ) AS NUMERO,
            P.CODIGO,
            P.DESCRIPCION,
            P.PRECIO_UNITARIO,
            P.PORCENTAJE_IMPUESTO
        FROM DBO.PRODUCTO AS P
        WHERE P.ACTIVO = 1;

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

        SELECT @CANTIDAD_PRODUCTOS = COUNT(*)
        FROM #PRODUCTOS;

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

                CREATE TABLE #NUEVAS_FACTURAS (
                    ID_FACTURA BIGINT NOT NULL
                );

                BEGIN TRANSACTION;

                WITH NUMEROS AS (
                    SELECT TOP (@LOTE)
                        ROW_NUMBER() OVER (
                            ORDER BY (
                                SELECT NULL
                            )
                        ) AS NUMERO
                    FROM SYS.ALL_OBJECTS AS A
                    CROSS JOIN SYS.ALL_OBJECTS AS B
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
                    DBO.FN_GENERAR_CLAVE_COMPROBANTE(
                        DATEADD(
                            SECOND,
                            -CONVERT(
                                INT,
                                (
                                    N.NUMERO
                                    + @ACTUAL
                                ) * 60
                            ),
                            @AHORA
                        ),
                        T.CODIGO
                    ) AS IDENTIFICADOR_COMPROBANTE,
                    E.CEDULA AS CEDULA_EMPRESA,
                    C.CEDULA AS CEDULA_CLIENTE,
                    T.CODIGO AS CODIGO_TIPO_DOCUMENTO,
                    M.CODIGO AS CODIGO_MONEDA,
                    EF.ESTADO AS ESTADO_FACTURA,
                    DATEADD(
                        SECOND,
                        -CONVERT(
                            INT,
                            (
                                N.NUMERO
                                + @ACTUAL
                            ) * 60
                        ),
                        @AHORA
                    ) AS FECHA_EMISION,
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
                    INNER JOIN #PRODUCTOS AS P
                        ON P.NUMERO = (
                            (
                                NF.ID_FACTURA
                                + L.NUMERO_LINEA
                                - 1
                            ) % @CANTIDAD_PRODUCTOS
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
                )

                INSERT INTO DBO.DETALLEFACTURA (
                    ID_FACTURA,
                    NUMERO_LINEA,
                    CODIGO_PRODUCTO,
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
                    D.CODIGO AS CODIGO_PRODUCTO,
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
                    ) AS MONTO_DESCUENTO,
                    ROUND(
                        (
                            D.SUBTOTAL
                            - ROUND(
                                D.SUBTOTAL
                                * D.PORCENTAJE_DESCUENTO
                                / 100.0,
                                2
                            )
                        )
                        * D.PORCENTAJE_IMPUESTO
                        / 100.0,
                        2
                    ) AS MONTO_IMPUESTO,
                    ROUND(
                        D.SUBTOTAL
                        - ROUND(
                            D.SUBTOTAL
                            * D.PORCENTAJE_DESCUENTO
                            / 100.0,
                            2
                        )
                        + (
                            (
                                D.SUBTOTAL
                                - ROUND(
                                    D.SUBTOTAL
                                    * D.PORCENTAJE_DESCUENTO
                                    / 100.0,
                                    2
                                )
                            )
                            * D.PORCENTAJE_IMPUESTO
                            / 100.0
                        ),
                        2
                    ) AS TOTAL_LINEA
                FROM DETALLES_CALCULADOS AS D;

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
                    FROM DBO.DETALLEFACTURA AS D
                    INNER JOIN #NUEVAS_FACTURAS AS NF
                        ON D.ID_FACTURA = NF.ID_FACTURA
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

                DROP TABLE #NUEVAS_FACTURAS;
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
