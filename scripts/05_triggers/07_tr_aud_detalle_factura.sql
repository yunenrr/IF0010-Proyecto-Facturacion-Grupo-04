USE FACTURACIONSOLUCIONESMAGNIFICAS;
GO

IF
    EXISTS (
        SELECT 1
        FROM SYS.TRIGGERS
        WHERE NAME = 'TR_AUD_DETALLEFACTURA'
    )
    BEGIN
        DROP TRIGGER DBO.TR_AUD_DETALLEFACTURA;
    END
GO

CREATE TRIGGER DBO.TR_AUD_DETALLEFACTURA
ON DBO.DETALLEFACTURA
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    IF
        NOT EXISTS (
            SELECT 1
            FROM DELETED
        )
        BEGIN
            INSERT INTO DBO.AUDITORIA (
            TABLA_AFECTADA,
            ID_REGISTRO,
            OPERACION,
            VALOR_ANTERIOR,
            VALOR_NUEVO,
            USUARIO,
            FECHA_HORA,
            DESCRIPCION
            )
            SELECT
                'DETALLEFACTURA' AS TABLA_AFECTADA,
                CONCAT(
                    I.ID_FACTURA,
                    '-',
                    I.NUMERO_LINEA
                ) AS ID_REGISTRO,
                'INSERT' AS OPERACION,
                'NO APLICA' AS VALOR_ANTERIOR,
                CONCAT(
                    'ID_FACTURA=',
                    I.ID_FACTURA,
                    '; NUMERO_LINEA=',
                    I.NUMERO_LINEA,
                    '; DESCRIPCION=',
                    I.DESCRIPCION,
                    '; CANTIDAD=',
                    I.CANTIDAD,
                    '; PRECIO_UNITARIO=',
                    I.PRECIO_UNITARIO,
                    '; PORCENTAJE_IMPUESTO=',
                    I.PORCENTAJE_IMPUESTO,
                    '; SUBTOTAL=',
                    I.SUBTOTAL,
                    '; MONTO_DESCUENTO=',
                    I.MONTO_DESCUENTO,
                    '; MONTO_IMPUESTO=',
                    I.MONTO_IMPUESTO,
                    '; TOTAL_LINEA=',
                    I.TOTAL_LINEA
                ) AS VALOR_NUEVO,
                ORIGINAL_LOGIN() AS USUARIO,
                CONVERT(DATETIME2(0), SYSDATETIME()) AS FECHA_HORA,
                'Historial de DETALLEFACTURA' AS DESCRIPCION
            FROM INSERTED AS I;

            RETURN;
        END;

    INSERT INTO DBO.AUDITORIA (
        TABLA_AFECTADA,
        ID_REGISTRO,
        OPERACION,
        VALOR_ANTERIOR,
        VALOR_NUEVO,
        USUARIO,
        FECHA_HORA,
        DESCRIPCION
    )
    SELECT
        'DETALLEFACTURA' AS TABLA_AFECTADA,
        CONCAT(
            COALESCE(I.ID_FACTURA, D.ID_FACTURA),
            '-',
            COALESCE(I.NUMERO_LINEA, D.NUMERO_LINEA)
        ) AS ID_REGISTRO,
        CASE
            WHEN D.ID_FACTURA IS NULL THEN 'INSERT'
            WHEN I.ID_FACTURA IS NULL THEN 'DELETE'
            ELSE 'UPDATE'
        END AS OPERACION,
        CASE
            WHEN D.ID_FACTURA IS NULL THEN 'NO APLICA'
            ELSE CONCAT(
                'ID_FACTURA=',
                D.ID_FACTURA,
                '; NUMERO_LINEA=',
                D.NUMERO_LINEA,
                '; DESCRIPCION=',
                D.DESCRIPCION,
                '; CANTIDAD=',
                D.CANTIDAD,
                '; PRECIO_UNITARIO=',
                D.PRECIO_UNITARIO,
                '; PORCENTAJE_IMPUESTO=',
                D.PORCENTAJE_IMPUESTO,
                '; SUBTOTAL=',
                D.SUBTOTAL,
                '; MONTO_DESCUENTO=',
                D.MONTO_DESCUENTO,
                '; MONTO_IMPUESTO=',
                D.MONTO_IMPUESTO,
                '; TOTAL_LINEA=',
                D.TOTAL_LINEA
            )
        END AS VALOR_ANTERIOR,
        CASE
            WHEN I.ID_FACTURA IS NULL THEN 'NO APLICA'
            ELSE CONCAT(
                'ID_FACTURA=',
                I.ID_FACTURA,
                '; NUMERO_LINEA=',
                I.NUMERO_LINEA,
                '; DESCRIPCION=',
                I.DESCRIPCION,
                '; CANTIDAD=',
                I.CANTIDAD,
                '; PRECIO_UNITARIO=',
                I.PRECIO_UNITARIO,
                '; PORCENTAJE_IMPUESTO=',
                I.PORCENTAJE_IMPUESTO,
                '; SUBTOTAL=',
                I.SUBTOTAL,
                '; MONTO_DESCUENTO=',
                I.MONTO_DESCUENTO,
                '; MONTO_IMPUESTO=',
                I.MONTO_IMPUESTO,
                '; TOTAL_LINEA=',
                I.TOTAL_LINEA
            )
        END AS VALOR_NUEVO,
        ORIGINAL_LOGIN() AS USUARIO,
        CONVERT(DATETIME2(0), SYSDATETIME()) AS FECHA_HORA,
        'Historial de DETALLEFACTURA' AS DESCRIPCION
    FROM INSERTED AS I
    FULL OUTER JOIN DELETED AS D
        ON
            I.ID_FACTURA = D.ID_FACTURA
            AND I.NUMERO_LINEA = D.NUMERO_LINEA;
END;
GO
