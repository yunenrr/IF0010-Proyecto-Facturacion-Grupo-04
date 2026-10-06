USE FACTURACIONSOLUCIONESMAGNIFICAS;
GO

IF
    EXISTS (
        SELECT 1
        FROM SYS.OBJECTS
        WHERE
            NAME = 'PR_CARGAR_CATALOGOS'
            AND TYPE = 'P'
    )
    BEGIN
        DROP PROCEDURE DBO.PR_CARGAR_CATALOGOS;
    END
GO

CREATE PROCEDURE DBO.PR_CARGAR_CATALOGOS
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        INSERT INTO DBO.TIPODOCUMENTO (CODIGO, DESCRIPCION)
        SELECT
            DATOS.CODIGO,
            DATOS.DESCRIPCION
        FROM (
            VALUES
                ('01', 'Factura electronica'),
                ('02', 'Nota de debito electronica'),
                ('03', 'Nota de credito electronica'),
                ('04', 'Tiquete electronico')
        ) AS DATOS (CODIGO, DESCRIPCION)
        WHERE
            NOT EXISTS (
                SELECT 1
                FROM DBO.TIPODOCUMENTO AS EXISTENTE
                WHERE EXISTENTE.CODIGO = DATOS.CODIGO
            );

        INSERT INTO DBO.MONEDA (CODIGO, SIMBOLO, DESCRIPCION)
        SELECT
            DATOS.CODIGO,
            DATOS.SIMBOLO,
            DATOS.DESCRIPCION
        FROM (
            VALUES
                ('CRC', N'₡', 'Colon costarricense'),
                ('USD', N'$', 'Dolar estadounidense'),
                ('EUR', N'€', 'Euro')
        ) AS DATOS (CODIGO, SIMBOLO, DESCRIPCION)
        WHERE
            NOT EXISTS (
                SELECT 1
                FROM DBO.MONEDA AS EXISTENTE
                WHERE EXISTENTE.CODIGO = DATOS.CODIGO
            );

        INSERT INTO DBO.ESTADOFACTURA (ESTADO, DESCRIPCION)
        SELECT
            DATOS.ESTADO,
            DATOS.DESCRIPCION
        FROM (
            VALUES
                ('BORRADOR', 'Factura en preparacion'),
                ('EMITIDA', 'Factura emitida'),
                ('PAGADA', 'Factura pagada'),
                ('CANCELADA', 'Factura cancelada')
        ) AS DATOS (ESTADO, DESCRIPCION)
        WHERE
            NOT EXISTS (
                SELECT 1
                FROM DBO.ESTADOFACTURA AS EXISTENTE
                WHERE EXISTENTE.ESTADO = DATOS.ESTADO
            );

        INSERT INTO DBO.TIPOCLIENTE (CODIGO, DESCRIPCION)
        SELECT
            DATOS.CODIGO,
            DATOS.DESCRIPCION
        FROM (
            VALUES
                ('FISICA', 'Persona fisica'),
                ('JURIDICA', 'Persona juridica')
        ) AS DATOS (CODIGO, DESCRIPCION)
        WHERE
            NOT EXISTS (
                SELECT 1
                FROM DBO.TIPOCLIENTE AS EXISTENTE
                WHERE EXISTENTE.CODIGO = DATOS.CODIGO
            );

        INSERT INTO DBO.TIPOPRODUCTO (CODIGO, DESCRIPCION)
        SELECT
            DATOS.CODIGO,
            DATOS.DESCRIPCION
        FROM (
            VALUES
                ('FISICO', 'Producto fisico'),
                ('DIGITAL', 'Producto digital')
        ) AS DATOS (CODIGO, DESCRIPCION)
        WHERE
            NOT EXISTS (
                SELECT 1
                FROM DBO.TIPOPRODUCTO AS EXISTENTE
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

EXEC DBO.PR_CARGAR_CATALOGOS;
GO

DROP PROCEDURE DBO.PR_CARGAR_CATALOGOS;
GO
