USE FacturacionSolucionesMagnificas;
GO

CREATE TABLE Empresa (
    cedula VARCHAR(20) NOT NULL,
    nombre_comercial VARCHAR(100) NOT NULL,
    razon_social VARCHAR(150) NOT NULL,
    id_direccion INT NOT NULL,
    telefono VARCHAR(20) NOT NULL,
    correo VARCHAR(100) NOT NULL,
    fecha_creacion DATETIME2(0) NOT NULL
        CONSTRAINT DF_Empresa_FechaCreacion
        DEFAULT SYSDATETIME(),
    activo BIT NOT NULL
        CONSTRAINT DF_Empresa_Activo
        DEFAULT 1,

    CONSTRAINT PK_Empresa
        PRIMARY KEY (cedula),

    CONSTRAINT FK_Empresa_Direccion
        FOREIGN KEY (id_direccion)
        REFERENCES Direccion(id_direccion)
);
GO