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
                ORDER BY EMPRESA.CEDULA
            ) AS NUMERO,
            EMPRESA.CEDULA AS CEDULA
        FROM DBO.EMPRESA AS EMPRESA
        WHERE EMPRESA.ACTIVO = 1;

        INSERT INTO #CLIENTES (
            NUMERO,
            CEDULA
        )
        SELECT
            ROW_NUMBER() OVER (
                ORDER BY CLIENTE.CEDULA
            ) AS NUMERO,
            CLIENTE.CEDULA AS CEDULA
        FROM DBO.CLIENTE AS CLIENTE;

        INSERT INTO #TIPOS (
            NUMERO,
            CODIGO
        )
        SELECT
            ROW_NUMBER() OVER (
                ORDER BY TIPO.CODIGO
            ) AS NUMERO,
            TIPO.CODIGO AS CODIGO
        FROM DBO.TIPODOCUMENTO AS TIPO;

        INSERT INTO #MONEDAS (
            NUMERO,
            CODIGO
        )
        SELECT
            ROW_NUMBER() OVER (
                ORDER BY MONEDA.CODIGO
            ) AS NUMERO,
            MONEDA.CODIGO AS CODIGO
        FROM DBO.MONEDA AS MONEDA;

        INSERT INTO #ESTADOS (
            NUMERO,
            ESTADO
        )
        SELECT
            ROW_NUMBER() OVER (
                ORDER BY ESTADO.ESTADO
            ) AS NUMERO,
            ESTADO.ESTADO AS ESTADO
        FROM DBO.ESTADOFACTURA AS ESTADO;

        INSERT INTO #PRODUCTOS (
            NUMERO,
            CODIGO,
            DESCRIPCION,
            PRECIO_UNITARIO,
            PORCENTAJE_IMPUESTO
        )
        SELECT
            ROW_NUMBER() OVER (
                ORDER BY PRODUCTO.CODIGO
            ) AS NUMERO,
            PRODUCTO.CODIGO AS CODIGO,
            PRODUCTO.DESCRIPCION AS DESCRIPCION,
            PRODUCTO.PRECIO_UNITARIO AS PRECIO_UNITARIO,
            PRODUCTO.PORCENTAJE_IMPUESTO AS PORCENTAJE_IMPUESTO
        FROM DBO.PRODUCTO AS PRODUCTO
        WHERE PRODUCTO.ACTIVO = 1;

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
                    FROM SYS.ALL_OBJECTS AS OBJETO_A
                    CROSS JOIN SYS.ALL_OBJECTS AS OBJETO_B
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
                        'FAC-',
                        REPLACE(
                            CONVERT(
                                VARCHAR(36),
                                NEWID()
                            ),
                            '-',
                            ''
                        )
                    ) AS IDENTIFICADOR_COMPROBANTE,
                    EMPRESA.CEDULA AS CEDULA_EMPRESA,
                    CLIENTE.CEDULA AS CEDULA_CLIENTE,
                    TIPO.CODIGO AS CODIGO_TIPO_DOCUMENTO,
                    MONEDA.CODIGO AS CODIGO_MONEDA,
                    ESTADO.ESTADO AS ESTADO_FACTURA,
                    DATEADD(
                        DAY,
                        -CONVERT(
                            INT,
                            (
                                NUMERO.NUMERO
                                + @ACTUAL
                            ) % 365
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
                FROM NUMEROS AS NUMERO
                INNER JOIN #EMPRESAS AS EMPRESA
                    ON EMPRESA.NUMERO = (
                        (
                            NUMERO.NUMERO
                            + @ACTUAL
                            - 1
                        ) % @CANTIDAD_EMPRESAS
                    ) + 1
                INNER JOIN #CLIENTES AS CLIENTE
                    ON CLIENTE.NUMERO = (
                        (
                            NUMERO.NUMERO
                            + @ACTUAL
                            - 1
                        ) % @CANTIDAD_CLIENTES
                    ) + 1
                INNER JOIN #TIPOS AS TIPO
                    ON TIPO.NUMERO = (
                        (
                            NUMERO.NUMERO
                            + @ACTUAL
                            - 1
                        ) % @CANTIDAD_TIPOS
                    ) + 1
                INNER JOIN #MONEDAS AS MONEDA
                    ON MONEDA.NUMERO = (
                        (
                            NUMERO.NUMERO
                            + @ACTUAL
                            - 1
                        ) % @CANTIDAD_MONEDAS
                    ) + 1
                INNER JOIN #ESTADOS AS ESTADO
                    ON ESTADO.NUMERO = (
                        (
                            NUMERO.NUMERO
                            + @ACTUAL
                            - 1
                        ) % @CANTIDAD_ESTADOS
                    ) + 1;

                WITH DETALLES_BASE AS (
                    SELECT
                        NUEVA.ID_FACTURA AS ID_FACTURA,
                        LINEA.NUMERO_LINEA AS NUMERO_LINEA,
                        PRODUCTO.CODIGO AS CODIGO,
                        PRODUCTO.DESCRIPCION AS DESCRIPCION,
                        PRODUCTO.PRECIO_UNITARIO AS PRECIO_UNITARIO,
                        PRODUCTO.PORCENTAJE_IMPUESTO
                            AS PORCENTAJE_IMPUESTO,
                        CONVERT(
                            DECIMAL(18, 4),
                            1
                            + (
                                NUEVA.ID_FACTURA
                                + LINEA.NUMERO_LINEA
                            ) % 5
                        ) AS CANTIDAD,
                        CASE
                            WHEN LINEA.NUMERO_LINEA % 3 = 0
                                THEN 10
                            WHEN LINEA.NUMERO_LINEA % 2 = 0
                                THEN 5
                            ELSE 0
                        END AS PORCENTAJE_DESCUENTO
                    FROM #NUEVAS_FACTURAS AS NUEVA
                    CROSS JOIN (
                        VALUES
                        (1),
                        (2),
                        (3),
                        (4),
                        (5)
                    ) AS LINEA(NUMERO_LINEA)
                    INNER JOIN #PRODUCTOS AS PRODUCTO
                        ON PRODUCTO.NUMERO = (
                            (
                                NUEVA.ID_FACTURA
                                + LINEA.NUMERO_LINEA
                                - 1
                            ) % @CANTIDAD_PRODUCTOS
                        ) + 1
                    WHERE LINEA.NUMERO_LINEA <= (
                        3 + NUEVA.ID_FACTURA % 3
                    )
                ),
                DETALLES_CALCULADOS AS (
                    SELECT
                        DETALLE.ID_FACTURA AS ID_FACTURA,
                        DETALLE.NUMERO_LINEA AS NUMERO_LINEA,
                        DETALLE.CODIGO AS CODIGO,
                        DETALLE.DESCRIPCION AS DESCRIPCION,
                        DETALLE.PRECIO_UNITARIO AS PRECIO_UNITARIO,
                        DETALLE.PORCENTAJE_IMPUESTO
                            AS PORCENTAJE_IMPUESTO,
                        DETALLE.CANTIDAD AS CANTIDAD,
                        DETALLE.PORCENTAJE_DESCUENTO
                            AS PORCENTAJE_DESCUENTO,
                        ROUND(
                            DETALLE.CANTIDAD
                            * DETALLE.PRECIO_UNITARIO,
                            2
                        ) AS SUBTOTAL
                    FROM DETALLES_BASE AS DETALLE
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
                    DETALLE.ID_FACTURA AS ID_FACTURA,
                    DETALLE.NUMERO_LINEA AS NUMERO_LINEA,
                    DETALLE.CODIGO AS CODIGO_PRODUCTO,
                    DETALLE.DESCRIPCION AS DESCRIPCION,
                    DETALLE.CANTIDAD AS CANTIDAD,
                    DETALLE.PRECIO_UNITARIO AS PRECIO_UNITARIO,
                    DETALLE.PORCENTAJE_IMPUESTO
                        AS PORCENTAJE_IMPUESTO,
                    DETALLE.SUBTOTAL AS SUBTOTAL,
                    ROUND(
                        DETALLE.SUBTOTAL
                        * DETALLE.PORCENTAJE_DESCUENTO
                        / 100.0,
                        2
                    ) AS MONTO_DESCUENTO,
                    ROUND(
                        (
                            DETALLE.SUBTOTAL
                            - ROUND(
                                DETALLE.SUBTOTAL
                                * DETALLE.PORCENTAJE_DESCUENTO
                                / 100.0,
                                2
                            )
                        )
                        * DETALLE.PORCENTAJE_IMPUESTO
                        / 100.0,
                        2
                    ) AS MONTO_IMPUESTO,
                    ROUND(
                        DETALLE.SUBTOTAL
                        - ROUND(
                            DETALLE.SUBTOTAL
                            * DETALLE.PORCENTAJE_DESCUENTO
                            / 100.0,
                            2
                        )
                        + (
                            (
                                DETALLE.SUBTOTAL
                                - ROUND(
                                    DETALLE.SUBTOTAL
                                    * DETALLE.PORCENTAJE_DESCUENTO
                                    / 100.0,
                                    2
                                )
                            )
                            * DETALLE.PORCENTAJE_IMPUESTO
                            / 100.0
                        ),
                        2
                    ) AS TOTAL_LINEA
                FROM DETALLES_CALCULADOS AS DETALLE;

                WITH TOTALES AS (
                    SELECT
                        DETALLE.ID_FACTURA AS ID_FACTURA,
                        SUM(
                            DETALLE.SUBTOTAL
                        ) AS SUBTOTAL,
                        SUM(
                            DETALLE.MONTO_DESCUENTO
                        ) AS TOTAL_DESCUENTOS,
                        SUM(
                            DETALLE.MONTO_IMPUESTO
                        ) AS TOTAL_IMPUESTOS,
                        SUM(
                            DETALLE.TOTAL_LINEA
                        ) AS TOTAL
                    FROM DBO.DETALLEFACTURA AS DETALLE
                    INNER JOIN #NUEVAS_FACTURAS AS NUEVA
                        ON NUEVA.ID_FACTURA = DETALLE.ID_FACTURA
                    GROUP BY DETALLE.ID_FACTURA
                )

                UPDATE FACTURA
                SET
                    FACTURA.SUBTOTAL = TOTALES.SUBTOTAL,
                    FACTURA.TOTAL_DESCUENTOS
                        = TOTALES.TOTAL_DESCUENTOS,
                    FACTURA.TOTAL_IMPUESTOS
                        = TOTALES.TOTAL_IMPUESTOS,
                    FACTURA.TOTAL = TOTALES.TOTAL,
                    FACTURA.FECHA_MODIFICACION = @AHORA
                FROM DBO.FACTURA AS FACTURA
                INNER JOIN TOTALES AS TOTALES
                    ON TOTALES.ID_FACTURA = FACTURA.ID_FACTURA;

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
