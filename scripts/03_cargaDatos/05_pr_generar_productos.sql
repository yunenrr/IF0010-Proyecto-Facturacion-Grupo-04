USE FACTURACIONSOLUCIONESMAGNIFICAS;
GO

IF
    EXISTS (
        SELECT 1
        FROM SYS.OBJECTS
        WHERE
            NAME = 'PR_GENERAR_PRODUCTOS'
            AND TYPE = 'P'
    )
    BEGIN
        DROP PROCEDURE DBO.PR_GENERAR_PRODUCTOS;
    END
GO

CREATE PROCEDURE DBO.PR_GENERAR_PRODUCTOS
    @TOTAL_OBJETIVO INT = 1000
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF @TOTAL_OBJETIVO IS NULL OR @TOTAL_OBJETIVO < 1000
            THROW 51401, 'Se deben generar al menos 1000 productos.', 1;

        IF (
            NOT EXISTS (
                SELECT 1
                FROM DBO.TIPOPRODUCTO
                WHERE CODIGO = 'FISICO'
            )
            OR NOT EXISTS (
                SELECT 1
                FROM DBO.TIPOPRODUCTO
                WHERE CODIGO = 'DIGITAL'
            )
        )
            THROW 51402, 'Primero se deben cargar los tipos de producto.', 1;

        BEGIN TRANSACTION;

        DECLARE @ACTUAL BIGINT;
        DECLARE @CONTADOR INT = 1;

        DECLARE @CODIGO VARCHAR(30);
        DECLARE @DESCRIPCION VARCHAR(200);
        DECLARE @TIPO VARCHAR(10);
        DECLARE @EXISTENCIA INT;
        DECLARE @PRECIO DECIMAL(18, 2);
        DECLARE @IMPUESTO DECIMAL(5, 2);

        SELECT @ACTUAL = COUNT_BIG(*)
        FROM DBO.PRODUCTO;

        WHILE @ACTUAL < @TOTAL_OBJETIVO
        BEGIN
            SET @CODIGO = CONCAT('PROD-GENERADO-', @CONTADOR);

            IF
                NOT EXISTS (
                    SELECT 1
                    FROM DBO.PRODUCTO
                    WHERE CODIGO = @CODIGO
                )
            BEGIN
                SET @TIPO = CASE
                    WHEN @CONTADOR % 2 = 0 THEN 'DIGITAL'
                    ELSE 'FISICO'
                END;

                SET @EXISTENCIA = CASE
                    WHEN @TIPO = 'FISICO' THEN 10 + @CONTADOR % 491
                    ELSE 0
                END;

                SET @DESCRIPCION =
                    CONCAT('Producto de prueba ', @CONTADOR);

                SET @PRECIO = CONVERT(
                    DECIMAL(18, 2),
                    100 + (@CONTADOR % 1000) * 25.50
                );

                SET @IMPUESTO = CASE @CONTADOR % 4
                    WHEN 0 THEN 0
                    WHEN 1 THEN 1
                    WHEN 2 THEN 4
                    ELSE 13
                END;

                EXEC DBO.PR_CREAR_PRODUCTO
                    @CODIGO = @CODIGO,
                    @DESCRIPCION = @DESCRIPCION,
                    @TIPO_PRODUCTO = @TIPO,
                    @EXISTENCIA = @EXISTENCIA,
                    @PRECIO_UNITARIO = @PRECIO,
                    @PORCENTAJE_IMPUESTO = @IMPUESTO,
                    @ACTIVO = 1;

                SET @ACTUAL = @ACTUAL + 1;
            END;

            SET @CONTADOR = @CONTADOR + 1;
        END;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH;
END;
GO

EXEC DBO.PR_GENERAR_PRODUCTOS @TOTAL_OBJETIVO = 1000;
GO

DROP PROCEDURE DBO.PR_GENERAR_PRODUCTOS;
GO
