USE FACTURACIONSOLUCIONESMAGNIFICAS;
GO

IF EXISTS (
    SELECT 1
    FROM sys.objects
    WHERE name = 'SP_CARGAR_CATALOGOS'
      AND type = 'P'
)
BEGIN
    DROP PROCEDURE dbo.SP_CARGAR_CATALOGOS;
END
GO

CREATE PROCEDURE dbo.SP_CARGAR_CATALOGOS
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        INSERT INTO dbo.TIPODOCUMENTO (CODIGO, DESCRIPCION)
        SELECT DATOS.CODIGO, DATOS.DESCRIPCION
        FROM (
            VALUES
                ('01', 'Factura electronica'),
                ('02', 'Nota de debito electronica'),
                ('03', 'Nota de credito electronica'),
                ('04', 'Tiquete electronico')
        ) AS DATOS (CODIGO, DESCRIPCION)
        WHERE NOT EXISTS (
            SELECT 1
            FROM dbo.TIPODOCUMENTO AS EXISTENTE
            WHERE EXISTENTE.CODIGO = DATOS.CODIGO
        );

        INSERT INTO dbo.MONEDA (CODIGO, SIMBOLO, DESCRIPCION)
        SELECT DATOS.CODIGO, DATOS.SIMBOLO, DATOS.DESCRIPCION
        FROM (
            VALUES
                ('CRC', N'₡', 'Colon costarricense'),
                ('USD', N'$', 'Dolar estadounidense'),
                ('EUR', N'€', 'Euro')
        ) AS DATOS (CODIGO, SIMBOLO, DESCRIPCION)
        WHERE NOT EXISTS (
            SELECT 1
            FROM dbo.MONEDA AS EXISTENTE
            WHERE EXISTENTE.CODIGO = DATOS.CODIGO
        );

        INSERT INTO dbo.ESTADOFACTURA (ESTADO, DESCRIPCION)
        SELECT DATOS.ESTADO, DATOS.DESCRIPCION
        FROM (
            VALUES
                ('BORRADOR', 'Factura en preparacion'),
                ('EMITIDA', 'Factura emitida'),
                ('PAGADA', 'Factura pagada'),
                ('CANCELADA', 'Factura cancelada')
        ) AS DATOS (ESTADO, DESCRIPCION)
        WHERE NOT EXISTS (
            SELECT 1
            FROM dbo.ESTADOFACTURA AS EXISTENTE
            WHERE EXISTENTE.ESTADO = DATOS.ESTADO
        );

        INSERT INTO dbo.TIPOCLIENTE (CODIGO, DESCRIPCION)
        SELECT DATOS.CODIGO, DATOS.DESCRIPCION
        FROM (
            VALUES
                ('FISICA', 'Persona fisica'),
                ('JURIDICA', 'Persona juridica')
        ) AS DATOS (CODIGO, DESCRIPCION)
        WHERE NOT EXISTS (
            SELECT 1
            FROM dbo.TIPOCLIENTE AS EXISTENTE
            WHERE EXISTENTE.CODIGO = DATOS.CODIGO
        );

        INSERT INTO dbo.TIPOPRODUCTO (CODIGO, DESCRIPCION)
        SELECT DATOS.CODIGO, DATOS.DESCRIPCION
        FROM (
            VALUES
                ('FISICO', 'Producto fisico'),
                ('DIGITAL', 'Producto digital')
        ) AS DATOS (CODIGO, DESCRIPCION)
        WHERE NOT EXISTS (
            SELECT 1
            FROM dbo.TIPOPRODUCTO AS EXISTENTE
            WHERE EXISTENTE.CODIGO = DATOS.CODIGO
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

EXEC dbo.SP_CARGAR_CATALOGOS;
GO

DROP PROCEDURE dbo.SP_CARGAR_CATALOGOS;
GO
