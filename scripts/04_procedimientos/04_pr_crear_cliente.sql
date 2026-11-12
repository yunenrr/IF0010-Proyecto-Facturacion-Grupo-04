USE FACTURACIONSOLUCIONESMAGNIFICAS;
GO

IF
    EXISTS (
        SELECT 1
        FROM SYS.OBJECTS
        WHERE
            NAME = 'PR_CREAR_CLIENTE'
            AND TYPE = 'P'
    )
    BEGIN
        DROP PROCEDURE DBO.PR_CREAR_CLIENTE;
    END
GO

CREATE PROCEDURE DBO.PR_CREAR_CLIENTE
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
            THROW 51101, 'La cedula es obligatoria.', 1;

        IF
            NULLIF(@TIPO_CLIENTE, '') IS NULL
            OR @TIPO_CLIENTE NOT IN ('FISICA', 'JURIDICA')
            THROW 51102, 'El tipo de cliente no es valido.', 1;

        IF
            NOT EXISTS (
                SELECT 1
                FROM DBO.DIRECCION
                WHERE ID_DIRECCION = @ID_DIRECCION
            )
            THROW 51104, 'La direccion no existe.', 1;

        IF
            @TIPO_CLIENTE = 'FISICA'
            AND NULLIF(@NOMBRE, '') IS NULL
            THROW 51105, 'El nombre es obligatorio.', 1;

        IF
            @TIPO_CLIENTE = 'JURIDICA'
            AND NULLIF(@RAZON_SOCIAL, '') IS NULL
            THROW 51106, 'La razon social es obligatoria.', 1;

        IF @TIPO_CLIENTE = 'FISICA' AND @PRIMER_APELLIDO IS NULL
            THROW 51110, 'El primer apellido es obligatorio.', 1;

        IF @TIPO_CLIENTE = 'FISICA' AND @SEGUNDO_APELLIDO IS NULL
            THROW 51111, 'El segundo apellido es obligatorio.', 1;

        IF @TIPO_CLIENTE = 'JURIDICA' AND @NOMBRE_COMERCIAL IS NULL
            THROW 51112, 'El nombre comercial es obligatorio.', 1;

        IF NULLIF(@TELEFONO, '') IS NULL
            THROW 51107, 'El telefono es obligatorio.', 1;

        IF NULLIF(@CORREO, '') IS NULL
            THROW 51108, 'El correo es obligatorio.', 1;

        IF
            EXISTS (
                SELECT 1
                FROM DBO.CLIENTE
                WHERE CEDULA = @CEDULA
            )
            THROW 51109, 'Ya existe un cliente con esa cedula.', 1;

        BEGIN TRANSACTION;

        INSERT INTO DBO.CLIENTE (
            CEDULA,
            ID_DIRECCION,
            TELEFONO,
            CORREO,
            FECHA_REGISTRO,
            FECHA_ACTUALIZACION
        )
        VALUES (
            @CEDULA,
            @ID_DIRECCION,
            @TELEFONO,
            @CORREO,
            CONVERT(DATETIME2(0), SYSDATETIME()),
            CONVERT(DATETIME2(0), SYSDATETIME())
        );

        IF @TIPO_CLIENTE = 'FISICA'
            BEGIN
                INSERT INTO DBO.CLIENTEFISICO (
                    CEDULA_CLIENTE,
                    NOMBRE,
                    PRIMER_APELLIDO,
                    SEGUNDO_APELLIDO
                )
                VALUES (
                    @CEDULA,
                    @NOMBRE,
                    @PRIMER_APELLIDO,
                    @SEGUNDO_APELLIDO
                );
            END;

        IF @TIPO_CLIENTE = 'JURIDICA'
            BEGIN
                INSERT INTO DBO.CLIENTEJURIDICO (
                    CEDULA_CLIENTE,
                    RAZON_SOCIAL,
                    NOMBRE_COMERCIAL
                )
                VALUES (
                    @CEDULA,
                    @RAZON_SOCIAL,
                    @NOMBRE_COMERCIAL
                );
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
