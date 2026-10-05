USE FACTURACIONSOLUCIONESMAGNIFICAS;
GO

IF EXISTS (
    SELECT 1
    FROM sys.objects
    WHERE name = 'SP_CREAR_PRODUCTO'
      AND type = 'P'
)
BEGIN
    DROP PROCEDURE dbo.SP_CREAR_PRODUCTO;
END
GO

CREATE PROCEDURE dbo.SP_CREAR_PRODUCTO
    @CODIGO VARCHAR(30),
    @DESCRIPCION VARCHAR(200),
    @TIPO_PRODUCTO VARCHAR(10),
    @EXISTENCIA INT,
    @PRECIO_UNITARIO DECIMAL(18, 2),
    @PORCENTAJE_IMPUESTO DECIMAL(5, 2),
    @ACTIVO BIT = 1
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        SET @CODIGO = TRIM(@CODIGO);
        SET @DESCRIPCION = TRIM(@DESCRIPCION);
        SET @TIPO_PRODUCTO = UPPER(TRIM(@TIPO_PRODUCTO));

        IF NULLIF(@CODIGO, '') IS NULL
            THROW 51301, 'El codigo es obligatorio.', 1;

        IF NULLIF(@DESCRIPCION, '') IS NULL
            THROW 51302, 'La descripcion es obligatoria.', 1;

        IF NULLIF(@TIPO_PRODUCTO, '') IS NULL
            THROW 51303, 'El tipo de producto es obligatorio.', 1;

        IF NOT EXISTS (
            SELECT 1
            FROM dbo.TIPOPRODUCTO
            WHERE CODIGO = @TIPO_PRODUCTO
        )
            THROW 51304, 'El tipo de producto no existe.', 1;

        IF @EXISTENCIA IS NULL OR @EXISTENCIA < 0
            THROW 51305, 'La existencia debe ser mayor o igual a cero.', 1;

        IF @TIPO_PRODUCTO = 'DIGITAL' AND @EXISTENCIA <> 0
            THROW 51306, 'Los productos digitales deben tener existencia cero.', 1;

        IF @PRECIO_UNITARIO IS NULL OR @PRECIO_UNITARIO <= 0
            THROW 51307, 'El precio debe ser mayor que cero.', 1;

        IF @PORCENTAJE_IMPUESTO IS NULL
           OR @PORCENTAJE_IMPUESTO NOT BETWEEN 0 AND 100
            THROW 51308, 'El impuesto debe estar entre 0 y 100.', 1;

        IF @ACTIVO IS NULL
            THROW 51309, 'El estado activo es obligatorio.', 1;

        IF EXISTS (
            SELECT 1
            FROM dbo.PRODUCTO
            WHERE CODIGO = @CODIGO
        )
            THROW 51310, 'Ya existe un producto con ese codigo.', 1;

        BEGIN TRANSACTION;

        INSERT INTO dbo.PRODUCTO (
            CODIGO,
            DESCRIPCION,
            TIPO_PRODUCTO,
            EXISTENCIA,
            PRECIO_UNITARIO,
            PORCENTAJE_IMPUESTO,
            ACTIVO,
            FECHA_CREACION
        )
        VALUES (
            @CODIGO,
            @DESCRIPCION,
            @TIPO_PRODUCTO,
            @EXISTENCIA,
            @PRECIO_UNITARIO,
            @PORCENTAJE_IMPUESTO,
            @ACTIVO,
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
