USE FACTURACIONSOLUCIONESMAGNIFICAS;
GO

IF
    EXISTS (
        SELECT 1
        FROM SYS.OBJECTS
        WHERE
            NAME = 'FN_INFORMACION_CLIENTE'
            AND TYPE = 'IF'
    )
    BEGIN
        DROP FUNCTION DBO.FN_INFORMACION_CLIENTE;
    END
GO

CREATE FUNCTION DBO.FN_INFORMACION_CLIENTE(
    @CEDULA VARCHAR(20)
)
RETURNS TABLE
AS
RETURN (
    SELECT
        C.CEDULA,
        CF.NOMBRE,
        CJ.RAZON_SOCIAL,
        D.SENAS_EXACTAS,
        C.FECHA_REGISTRO,
        C.FECHA_ACTUALIZACION,
        CASE
            WHEN CF.CEDULA_CLIENTE IS NOT NULL THEN 'FISICA'
            WHEN CJ.CEDULA_CLIENTE IS NOT NULL THEN 'JURIDICA'
        END AS TIPO_CLIENTE,
        CASE
            WHEN
                IS_MEMBER('ROL_ADMINISTRATIVO') = 1
                OR IS_MEMBER('DB_OWNER') = 1
                OR USER_NAME() = 'DBO'
                THEN C.TELEFONO
            WHEN IS_MEMBER('ROL_OPERATIVO') = 1
                THEN
                    CASE
                        WHEN LEN(C.TELEFONO) > 4
                            THEN CONCAT(
                                REPLICATE(
                                    '*',
                                    LEN(C.TELEFONO) - 4
                                ),
                                RIGHT(
                                    C.TELEFONO,
                                    4
                                )
                            )
                        ELSE REPLICATE(
                            '*',
                            LEN(C.TELEFONO)
                        )
                    END
        END AS TELEFONO,
        CASE
            WHEN
                IS_MEMBER('ROL_ADMINISTRATIVO') = 1
                OR IS_MEMBER('DB_OWNER') = 1
                OR USER_NAME() = 'DBO'
                THEN C.CORREO
            WHEN IS_MEMBER('ROL_OPERATIVO') = 1
                THEN
                    CASE
                        WHEN CHARINDEX('@', C.CORREO) > 1
                            THEN CONCAT(
                                LEFT(
                                    C.CORREO,
                                    1
                                ),
                                '***',
                                SUBSTRING(
                                    C.CORREO,
                                    CHARINDEX(
                                        '@',
                                        C.CORREO
                                    ),
                                    LEN(C.CORREO)
                                )
                            )
                        ELSE '***'
                    END
        END AS CORREO
    FROM DBO.CLIENTE AS C
    INNER JOIN DBO.DIRECCION AS D
        ON C.ID_DIRECCION = D.ID_DIRECCION
    LEFT JOIN DBO.CLIENTEFISICO AS CF
        ON C.CEDULA = CF.CEDULA_CLIENTE
    LEFT JOIN DBO.CLIENTEJURIDICO AS CJ
        ON C.CEDULA = CJ.CEDULA_CLIENTE
    WHERE
        C.CEDULA = TRIM(@CEDULA)
        AND (
            IS_MEMBER('ROL_ADMINISTRATIVO') = 1
            OR IS_MEMBER('ROL_OPERATIVO') = 1
            OR IS_MEMBER('DB_OWNER') = 1
            OR USER_NAME() = 'DBO'
        )
);
GO

GRANT SELECT
ON DBO.FN_INFORMACION_CLIENTE
TO ROL_ADMINISTRATIVO;
GO

GRANT SELECT
ON DBO.FN_INFORMACION_CLIENTE
TO ROL_OPERATIVO;
GO

GRANT SELECT
ON DBO.FN_INFORMACION_CLIENTE
TO USUARIO_SIN_ROL;
GO
