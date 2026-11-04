USE FACTURACIONSOLUCIONESMAGNIFICAS;
GO

IF
    EXISTS (
        SELECT 1
        FROM SYS.TRIGGERS
        WHERE NAME = 'TR_AUD_FACTURA'
    )
    BEGIN
        DROP TRIGGER DBO.TR_AUD_FACTURA;
    END
GO

CREATE TRIGGER DBO.TR_AUD_FACTURA
ON DBO.FACTURA
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

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
        'FACTURA' AS TABLA_AFECTADA,
        CONVERT(
            VARCHAR(100),
            COALESCE(I.ID_FACTURA, D.ID_FACTURA)
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
                '; IDENTIFICADOR_COMPROBANTE=',
                D.IDENTIFICADOR_COMPROBANTE,
                '; CEDULA_EMPRESA=',
                D.CEDULA_EMPRESA,
                '; CEDULA_CLIENTE=',
                D.CEDULA_CLIENTE,
                '; CODIGO_TIPO_DOCUMENTO=',
                D.CODIGO_TIPO_DOCUMENTO,
                '; CODIGO_MONEDA=',
                D.CODIGO_MONEDA,
                '; ESTADO_FACTURA=',
                D.ESTADO_FACTURA,
                '; FECHA_EMISION=',
                CONVERT(VARCHAR(19), D.FECHA_EMISION, 126),
                '; SUBTOTAL=',
                D.SUBTOTAL,
                '; TOTAL_DESCUENTOS=',
                D.TOTAL_DESCUENTOS,
                '; TOTAL_IMPUESTOS=',
                D.TOTAL_IMPUESTOS,
                '; TOTAL=',
                D.TOTAL,
                '; OBSERVACIONES=',
                D.OBSERVACIONES,
                '; FECHA_CREACION=',
                CONVERT(VARCHAR(19), D.FECHA_CREACION, 126),
                '; FECHA_MODIFICACION=',
                CONVERT(VARCHAR(19), D.FECHA_MODIFICACION, 126)
            )
        END AS VALOR_ANTERIOR,
        CASE
            WHEN I.ID_FACTURA IS NULL THEN 'NO APLICA'
            ELSE CONCAT(
                'ID_FACTURA=',
                I.ID_FACTURA,
                '; IDENTIFICADOR_COMPROBANTE=',
                I.IDENTIFICADOR_COMPROBANTE,
                '; CEDULA_EMPRESA=',
                I.CEDULA_EMPRESA,
                '; CEDULA_CLIENTE=',
                I.CEDULA_CLIENTE,
                '; CODIGO_TIPO_DOCUMENTO=',
                I.CODIGO_TIPO_DOCUMENTO,
                '; CODIGO_MONEDA=',
                I.CODIGO_MONEDA,
                '; ESTADO_FACTURA=',
                I.ESTADO_FACTURA,
                '; FECHA_EMISION=',
                CONVERT(VARCHAR(19), I.FECHA_EMISION, 126),
                '; SUBTOTAL=',
                I.SUBTOTAL,
                '; TOTAL_DESCUENTOS=',
                I.TOTAL_DESCUENTOS,
                '; TOTAL_IMPUESTOS=',
                I.TOTAL_IMPUESTOS,
                '; TOTAL=',
                I.TOTAL,
                '; OBSERVACIONES=',
                I.OBSERVACIONES,
                '; FECHA_CREACION=',
                CONVERT(VARCHAR(19), I.FECHA_CREACION, 126),
                '; FECHA_MODIFICACION=',
                CONVERT(VARCHAR(19), I.FECHA_MODIFICACION, 126)
            )
        END AS VALOR_NUEVO,
        ORIGINAL_LOGIN() AS USUARIO,
        CONVERT(DATETIME2(0), SYSDATETIME()) AS FECHA_HORA,
        'Historial de FACTURA' AS DESCRIPCION
    FROM INSERTED AS I
    FULL OUTER JOIN DELETED AS D
        ON I.ID_FACTURA = D.ID_FACTURA;
END;
GO
