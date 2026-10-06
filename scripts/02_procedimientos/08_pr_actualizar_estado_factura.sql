USE FACTURACIONSOLUCIONESMAGNIFICAS;
GO

IF
    EXISTS (
        SELECT 1
        FROM SYS.OBJECTS
        WHERE
            NAME = 'PR_ACTUALIZAR_ESTADO_FACTURA'
            AND TYPE = 'P'
    )
    BEGIN
        DROP PROCEDURE DBO.PR_ACTUALIZAR_ESTADO_FACTURA;
    END
GO

CREATE PROCEDURE DBO.PR_ACTUALIZAR_ESTADO_FACTURA
    @ID_FACTURA BIGINT,
    @NUEVO_ESTADO VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        SET @NUEVO_ESTADO = UPPER(TRIM(@NUEVO_ESTADO));

        IF
            NOT EXISTS (
                SELECT 1
                FROM DBO.FACTURA
                WHERE ID_FACTURA = @ID_FACTURA
            )
            THROW 52301, 'La factura indicada no existe.', 1;

        IF NULLIF(@NUEVO_ESTADO, '') IS NULL
            THROW 52302, 'El nuevo estado es obligatorio.', 1;

        IF
            NOT EXISTS (
                SELECT 1
                FROM DBO.ESTADOFACTURA
                WHERE ESTADO = @NUEVO_ESTADO
            )
            THROW 52303, 'El nuevo estado no existe.', 1;

        IF
            EXISTS (
                SELECT 1
                FROM DBO.FACTURA
                WHERE
                    ID_FACTURA = @ID_FACTURA
                    AND ESTADO_FACTURA = @NUEVO_ESTADO
            )
            THROW 52304, 'La factura ya posee ese estado.', 1;

        BEGIN TRANSACTION;

        UPDATE DBO.FACTURA
        SET
            ESTADO_FACTURA = @NUEVO_ESTADO,
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
