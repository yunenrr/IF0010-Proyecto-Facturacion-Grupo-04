USE FACTURACIONSOLUCIONESMAGNIFICAS;
GO

IF
    EXISTS (
        SELECT 1
        FROM SYS.OBJECTS
        WHERE
            NAME = 'FN_GENERAR_CLAVE_COMPROBANTE'
            AND TYPE = 'FN'
    )
    BEGIN
        DROP FUNCTION DBO.FN_GENERAR_CLAVE_COMPROBANTE;
    END
GO

CREATE FUNCTION DBO.FN_GENERAR_CLAVE_COMPROBANTE (
    @FECHA DATETIME2(0),
    @TIPO_DOCUMENTO VARCHAR(10)
)
RETURNS VARCHAR(40)
AS
BEGIN
    IF
        @FECHA IS NULL
        OR NULLIF(TRIM(@TIPO_DOCUMENTO), '') IS NULL
        RETURN NULL;

    RETURN CONCAT(
        CONVERT(
            CHAR(8),
            @FECHA,
            112
        ),
        REPLACE(
            CONVERT(
                CHAR(8),
                @FECHA,
                108
            ),
            ':',
            ''
        ),
        '-',
        TRIM(@TIPO_DOCUMENTO)
    );
END;
GO
