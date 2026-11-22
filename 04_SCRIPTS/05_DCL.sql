/* ============================================================
   PROYECTO: CONECTASUCRE
   SCRIPT: 05_DCL.sql
   MOTOR: MySQL 8.0+ / MySQL 9.7
   BASE DE DATOS: conectasucre_final
   OBJETIVO: Gestion de usuarios, roles y privilegios mediante
             CREATE USER, CREATE ROLE, GRANT y REVOKE.

   IMPORTANTE:
   - Ejecutar conectado con una cuenta administradora (por ejemplo root).
   - Los usuarios se crean para conexiones desde localhost.
   - Cambiar las contrasenas de ejemplo antes de usar en un entorno real.
   - No se otorgan privilegios globales ni de administracion del servidor.
   ============================================================ */

USE conectasucre_final;

/* ============================================================
   1. CREACION DE ROLES
   ============================================================ */

CREATE ROLE IF NOT EXISTS
    'rol_lectura'@'%',
    'rol_operaciones'@'%',
    'rol_auditoria'@'%';

/* ============================================================
   2. PRIVILEGIOS DEL ROL DE LECTURA
   Puede consultar la informacion del proyecto, sin modificarla.
   ============================================================ */

GRANT SELECT
ON conectasucre_final.*
TO 'rol_lectura'@'%';

/* ============================================================
   3. PRIVILEGIOS DEL ROL DE OPERACIONES
   Puede consultar y gestionar datos operativos.
   No puede eliminar tablas ni modificar la estructura.
   ============================================================ */

GRANT SELECT, INSERT, UPDATE
ON conectasucre_final.clientes
TO 'rol_operaciones'@'%';

GRANT SELECT, INSERT, UPDATE
ON conectasucre_final.productores
TO 'rol_operaciones'@'%';

GRANT SELECT, INSERT, UPDATE
ON conectasucre_final.productos
TO 'rol_operaciones'@'%';

GRANT SELECT, INSERT, UPDATE
ON conectasucre_final.pedidos
TO 'rol_operaciones'@'%';

GRANT SELECT, INSERT, UPDATE
ON conectasucre_final.detalle_pedidos
TO 'rol_operaciones'@'%';

GRANT SELECT, INSERT, UPDATE
ON conectasucre_final.despachos_asignaciones
TO 'rol_operaciones'@'%';

GRANT SELECT, INSERT, UPDATE
ON conectasucre_final.entregas
TO 'rol_operaciones'@'%';

GRANT SELECT, INSERT, UPDATE
ON conectasucre_final.novedades_relacionales
TO 'rol_operaciones'@'%';

GRANT SELECT
ON conectasucre_final.municipios
TO 'rol_operaciones'@'%';

GRANT SELECT
ON conectasucre_final.rutas
TO 'rol_operaciones'@'%';

GRANT SELECT
ON conectasucre_final.vehiculos
TO 'rol_operaciones'@'%';

GRANT SELECT
ON conectasucre_final.tipos_vehiculo
TO 'rol_operaciones'@'%';

GRANT SELECT
ON conectasucre_final.conductores
TO 'rol_operaciones'@'%';

/* ============================================================
   4. PRIVILEGIOS DEL ROL DE AUDITORIA
   Puede consultar los datos y revisar historiales y auditorias.
   No puede modificar la informacion.
   ============================================================ */

GRANT SELECT
ON conectasucre_final.*
TO 'rol_auditoria'@'%';

/* ============================================================
   5. CREACION DE USUARIOS DE PRUEBA
   Las contrasenas son demostrativas: cambiarlas antes de uso real.
   ============================================================ */

CREATE USER IF NOT EXISTS 'cs_lectura'@'localhost'
IDENTIFIED BY 'Cambiar_Lectura_2026!';

CREATE USER IF NOT EXISTS 'cs_operaciones'@'localhost'
IDENTIFIED BY 'Cambiar_Operaciones_2026!';

CREATE USER IF NOT EXISTS 'cs_auditoria'@'localhost'
IDENTIFIED BY 'Cambiar_Auditoria_2026!';

/* ============================================================
   6. ASIGNACION DE ROLES A USUARIOS
   ============================================================ */

GRANT 'rol_lectura'@'%' TO 'cs_lectura'@'localhost';
GRANT 'rol_operaciones'@'%' TO 'cs_operaciones'@'localhost';
GRANT 'rol_auditoria'@'%' TO 'cs_auditoria'@'localhost';

SET DEFAULT ROLE 'rol_lectura'@'%'
TO 'cs_lectura'@'localhost';

SET DEFAULT ROLE 'rol_operaciones'@'%'
TO 'cs_operaciones'@'localhost';

SET DEFAULT ROLE 'rol_auditoria'@'%'
TO 'cs_auditoria'@'localhost';

/* ============================================================
   7. DEMOSTRACION CONTROLADA DE REVOKE
   Se crea un rol temporal, se concede SELECT y luego se revoca.
   La operacion no altera los roles operativos anteriores.
   ============================================================ */

CREATE ROLE IF NOT EXISTS 'rol_prueba_revocacion'@'%';

GRANT SELECT
ON conectasucre_final.clientes
TO 'rol_prueba_revocacion'@'%';

-- Revocar el permiso concedido en la instruccion anterior.
REVOKE SELECT
ON conectasucre_final.clientes
FROM 'rol_prueba_revocacion'@'%';

/* ============================================================
   8. VERIFICACION DE PRIVILEGIOS
   ============================================================ */

SHOW GRANTS FOR 'rol_lectura'@'%';
SHOW GRANTS FOR 'rol_operaciones'@'%';
SHOW GRANTS FOR 'rol_auditoria'@'%';

SHOW GRANTS FOR 'cs_lectura'@'localhost';
SHOW GRANTS FOR 'cs_operaciones'@'localhost';
SHOW GRANTS FOR 'cs_auditoria'@'localhost';

SHOW GRANTS FOR 'rol_prueba_revocacion'@'%';

/* ============================================================
   9. CONSULTA DE ROLES Y USUARIOS CREADOS
   ============================================================ */

SELECT
    User AS usuario,
    Host AS origen
FROM mysql.user
WHERE User IN (
    'cs_lectura',
    'cs_operaciones',
    'cs_auditoria'
)
ORDER BY User;

/* ======================= FIN =============================== */
