USE FACTURACIONSOLUCIONESMAGNIFICAS;
GO

IF
    EXISTS (
        SELECT 1
        FROM SYS.OBJECTS
        WHERE
            NAME = 'PR_CREAR_PRODUCTO'
            AND TYPE = 'P'
    )
    BEGIN
        DROP PROCEDURE DBO.PR_CREAR_PRODUCTO;
    END
GO

CREATE PROCEDURE DBO.PR_CREAR_PRODUCTO
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

        IF
            NOT EXISTS (
                SELECT 1
                FROM DBO.TIPOPRODUCTO
                WHERE CODIGO = @TIPO_PRODUCTO
            )
            THROW 51304, 'El tipo de producto no existe.', 1;

        IF @EXISTENCIA IS NULL OR @EXISTENCIA < 0
            THROW 51305, 'La existencia debe ser mayor o igual a cero.', 1;

        IF @TIPO_PRODUCTO = 'DIGITAL' AND @EXISTENCIA <> 0
            THROW 51306, 'El producto digital debe tener existencia cero.', 1;

        IF @PRECIO_UNITARIO IS NULL OR @PRECIO_UNITARIO <= 0
            THROW 51307, 'El precio debe ser mayor que cero.', 1;

        IF (
            @PORCENTAJE_IMPUESTO IS NULL
            OR @PORCENTAJE_IMPUESTO NOT BETWEEN 0 AND 100
        )
            THROW 51308, 'El impuesto debe estar entre 0 y 100.', 1;

        IF @ACTIVO IS NULL
            THROW 51309, 'El estado activo es obligatorio.', 1;

        IF
            EXISTS (
                SELECT 1
                FROM DBO.PRODUCTO
                WHERE CODIGO = @CODIGO
            )
            THROW 51310, 'Ya existe un producto con ese codigo.', 1;

        DECLARE @ID_TIPO_PRODUCTO INT;

        SELECT @ID_TIPO_PRODUCTO = TP.ID_TIPO_PRODUCTO
        FROM DBO.TIPOPRODUCTO AS TP
        WHERE TP.CODIGO = @TIPO_PRODUCTO;

        BEGIN TRANSACTION;

        INSERT INTO DBO.PRODUCTO (
            CODIGO,
            DESCRIPCION,
            ID_TIPO_PRODUCTO,
            EXISTENCIA,
            PRECIO_UNITARIO,
            PORCENTAJE_IMPUESTO,
            FECHA_CREACION,
            FECHA_MODIFICACION,
            ACTIVO
        )
        VALUES (
            @CODIGO,
            @DESCRIPCION,
            @ID_TIPO_PRODUCTO,
            @EXISTENCIA,
            @PRECIO_UNITARIO,
            @PORCENTAJE_IMPUESTO,
            CONVERT(DATETIME2(0), SYSDATETIME()),
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
