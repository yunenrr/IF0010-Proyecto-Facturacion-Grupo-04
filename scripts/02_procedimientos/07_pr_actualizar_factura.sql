USE FACTURACIONSOLUCIONESMAGNIFICAS;
GO

IF
    EXISTS (
        SELECT 1
        FROM SYS.OBJECTS
        WHERE
            NAME = 'PR_ACTUALIZAR_FACTURA'
            AND TYPE = 'P'
    )
    BEGIN
        DROP PROCEDURE DBO.PR_ACTUALIZAR_FACTURA;
    END
GO

CREATE PROCEDURE DBO.PR_ACTUALIZAR_FACTURA
    @ID_FACTURA BIGINT,
    @CEDULA_EMPRESA VARCHAR(20),
    @CEDULA_CLIENTE VARCHAR(20),
    @CODIGO_TIPO_DOCUMENTO VARCHAR(10),
    @CODIGO_MONEDA CHAR(3),
    @FECHA_EMISION DATETIME2(0),
    @OBSERVACIONES VARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        SET @CEDULA_EMPRESA = TRIM(@CEDULA_EMPRESA);
        SET @CEDULA_CLIENTE = TRIM(@CEDULA_CLIENTE);
        SET @CODIGO_TIPO_DOCUMENTO = TRIM(@CODIGO_TIPO_DOCUMENTO);
        SET @CODIGO_MONEDA = TRIM(@CODIGO_MONEDA);

        IF
            NOT EXISTS (
                SELECT 1
                FROM DBO.FACTURA
                WHERE ID_FACTURA = @ID_FACTURA
            )
            THROW 52201, 'La factura no existe.', 1;

        IF
            NOT EXISTS (
                SELECT 1
                FROM DBO.EMPRESA
                WHERE CEDULA = @CEDULA_EMPRESA
            )
            THROW 52202, 'La empresa no existe.', 1;

        IF
            NOT EXISTS (
                SELECT 1
                FROM DBO.CLIENTE
                WHERE CEDULA = @CEDULA_CLIENTE
            )
            THROW 52203, 'El cliente no existe.', 1;

        IF
            NOT EXISTS (
                SELECT 1
                FROM DBO.TIPODOCUMENTO
                WHERE CODIGO = @CODIGO_TIPO_DOCUMENTO
            )
            THROW 52204, 'El tipo de documento no existe.', 1;

        IF
            NOT EXISTS (
                SELECT 1
                FROM DBO.MONEDA
                WHERE CODIGO = @CODIGO_MONEDA
            )
            THROW 52205, 'La moneda no existe.', 1;

        IF @FECHA_EMISION IS NULL
            THROW 52206, 'La fecha de emision es obligatoria.', 1;

        IF @FECHA_EMISION > CONVERT(DATETIME2(0), SYSDATETIME())
            THROW 52207, 'La fecha de emision no puede ser futura.', 1;

        BEGIN TRANSACTION;

        UPDATE DBO.FACTURA
        SET
            CEDULA_EMPRESA = @CEDULA_EMPRESA,
            CEDULA_CLIENTE = @CEDULA_CLIENTE,
            CODIGO_TIPO_DOCUMENTO = @CODIGO_TIPO_DOCUMENTO,
            CODIGO_MONEDA = @CODIGO_MONEDA,
            FECHA_EMISION = @FECHA_EMISION,
            OBSERVACIONES = ISNULL(
                NULLIF(TRIM(@OBSERVACIONES), ''),
                'SIN OBSERVACIONES'
            ),
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
