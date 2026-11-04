USE FACTURACIONSOLUCIONESMAGNIFICAS;
GO

IF EXISTS (
    SELECT 1
    FROM SYS.TRIGGERS
    WHERE NAME = 'TR_AUD_DIRECCION'
)
    BEGIN
        DROP TRIGGER DBO.TR_AUD_DIRECCION;
    END
GO

CREATE TRIGGER DBO.TR_AUD_DIRECCION
ON DBO.DIRECCION
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
        'DIRECCION',
        CONVERT(VARCHAR(100), COALESCE(I.ID_DIRECCION, D.ID_DIRECCION)),
        CASE
            WHEN D.ID_DIRECCION IS NULL THEN 'INSERT'
            WHEN I.ID_DIRECCION IS NULL THEN 'DELETE'
            ELSE 'UPDATE'
        END,
        CASE
            WHEN D.ID_DIRECCION IS NULL THEN 'NO APLICA'
            ELSE CONCAT(
                'ID_DIRECCION=',
                D.ID_DIRECCION,
                '; CODIGO_PROVINCIA=',
                D.CODIGO_PROVINCIA,
                '; CODIGO_CANTON=',
                D.CODIGO_CANTON,
                '; CODIGO_DISTRITO=',
                D.CODIGO_DISTRITO,
                '; CODIGO_BARRIO=',
                D.CODIGO_BARRIO,
                '; SENAS_EXACTAS=',
                D.SENAS_EXACTAS
            )
        END,
        CASE
            WHEN I.ID_DIRECCION IS NULL THEN 'NO APLICA'
            ELSE CONCAT(
                'ID_DIRECCION=',
                I.ID_DIRECCION,
                '; CODIGO_PROVINCIA=',
                I.CODIGO_PROVINCIA,
                '; CODIGO_CANTON=',
                I.CODIGO_CANTON,
                '; CODIGO_DISTRITO=',
                I.CODIGO_DISTRITO,
                '; CODIGO_BARRIO=',
                I.CODIGO_BARRIO,
                '; SENAS_EXACTAS=',
                I.SENAS_EXACTAS
            )
        END,
        ORIGINAL_LOGIN(),
        CONVERT(DATETIME2(0), SYSDATETIME()),
        'Historial de DIRECCION'
    FROM INSERTED AS I
    FULL OUTER JOIN DELETED AS D
        ON I.ID_DIRECCION = D.ID_DIRECCION;
END;
GO
