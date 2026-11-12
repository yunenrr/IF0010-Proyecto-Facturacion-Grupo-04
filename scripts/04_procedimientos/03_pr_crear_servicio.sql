USE FACTURACIONSOLUCIONESMAGNIFICAS;
GO

IF
    EXISTS (
        SELECT 1
        FROM SYS.OBJECTS
        WHERE
            NAME = 'PR_CREAR_SERVICIO'
            AND TYPE = 'P'
    )
    BEGIN
        DROP PROCEDURE DBO.PR_CREAR_SERVICIO;
    END
GO

CREATE PROCEDURE DBO.PR_CREAR_SERVICIO
    @CODIGO VARCHAR(30),
    @DESCRIPCION VARCHAR(200),
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

        IF NULLIF(@CODIGO, '') IS NULL
            THROW 51501, 'El codigo del servicio es obligatorio.', 1;

        IF NULLIF(@DESCRIPCION, '') IS NULL
            THROW 51502, 'La descripcion es obligatoria.', 1;

        IF @PRECIO_UNITARIO IS NULL OR @PRECIO_UNITARIO <= 0
            THROW 51507, 'El precio debe ser mayor que cero.', 1;

        IF (
            @PORCENTAJE_IMPUESTO IS NULL
            OR @PORCENTAJE_IMPUESTO NOT BETWEEN 0 AND 100
        )
            THROW 51508, 'El impuesto debe estar entre 0 y 100.', 1;

        IF @ACTIVO IS NULL
            THROW 51509, 'El estado activo es obligatorio.', 1;

        IF
            EXISTS (
                SELECT 1
                FROM DBO.SERVICIO
                WHERE CODIGO = @CODIGO
            )
            THROW 51510, 'Ya existe un servicio con ese codigo.', 1;

        BEGIN TRANSACTION;

        INSERT INTO DBO.SERVICIO (
            CODIGO,
            DESCRIPCION,
            PRECIO_UNITARIO,
            PORCENTAJE_IMPUESTO,
            FECHA_CREACION,
            FECHA_MODIFICACION,
            ACTIVO
        )
        VALUES (
            @CODIGO,
            @DESCRIPCION,
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
