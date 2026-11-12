USE FACTURACIONSOLUCIONESMAGNIFICAS;
GO

IF
    EXISTS (
        SELECT 1
        FROM SYS.OBJECTS
        WHERE
            NAME = 'PR_AGREGAR_DETALLE_FACTURA'
            AND TYPE = 'P'
    )
    BEGIN
        DROP PROCEDURE DBO.PR_AGREGAR_DETALLE_FACTURA;
    END
GO

CREATE PROCEDURE DBO.PR_AGREGAR_DETALLE_FACTURA
    @ID_FACTURA BIGINT,
    @NUMERO_LINEA INT,
    @CODIGO_PRODUCTO VARCHAR(30),
    @CANTIDAD DECIMAL(18, 4),
    @PORCENTAJE_DESCUENTO DECIMAL(5, 2) = 0,
    @CODIGO_SERVICIO VARCHAR(30) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        SET @CODIGO_PRODUCTO = NULLIF(TRIM(@CODIGO_PRODUCTO), '');
        SET @CODIGO_SERVICIO = NULLIF(TRIM(@CODIGO_SERVICIO), '');

        IF
            NOT EXISTS (
                SELECT 1
                FROM DBO.FACTURA
                WHERE ID_FACTURA = @ID_FACTURA
            )
            THROW 52101, 'La factura no existe.', 1;

        IF @NUMERO_LINEA IS NULL OR @NUMERO_LINEA <= 0
            THROW 52102, 'El numero de linea debe ser mayor que cero.', 1;

        IF
            EXISTS (
                SELECT 1
                FROM DBO.DETALLEFACTURA
                WHERE
                    ID_FACTURA = @ID_FACTURA
                    AND NUMERO_LINEA = @NUMERO_LINEA
            )
            THROW 52103, 'El numero de linea ya existe.', 1;

        IF (
            SELECT COUNT(*)
            FROM DBO.DETALLEFACTURA
            WHERE ID_FACTURA = @ID_FACTURA
        ) >= 5
            THROW 52104, 'La factura ya tiene cinco detalles.', 1;

        IF (
            (@CODIGO_PRODUCTO IS NULL AND @CODIGO_SERVICIO IS NULL)
            OR (
                @CODIGO_PRODUCTO IS NOT NULL
                AND @CODIGO_SERVICIO IS NOT NULL
            )
        )
            THROW 52105, 'Indique un producto o un servicio.', 1;

        IF @CODIGO_PRODUCTO IS NOT NULL
            BEGIN
                IF
                    NOT EXISTS (
                        SELECT 1
                        FROM DBO.PRODUCTO
                        WHERE
                            CODIGO = @CODIGO_PRODUCTO
                            AND ACTIVO = 1
                    )
                    THROW 52106, 'El producto no existe o esta inactivo.', 1;
            END;

        IF @CODIGO_SERVICIO IS NOT NULL
            BEGIN
                IF
                    NOT EXISTS (
                        SELECT 1
                        FROM DBO.SERVICIO
                        WHERE
                            CODIGO = @CODIGO_SERVICIO
                            AND ACTIVO = 1
                    )
                    THROW 52111, 'El servicio no existe o esta inactivo.', 1;
            END;

        IF @CANTIDAD IS NULL OR @CANTIDAD <= 0
            THROW 52107, 'La cantidad debe ser mayor que cero.', 1;

        IF (
            @PORCENTAJE_DESCUENTO IS NULL
            OR @PORCENTAJE_DESCUENTO NOT BETWEEN 0 AND 100
        )
            THROW 52108, 'El descuento debe estar entre 0 y 100.', 1;

        DECLARE @DESCRIPCION VARCHAR(200);
        DECLARE @PRECIO_UNITARIO DECIMAL(18, 2);
        DECLARE @PORCENTAJE_IMPUESTO DECIMAL(5, 2);
        DECLARE @SUBTOTAL DECIMAL(18, 2);
        DECLARE @MONTO_DESCUENTO DECIMAL(18, 2);
        DECLARE @MONTO_IMPUESTO DECIMAL(18, 2);
        DECLARE @TOTAL_LINEA DECIMAL(18, 2);
        DECLARE @SUBTOTAL_FACTURA DECIMAL(18, 2);
        DECLARE @DESCUENTOS_FACTURA DECIMAL(18, 2);
        DECLARE @IMPUESTOS_FACTURA DECIMAL(18, 2);
        DECLARE @TOTAL_FACTURA DECIMAL(18, 2);

        IF @CODIGO_PRODUCTO IS NOT NULL
            BEGIN
                SELECT
                    @DESCRIPCION = PRODUCTO.DESCRIPCION,
                    @PRECIO_UNITARIO = PRODUCTO.PRECIO_UNITARIO,
                    @PORCENTAJE_IMPUESTO = PRODUCTO.PORCENTAJE_IMPUESTO
                FROM DBO.PRODUCTO AS PRODUCTO
                WHERE PRODUCTO.CODIGO = @CODIGO_PRODUCTO;
            END;

        IF @CODIGO_SERVICIO IS NOT NULL
            BEGIN
                SELECT
                    @DESCRIPCION = SERVICIO.DESCRIPCION,
                    @PRECIO_UNITARIO = SERVICIO.PRECIO_UNITARIO,
                    @PORCENTAJE_IMPUESTO = SERVICIO.PORCENTAJE_IMPUESTO
                FROM DBO.SERVICIO AS SERVICIO
                WHERE SERVICIO.CODIGO = @CODIGO_SERVICIO;
            END;

        IF @PRECIO_UNITARIO <= 0
            THROW 52109, 'El precio debe ser mayor que cero.', 1;

        IF @PORCENTAJE_IMPUESTO NOT BETWEEN 0 AND 100
            THROW 52110, 'El impuesto del producto no es valido.', 1;

        SET @SUBTOTAL = ROUND(
            @CANTIDAD * @PRECIO_UNITARIO,
            2
        );

        SET @MONTO_DESCUENTO = ROUND(
            @SUBTOTAL * @PORCENTAJE_DESCUENTO / 100.0,
            2
        );

        SET @MONTO_IMPUESTO = ROUND(
            (
                @SUBTOTAL - @MONTO_DESCUENTO
            ) * @PORCENTAJE_IMPUESTO / 100.0,
            2
        );

        SET @TOTAL_LINEA = (
            @SUBTOTAL
            - @MONTO_DESCUENTO
            + @MONTO_IMPUESTO
        );

        BEGIN TRANSACTION;

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
        VALUES (
            @ID_FACTURA,
            @NUMERO_LINEA,
            @DESCRIPCION,
            @CANTIDAD,
            @PRECIO_UNITARIO,
            @PORCENTAJE_IMPUESTO,
            @SUBTOTAL,
            @MONTO_DESCUENTO,
            @MONTO_IMPUESTO,
            @TOTAL_LINEA
        );

        IF @CODIGO_PRODUCTO IS NOT NULL
            BEGIN
                INSERT INTO DBO.DETALLEPRODUCTO (
                    ID_FACTURA,
                    NUMERO_LINEA,
                    CODIGO_PRODUCTO
                )
                VALUES (
                    @ID_FACTURA,
                    @NUMERO_LINEA,
                    @CODIGO_PRODUCTO
                );
            END;

        IF @CODIGO_SERVICIO IS NOT NULL
            BEGIN
                INSERT INTO DBO.DETALLESERVICIO (
                    ID_FACTURA,
                    NUMERO_LINEA,
                    CODIGO_SERVICIO
                )
                VALUES (
                    @ID_FACTURA,
                    @NUMERO_LINEA,
                    @CODIGO_SERVICIO
                );
            END;

        SELECT
            @SUBTOTAL_FACTURA = SUM(DETALLE.SUBTOTAL),
            @DESCUENTOS_FACTURA = SUM(DETALLE.MONTO_DESCUENTO),
            @IMPUESTOS_FACTURA = SUM(DETALLE.MONTO_IMPUESTO),
            @TOTAL_FACTURA = SUM(DETALLE.TOTAL_LINEA)
        FROM DBO.DETALLEFACTURA AS DETALLE
        WHERE DETALLE.ID_FACTURA = @ID_FACTURA;

        UPDATE DBO.FACTURA
        SET
            SUBTOTAL = @SUBTOTAL_FACTURA,
            TOTAL_DESCUENTOS = @DESCUENTOS_FACTURA,
            TOTAL_IMPUESTOS = @IMPUESTOS_FACTURA,
            TOTAL = @TOTAL_FACTURA,
            FECHA_MODIFICACION = CONVERT(
                DATETIME2(0),
                SYSDATETIME()
            )
        WHERE ID_FACTURA = @ID_FACTURA;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH;
END;
GO
