USE FACTURACIONSOLUCIONESMAGNIFICAS;
GO

IF EXISTS (
    SELECT 1
    FROM sys.objects
    WHERE name = 'SP_CREAR_EMPRESA'
      AND type = 'P'
)
BEGIN
    DROP PROCEDURE dbo.SP_CREAR_EMPRESA;
END
GO

CREATE PROCEDURE dbo.SP_CREAR_EMPRESA
    @CEDULA VARCHAR(20),
    @NOMBRE_COMERCIAL VARCHAR(100),
    @RAZON_SOCIAL VARCHAR(150),
    @ID_DIRECCION INT,
    @TELEFONO VARCHAR(20),
    @CORREO VARCHAR(100),
    @ACTIVO BIT = 1
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        SET @CEDULA = TRIM(@CEDULA);
        SET @NOMBRE_COMERCIAL = TRIM(@NOMBRE_COMERCIAL);
        SET @RAZON_SOCIAL = TRIM(@RAZON_SOCIAL);
        SET @TELEFONO = TRIM(@TELEFONO);
        SET @CORREO = TRIM(@CORREO);

        IF NULLIF(@CEDULA, '') IS NULL
            THROW 51101, 'La cedula es obligatoria.', 1;

        IF NULLIF(@NOMBRE_COMERCIAL, '') IS NULL
            THROW 51102, 'El nombre comercial es obligatorio.', 1;

        IF NULLIF(@RAZON_SOCIAL, '') IS NULL
            THROW 51103, 'La razon social es obligatoria.', 1;

        IF NULLIF(@TELEFONO, '') IS NULL
            THROW 51104, 'El telefono es obligatorio.', 1;

        IF NULLIF(@CORREO, '') IS NULL
           OR @CORREO NOT LIKE '%_@_%._%'
           OR @CORREO LIKE '% %'
            THROW 51105, 'El correo no tiene un formato valido.', 1;

        IF @ID_DIRECCION IS NULL
            THROW 51106, 'La direccion es obligatoria.', 1;

        IF NOT EXISTS (
            SELECT 1
            FROM dbo.DIRECCION
            WHERE ID_DIRECCION = @ID_DIRECCION
        )
            THROW 51107, 'La direccion no existe.', 1;

        IF @ACTIVO IS NULL
            THROW 51108, 'El estado activo es obligatorio.', 1;

        IF EXISTS (
            SELECT 1
            FROM dbo.EMPRESA
            WHERE CEDULA = @CEDULA
        )
            THROW 51109, 'Ya existe una empresa con esa cedula.', 1;

        BEGIN TRANSACTION;

        INSERT INTO dbo.EMPRESA (
            CEDULA,
            NOMBRE_COMERCIAL,
            RAZON_SOCIAL,
            ID_DIRECCION,
            TELEFONO,
            CORREO,
            FECHA_CREACION,
            ACTIVO
        )
        VALUES (
            @CEDULA,
            @NOMBRE_COMERCIAL,
            @RAZON_SOCIAL,
            @ID_DIRECCION,
            @TELEFONO,
            @CORREO,
            CONVERT(DATETIME2(0), SYSDATETIME()),
            @ACTIVO
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
