USE FACTURACIONSOLUCIONESMAGNIFICAS;
GO

IF EXISTS (
    SELECT 1
    FROM sys.objects
    WHERE name = 'SP_CREAR_CLIENTE'
      AND type = 'P'
)
BEGIN
    DROP PROCEDURE dbo.SP_CREAR_CLIENTE;
END
GO

CREATE PROCEDURE dbo.SP_CREAR_CLIENTE
    @CEDULA VARCHAR(20),
    @TIPO_CLIENTE VARCHAR(10),
    @NOMBRE VARCHAR(150),
    @RAZON_SOCIAL VARCHAR(150),
    @ID_DIRECCION INT,
    @TELEFONO VARCHAR(20),
    @CORREO VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        SET @CEDULA = TRIM(@CEDULA);
        SET @TIPO_CLIENTE = UPPER(TRIM(@TIPO_CLIENTE));
        SET @NOMBRE = TRIM(@NOMBRE);
        SET @RAZON_SOCIAL = TRIM(@RAZON_SOCIAL);
        SET @TELEFONO = TRIM(@TELEFONO);
        SET @CORREO = TRIM(@CORREO);

        IF NULLIF(@CEDULA, '') IS NULL
            THROW 50001, 'La cedula es obligatoria.', 1;

        IF NULLIF(@TIPO_CLIENTE, '') IS NULL
            THROW 50002, 'El tipo de cliente es obligatorio.', 1;

        IF NOT EXISTS (
            SELECT 1
            FROM dbo.TIPOCLIENTE
            WHERE CODIGO = @TIPO_CLIENTE
        )
            THROW 50003, 'El tipo de cliente no existe.', 1;

        IF @TIPO_CLIENTE = 'FISICA'
        BEGIN
            IF NULLIF(@NOMBRE, '') IS NULL
                THROW 50004, 'El cliente fisico debe tener nombre.', 1;

            SET @RAZON_SOCIAL = 'NO APLICA';
        END;

        IF @TIPO_CLIENTE = 'JURIDICA'
        BEGIN
            IF NULLIF(@RAZON_SOCIAL, '') IS NULL
                THROW 50005, 'El cliente juridico debe tener razon social.', 1;

            SET @NOMBRE = 'NO APLICA';
        END;

        IF @ID_DIRECCION IS NULL
            THROW 50006, 'La direccion es obligatoria.', 1;

        IF NOT EXISTS (
            SELECT 1
            FROM dbo.DIRECCION
            WHERE ID_DIRECCION = @ID_DIRECCION
        )
            THROW 50007, 'La direccion no existe.', 1;

        IF NULLIF(@TELEFONO, '') IS NULL
            THROW 50008, 'El telefono es obligatorio.', 1;

        IF NULLIF(@CORREO, '') IS NULL
           OR @CORREO NOT LIKE '%_@_%._%'
           OR @CORREO LIKE '% %'
            THROW 50009, 'El correo no tiene un formato valido.', 1;

        IF EXISTS (
            SELECT 1
            FROM dbo.CLIENTE
            WHERE CEDULA = @CEDULA
        )
            THROW 50010, 'La cedula ya pertenece a un cliente.', 1;

        BEGIN TRANSACTION;

        INSERT INTO dbo.CLIENTE (
            CEDULA,
            TIPO_CLIENTE,
            NOMBRE,
            RAZON_SOCIAL,
            ID_DIRECCION,
            TELEFONO,
            CORREO,
            FECHA_REGISTRO,
            FECHA_ACTUALIZACION
        )
        VALUES (
            @CEDULA,
            @TIPO_CLIENTE,
            @NOMBRE,
            @RAZON_SOCIAL,
            @ID_DIRECCION,
            @TELEFONO,
            @CORREO,
            CONVERT(DATETIME2(0), SYSDATETIME()),
            CONVERT(DATETIME2(0), SYSDATETIME())
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
