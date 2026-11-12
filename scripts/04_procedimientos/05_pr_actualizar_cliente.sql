USE FACTURACIONSOLUCIONESMAGNIFICAS;
GO

IF
    EXISTS (
        SELECT 1
        FROM SYS.OBJECTS
        WHERE
            NAME = 'PR_ACTUALIZAR_CLIENTE'
            AND TYPE = 'P'
    )
    BEGIN
        DROP PROCEDURE DBO.PR_ACTUALIZAR_CLIENTE;
    END
GO

CREATE PROCEDURE DBO.PR_ACTUALIZAR_CLIENTE
    @CEDULA VARCHAR(20),
    @TIPO_CLIENTE VARCHAR(10),
    @NOMBRE VARCHAR(150),
    @RAZON_SOCIAL VARCHAR(150),
    @ID_DIRECCION INT,
    @TELEFONO VARCHAR(20),
    @CORREO VARCHAR(100),
    @PRIMER_APELLIDO VARCHAR(100) = NULL,
    @SEGUNDO_APELLIDO VARCHAR(100) = NULL,
    @NOMBRE_COMERCIAL VARCHAR(150) = NULL
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
        SET @PRIMER_APELLIDO = NULLIF(TRIM(@PRIMER_APELLIDO), '');
        SET @SEGUNDO_APELLIDO = NULLIF(TRIM(@SEGUNDO_APELLIDO), '');
        SET @NOMBRE_COMERCIAL = NULLIF(TRIM(@NOMBRE_COMERCIAL), '');

        IF NULLIF(@CEDULA, '') IS NULL
            THROW 51120, 'La cedula es obligatoria.', 1;

        IF
            NOT EXISTS (
                SELECT 1
                FROM DBO.CLIENTE
                WHERE CEDULA = @CEDULA
            )
            THROW 51121, 'El cliente no existe.', 1;

        IF
            NULLIF(@TIPO_CLIENTE, '') IS NULL
            OR @TIPO_CLIENTE NOT IN ('FISICA', 'JURIDICA')
            THROW 51122, 'El tipo de cliente no es valido.', 1;

        IF
            NOT EXISTS (
                SELECT 1
                FROM DBO.DIRECCION
                WHERE ID_DIRECCION = @ID_DIRECCION
            )
            THROW 51124, 'La direccion no existe.', 1;

        IF
            @TIPO_CLIENTE = 'FISICA'
            AND NULLIF(@NOMBRE, '') IS NULL
            THROW 51125, 'El nombre es obligatorio.', 1;

        IF
            @TIPO_CLIENTE = 'JURIDICA'
            AND NULLIF(@RAZON_SOCIAL, '') IS NULL
            THROW 51126, 'La razon social es obligatoria.', 1;

        IF NULLIF(@TELEFONO, '') IS NULL
            THROW 51127, 'El telefono es obligatorio.', 1;

        IF NULLIF(@CORREO, '') IS NULL
            THROW 51128, 'El correo es obligatorio.', 1;

        BEGIN TRANSACTION;

        IF @TIPO_CLIENTE = 'FISICA'
            BEGIN
                IF
                    NOT EXISTS (
                        SELECT 1
                        FROM DBO.CLIENTEFISICO WITH (UPDLOCK, HOLDLOCK)
                        WHERE CEDULA_CLIENTE = @CEDULA
                    )
                    THROW 51130, 'El cliente fisico no existe.', 1;

                IF
                    EXISTS (
                        SELECT 1
                        FROM DBO.CLIENTEJURIDICO
                        WHERE CEDULA_CLIENTE = @CEDULA
                    )
                    THROW 51132, 'El cliente tiene dos tipos.', 1;
            END;

        IF @TIPO_CLIENTE = 'JURIDICA'
            BEGIN
                IF
                    NOT EXISTS (
                        SELECT 1
                        FROM DBO.CLIENTEJURIDICO WITH (UPDLOCK, HOLDLOCK)
                        WHERE CEDULA_CLIENTE = @CEDULA
                    )
                    THROW 51131, 'El cliente juridico no existe.', 1;

                IF
                    EXISTS (
                        SELECT 1
                        FROM DBO.CLIENTEFISICO
                        WHERE CEDULA_CLIENTE = @CEDULA
                    )
                    THROW 51132, 'El cliente tiene dos tipos.', 1;
            END;

        UPDATE DBO.CLIENTE
        SET
            ID_DIRECCION = @ID_DIRECCION,
            TELEFONO = @TELEFONO,
            CORREO = @CORREO,
            FECHA_ACTUALIZACION = CONVERT(
                DATETIME2(0),
                SYSDATETIME()
            )
        WHERE CEDULA = @CEDULA;

        IF @TIPO_CLIENTE = 'FISICA'
            BEGIN
                UPDATE DBO.CLIENTEFISICO
                SET
                    NOMBRE = @NOMBRE,
                    PRIMER_APELLIDO = COALESCE(
                        @PRIMER_APELLIDO,
                        PRIMER_APELLIDO
                    ),
                    SEGUNDO_APELLIDO = COALESCE(
                        @SEGUNDO_APELLIDO,
                        SEGUNDO_APELLIDO
                    )
                WHERE CEDULA_CLIENTE = @CEDULA;
            END;

        IF @TIPO_CLIENTE = 'JURIDICA'
            BEGIN
                UPDATE DBO.CLIENTEJURIDICO
                SET
                    RAZON_SOCIAL = @RAZON_SOCIAL,
                    NOMBRE_COMERCIAL = COALESCE(
                        @NOMBRE_COMERCIAL,
                        NOMBRE_COMERCIAL
                    )
                WHERE CEDULA_CLIENTE = @CEDULA;
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
