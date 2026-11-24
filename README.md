# Sistema de facturación - Soluciones Magníficas

Proyecto del curso IF0010 - Bases de Datos II, Universidad de Costa Rica.

Grupo 04.

## Descripción general

El proyecto consiste en el desarrollo de una base de datos en SQL Server para gestionar la facturación de empresas. Permite administrar clientes físicos y jurídicos, direcciones, productos, servicios, facturas y sus respectivos detalles.

La base de datos utiliza procedimientos almacenados, funciones, vistas, índices y triggers de auditoría para facilitar las operaciones, mantener la integridad de los datos y registrar los cambios realizados. También cuenta con roles de seguridad, scripts de carga masiva y consultas para obtener información del sistema.

## Integrantes del grupo

| Nombre completo | Carné |
| --- | --- |
| Carlos Calvo García | C4D558 |
| Walter Johel Morales Pérez | C35336 |
| Joseph Rojas Ureña | C4J391 |
| Maikel Jesús Romero Solano | C4J450 |

## Requisitos de software

- Microsoft SQL Server 2019 o superior.
- SQL Server Management Studio (SSMS).
- PowerShell y `sqlcmd`, para la ejecución automática de los scripts.
- Git, para trabajar con el repositorio.

## Instrucciones de ejecución

Los archivos de la carpeta `scripts` deben ejecutarse en el siguiente orden:

1. `01_tablas`: creación de la base de datos y sus tablas.
2. `02_seguridad`: configuración de roles, usuarios y permisos.
3. `03_funciones`: creación de funciones.
4. `04_procedimientos`: creación de procedimientos almacenados.
5. `05_triggers`: creación de triggers de auditoría.
6. `06_cargaDatos`: carga de catálogos y generación de datos de prueba.
7. `07_indices`: creación de índices.
8. `08_vistas`: creación de vistas.
9. `09_demostraciones`: demostraciones del funcionamiento del sistema.
10. `10_consultas`: consultas SQL del proyecto.

Para ejecutar todos los scripts automáticamente, abrir PowerShell en la carpeta raíz del repositorio y ejecutar:

```powershell
.\utilitarios\ejecutar_scripts.ps1 -Server "localhost,1433" -Username "sa"
```

Ingresar la contraseña del usuario cuando el utilitario la solicite. El nombre del servidor y el usuario deben ajustarse a la configuración de SQL Server de cada equipo.

## Notas importantes y consideraciones especiales

- La base de datos se llama `FACTURACIONSOLUCIONESMAGNIFICAS`.
- Se recomienda ejecutar el proyecto en una instancia de desarrollo y realizar un respaldo si ya existe la base de datos, ya que los scripts de reconstrucción eliminan tablas y datos existentes.
- Los triggers deben crearse antes de la carga de datos para que las operaciones queden registradas en la tabla de auditoría.
- La carga masiva requiere tiempo y espacio de almacenamiento suficientes.
- Si PowerShell bloquea la ejecución del utilitario, se puede habilitar temporalmente la ejecución en la sesión actual mediante `Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass`, después de verificar que el script es de confianza.
- Si la versión instalada de `sqlcmd` no reconoce la opción `-f`, se debe utilizar una versión compatible o retirar `-f 'i:65001'` del utilitario cuando se utilice la versión Go con archivos UTF-8.
- El repositorio cuenta con un flujo de GitHub Actions para validar la calidad y ejecución de los scripts SQL.
- El diagrama entidad-relación y el estándar de nomenclatura se encuentran en las carpetas `diagrama_ER` y `estandar_nomenclatura`, respectivamente, y deben mantenerse actualizados en formato PDF.
