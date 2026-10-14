USE FACTURACIONSOLUCIONESMAGNIFICAS;
GO

IF
    EXISTS (
        SELECT 1
        FROM SYS.OBJECTS
        WHERE
            NAME = 'PR_CREAR_FACTURA'
            AND TYPE = 'P'
    )
    BEGIN
        DROP PROCEDURE DBO.PR_CREAR_FACTURA;
    END
GO

CREATE PROCEDURE DBO.PR_CREAR_FACTURA
    @CEDULA_EMPRESA VARCHAR(20),
    @CEDULA_CLIENTE VARCHAR(20),
    @CODIGO_TIPO_DOCUMENTO VARCHAR(10),
    @CODIGO_MONEDA CHAR(3),
    @ESTADO_FACTURA VARCHAR(20),
    @FECHA_EMISION DATETIME2(0),
    @OBSERVACIONES VARCHAR(500) = NULL,
    @ID_FACTURA BIGINT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        SET @CEDULA_EMPRESA = TRIM(@CEDULA_EMPRESA);
        SET @CEDULA_CLIENTE = TRIM(@CEDULA_CLIENTE);
        SET @CODIGO_TIPO_DOCUMENTO = TRIM(@CODIGO_TIPO_DOCUMENTO);
        SET @CODIGO_MONEDA = TRIM(@CODIGO_MONEDA);
        SET @ESTADO_FACTURA = UPPER(TRIM(@ESTADO_FACTURA));

        IF NULLIF(@CEDULA_EMPRESA, '') IS NULL
            THROW 52001, 'La empresa es obligatoria.', 1;

        IF NULLIF(@CEDULA_CLIENTE, '') IS NULL
            THROW 52002, 'El cliente es obligatorio.', 1;

        IF
            NOT EXISTS (
                SELECT 1
                FROM DBO.EMPRESA
                WHERE CEDULA = @CEDULA_EMPRESA
            )
            THROW 52003, 'La empresa indicada no existe.', 1;

        IF
            NOT EXISTS (
                SELECT 1
                FROM DBO.CLIENTE
                WHERE CEDULA = @CEDULA_CLIENTE
            )
            THROW 52004, 'El cliente indicado no existe.', 1;

        IF
            NOT EXISTS (
                SELECT 1
                FROM DBO.TIPODOCUMENTO
                WHERE CODIGO = @CODIGO_TIPO_DOCUMENTO
            )
            THROW 52005, 'El tipo de documento no existe.', 1;

        IF
            NOT EXISTS (
                SELECT 1
                FROM DBO.MONEDA
                WHERE CODIGO = @CODIGO_MONEDA
            )
            THROW 52006, 'La moneda no existe.', 1;

        IF
            NOT EXISTS (
                SELECT 1
                FROM DBO.ESTADOFACTURA
                WHERE ESTADO = @ESTADO_FACTURA
            )
            THROW 52007, 'El estado de factura no existe.', 1;

        IF @FECHA_EMISION IS NULL
            THROW 52008, 'La fecha de emision es obligatoria.', 1;

        IF @FECHA_EMISION > CONVERT(DATETIME2(0), SYSDATETIME())
            THROW 52009, 'La fecha de emision no puede ser futura.', 1;

        DECLARE @IDENTIFICADOR_COMPROBANTE VARCHAR(40);

        SET @IDENTIFICADOR_COMPROBANTE = CONCAT(
            CONVERT(
                CHAR(8),
                @FECHA_EMISION,
                112
            ),
            REPLACE(
                CONVERT(
                    CHAR(8),
                    @FECHA_EMISION,
                    108
                ),
                ':',
                ''
            ),
            '-',
            @CODIGO_TIPO_DOCUMENTO
        );

        IF
            EXISTS (
                SELECT 1
                FROM DBO.FACTURA
                WHERE
                    IDENTIFICADOR_COMPROBANTE
                    = @IDENTIFICADOR_COMPROBANTE
            )
            THROW 52010, 'El identificador ya existe.', 1;

        SET @OBSERVACIONES = ISNULL(
            NULLIF(TRIM(@OBSERVACIONES), ''),
            'SIN OBSERVACIONES'
        );

        BEGIN TRANSACTION;

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
        VALUES (
            @IDENTIFICADOR_COMPROBANTE,
            @CEDULA_EMPRESA,
            @CEDULA_CLIENTE,
            @CODIGO_TIPO_DOCUMENTO,
            @CODIGO_MONEDA,
            @ESTADO_FACTURA,
            @FECHA_EMISION,
            0,
            0,
            0,
            0,
            @OBSERVACIONES,
            CONVERT(DATETIME2(0), SYSDATETIME()),
            CONVERT(DATETIME2(0), SYSDATETIME())
        );

        SET @ID_FACTURA = CONVERT(
            BIGINT,
            SCOPE_IDENTITY()
        );

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH;
END;
GO
