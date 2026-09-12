USE FacturacionSolucionesMagnificas;
GO

CREATE TABLE Cliente (
    cedula VARCHAR(20) NOT NULL,
    nombre_razon_social VARCHAR(150) NOT NULL,
    id_direccion INT NOT NULL,
    telefono VARCHAR(20) NOT NULL,
    correo VARCHAR(100) NOT NULL,
    fecha_registro DATETIME2(0) NOT NULL
        CONSTRAINT DF_Cliente_FechaRegistro
        DEFAULT SYSDATETIME(),
    fecha_actualizacion DATETIME2(0) NOT NULL
        CONSTRAINT DF_Cliente_FechaActualizacion
        DEFAULT SYSDATETIME(),

    CONSTRAINT PK_Cliente
        PRIMARY KEY (cedula),

    CONSTRAINT FK_Cliente_Direccion
        FOREIGN KEY (id_direccion)
        REFERENCES Direccion(id_direccion)
);
GO