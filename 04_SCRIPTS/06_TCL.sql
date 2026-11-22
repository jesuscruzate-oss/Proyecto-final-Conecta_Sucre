/* ============================================================
   PROYECTO: CONECTASUCRE
   SCRIPT: 06_TCL.sql
   MOTOR: MySQL 8.0+ / MySQL 9.7
   BASE DE DATOS: conectasucre_final
   OBJETIVO: Demostrar control transaccional con START TRANSACTION,
             COMMIT, ROLLBACK y SAVEPOINT.

   IMPORTANTE:
   - Ejecutar el script completo en una sola pestaña/conexion.
   - Se utiliza una tabla TEMPORAL de demostracion.
   - La tabla temporal solo existe durante esta sesion.
   - No modifica ni elimina registros reales de ConectaSucre.
   ============================================================ */

USE conectasucre_final;

/* ============================================================
   1. PREPARACION DE TABLA TEMPORAL
   ============================================================ */

DROP TEMPORARY TABLE IF EXISTS tcl_pruebas;

CREATE TEMPORARY TABLE tcl_pruebas (
    id_prueba INT NOT NULL AUTO_INCREMENT,
    operacion VARCHAR(100) NOT NULL,
    valor DECIMAL(12,2) NOT NULL,
    estado VARCHAR(30) NOT NULL,
    PRIMARY KEY (id_prueba)
) ENGINE = InnoDB;

/* ============================================================
   2. TRANSACCION CON COMMIT
   Los dos registros se confirman de manera permanente dentro
   de la tabla temporal de esta sesion.
   ============================================================ */

START TRANSACTION;

INSERT INTO tcl_pruebas (operacion, valor, estado)
VALUES
    ('Pedido de prueba CS-001', 150000.00, 'REGISTRADO'),
    ('Pedido de prueba CS-002', 275000.00, 'REGISTRADO');

COMMIT;

-- Verificar que los registros confirmados permanecen.
SELECT
    'DESPUES DE COMMIT' AS momento,
    id_prueba,
    operacion,
    valor,
    estado
FROM tcl_pruebas
ORDER BY id_prueba;

/* ============================================================
   3. TRANSACCION CON SAVEPOINT Y ROLLBACK TO SAVEPOINT
   Se registra una operacion, se establece un punto de retorno,
   se simula un cambio y se revierte solamente ese cambio.
   ============================================================ */

START TRANSACTION;

INSERT INTO tcl_pruebas (operacion, valor, estado)
VALUES ('Pedido de prueba CS-003', 320000.00, 'REGISTRADO');

SAVEPOINT sp_antes_actualizacion;

UPDATE tcl_pruebas
SET estado = 'DESPACHADO',
    valor = 350000.00
WHERE operacion = 'Pedido de prueba CS-003';

-- Revertir el UPDATE, conservando el INSERT de CS-003.
ROLLBACK TO SAVEPOINT sp_antes_actualizacion;

-- Confirmar el INSERT que sigue vigente.
COMMIT;

-- CS-003 debe aparecer como REGISTRADO y con valor 320000.
SELECT
    'DESPUES DE ROLLBACK TO SAVEPOINT' AS momento,
    id_prueba,
    operacion,
    valor,
    estado
FROM tcl_pruebas
ORDER BY id_prueba;

/* ============================================================
   4. TRANSACCION CON ROLLBACK TOTAL
   El INSERT se revierte y no debe permanecer en la tabla.
   ============================================================ */

START TRANSACTION;

INSERT INTO tcl_pruebas (operacion, valor, estado)
VALUES ('Pedido de prueba CS-004', 410000.00, 'REGISTRADO');

-- Simular un error o una operacion que no debe confirmarse.
ROLLBACK;

-- CS-004 no debe aparecer en el resultado.
SELECT
    'DESPUES DE ROLLBACK TOTAL' AS momento,
    id_prueba,
    operacion,
    valor,
    estado
FROM tcl_pruebas
ORDER BY id_prueba;

/* ============================================================
   5. VALIDACION FINAL
   Resultado esperado:
   - 3 registros confirmados (CS-001, CS-002 y CS-003).
   - CS-003 conserva estado REGISTRADO y valor 320000.
   - CS-004 no existe porque fue revertido.
   ============================================================ */

SELECT
    COUNT(*) AS total_registros_confirmados,
    SUM(valor) AS valor_total_confirmado
FROM tcl_pruebas;

SELECT
    id_prueba,
    operacion,
    valor,
    estado
FROM tcl_pruebas
ORDER BY id_prueba;

/* ======================= FIN =============================== */
