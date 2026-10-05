USE FACTURACIONSOLUCIONESMAGNIFICAS;
GO

IF EXISTS (
    SELECT 1
    FROM SYS.OBJECTS
    WHERE NAME = 'SP_ACTUALIZAR_CLIENTE'
      AND TYPE = 'P'
)
BEGIN
    DROP PROCEDURE DBO.SP_ACTUALIZAR_CLIENTE;
END
GO

CREATE PROCEDURE DBO.SP_ACTUALIZAR_CLIENTE
    @CEDULA VARCHAR(20),
    @ID_DIRECCION INT,
    @TELEFONO VARCHAR(20),
    @CORREO VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        SET @CEDULA = TRIM(@CEDULA);
        SET @TELEFONO = TRIM(@TELEFONO);
        SET @CORREO = TRIM(@CORREO);

        IF NULLIF(@CEDULA, '') IS NULL
            THROW 50011, 'La cedula es obligatoria.', 1;

        IF NOT EXISTS (
            SELECT 1
            FROM DBO.CLIENTE
            WHERE CEDULA = @CEDULA
        )
            THROW 50012, 'El cliente no existe.', 1;

        IF @ID_DIRECCION IS NULL
            THROW 50013, 'La direccion es obligatoria.', 1;

        IF NOT EXISTS (
            SELECT 1
            FROM DBO.DIRECCION
            WHERE ID_DIRECCION = @ID_DIRECCION
        )
            THROW 50014, 'La direccion no existe.', 1;

        IF NULLIF(@TELEFONO, '') IS NULL
            THROW 50015, 'El telefono es obligatorio.', 1;

        IF NULLIF(@CORREO, '') IS NULL
           OR @CORREO NOT LIKE '%_@_%._%'
           OR @CORREO LIKE '% %'
            THROW 50016, 'El correo no tiene un formato valido.', 1;

        BEGIN TRANSACTION;

        UPDATE DBO.CLIENTE
        SET
            ID_DIRECCION = @ID_DIRECCION,
            TELEFONO = @TELEFONO,
            CORREO = @CORREO,
            FECHA_ACTUALIZACION = CONVERT(DATETIME2(0), SYSDATETIME())
        WHERE CEDULA = @CEDULA;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH;
END;
GO
