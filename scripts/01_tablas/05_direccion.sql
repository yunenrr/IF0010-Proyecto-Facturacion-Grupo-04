USE FacturacionSolucionesMagnificas;
GO

CREATE TABLE Direccion (
    id_direccion INT IDENTITY(1,1) NOT NULL,
    id_distrito INT NOT NULL,
    senas_exactas VARCHAR(300) NOT NULL,

    CONSTRAINT PK_Direccion
        PRIMARY KEY (id_direccion),

    CONSTRAINT FK_Direccion_Distrito
        FOREIGN KEY (id_distrito)
        REFERENCES Distrito(id_distrito)
);
GO