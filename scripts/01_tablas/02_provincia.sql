USE FacturacionSolucionesMagnificas;
GO

CREATE TABLE Provincia (
    id_provincia INT IDENTITY(1,1) NOT NULL,
    nombre VARCHAR(50) NOT NULL,

    CONSTRAINT PK_Provincia
        PRIMARY KEY (id_provincia),

    CONSTRAINT UQ_Provincia_Nombre
        UNIQUE (nombre)
);
GO