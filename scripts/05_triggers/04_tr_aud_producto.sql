USE FACTURACIONSOLUCIONESMAGNIFICAS;
GO

IF
    EXISTS (
        SELECT 1
        FROM SYS.TRIGGERS
        WHERE NAME = 'TR_AUD_PRODUCTO'
    )
    BEGIN
        DROP TRIGGER DBO.TR_AUD_PRODUCTO;
    END
GO

CREATE TRIGGER DBO.TR_AUD_PRODUCTO
ON DBO.PRODUCTO
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
        'PRODUCTO' AS TABLA_AFECTADA,
        CONVERT(
            VARCHAR(100),
            COALESCE(I.CODIGO, D.CODIGO)
        ) AS ID_REGISTRO,
        CASE
            WHEN D.CODIGO IS NULL THEN 'INSERT'
            WHEN I.CODIGO IS NULL THEN 'DELETE'
            ELSE 'UPDATE'
        END AS OPERACION,
        CASE
            WHEN D.CODIGO IS NULL THEN 'NO APLICA'
            ELSE CONCAT(
                'CODIGO=',
                D.CODIGO,
                '; DESCRIPCION=',
                D.DESCRIPCION,
                '; ID_TIPO_PRODUCTO=',
                D.ID_TIPO_PRODUCTO,
                '; CANTIDAD_DISPONIBLE=',
                D.CANTIDAD_DISPONIBLE,
                '; PRECIO_UNITARIO=',
                D.PRECIO_UNITARIO,
                '; PORCENTAJE_IMPUESTO=',
                D.PORCENTAJE_IMPUESTO,
                '; FECHA_CREACION=',
                CONVERT(VARCHAR(19), D.FECHA_CREACION, 126),
                '; FECHA_MODIFICACION=',
                CONVERT(VARCHAR(19), D.FECHA_MODIFICACION, 126),
                '; ACTIVO=',
                D.ACTIVO
            )
        END AS VALOR_ANTERIOR,
        CASE
            WHEN I.CODIGO IS NULL THEN 'NO APLICA'
            ELSE CONCAT(
                'CODIGO=',
                I.CODIGO,
                '; DESCRIPCION=',
                I.DESCRIPCION,
                '; ID_TIPO_PRODUCTO=',
                I.ID_TIPO_PRODUCTO,
                '; CANTIDAD_DISPONIBLE=',
                I.CANTIDAD_DISPONIBLE,
                '; PRECIO_UNITARIO=',
                I.PRECIO_UNITARIO,
                '; PORCENTAJE_IMPUESTO=',
                I.PORCENTAJE_IMPUESTO,
                '; FECHA_CREACION=',
                CONVERT(VARCHAR(19), I.FECHA_CREACION, 126),
                '; FECHA_MODIFICACION=',
                CONVERT(VARCHAR(19), I.FECHA_MODIFICACION, 126),
                '; ACTIVO=',
                I.ACTIVO
            )
        END AS VALOR_NUEVO,
        ORIGINAL_LOGIN() AS USUARIO,
        CONVERT(DATETIME2(0), SYSDATETIME()) AS FECHA_HORA,
        'Historial de PRODUCTO' AS DESCRIPCION
    FROM INSERTED AS I
    FULL OUTER JOIN DELETED AS D
        ON I.CODIGO = D.CODIGO;
END;
GO
