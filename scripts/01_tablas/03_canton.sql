USE FacturacionSolucionesMagnificas;
GO

CREATE TABLE Canton (
    id_canton INT IDENTITY(1,1) NOT NULL,
    id_provincia INT NOT NULL,
    nombre VARCHAR(50) NOT NULL,

    CONSTRAINT PK_Canton
        PRIMARY KEY (id_canton),

    CONSTRAINT FK_Canton_Provincia
        FOREIGN KEY (id_provincia)
        REFERENCES Provincia(id_provincia),

    CONSTRAINT UQ_Canton_Provincia_Nombre
        UNIQUE (id_provincia, nombre)
);
GO