USE FacturacionSolucionesMagnificas;
GO

CREATE TABLE Distrito (
    id_distrito INT IDENTITY(1,1) NOT NULL,
    id_canton INT NOT NULL,
    nombre VARCHAR(50) NOT NULL,

    CONSTRAINT PK_Distrito
        PRIMARY KEY (id_distrito),

    CONSTRAINT FK_Distrito_Canton
        FOREIGN KEY (id_canton)
        REFERENCES Canton(id_canton),

    CONSTRAINT UQ_Distrito_Canton_Nombre
        UNIQUE (id_canton, nombre)
);
GO