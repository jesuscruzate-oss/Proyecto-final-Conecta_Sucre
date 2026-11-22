/* ============================================================
   PROYECTO: CONECTASUCRE
   SCRIPT: 08_FUNCIONES.sql
   MOTOR: MySQL 8.0+ / MySQL 9.7
   BASE DE DATOS: conectasucre_final
   OBJETIVO: Crear funciones almacenadas para calculos y consultas
             reutilizables del proceso comercial y logistico.

   IMPORTANTE:
   - Ejecutar conectado con una cuenta administradora.
   - Este script elimina y recrea SOLO las funciones con estos
     nombres para permitir ejecutarlo nuevamente.
   - No modifica los registros de las tablas del proyecto.
   ============================================================ */

USE conectasucre_final;

/* ============================================================
   1. FUNCION: CALCULAR SUBTOTAL
   Multiplica cantidad por precio unitario.
   ============================================================ */

DROP FUNCTION IF EXISTS fn_calcular_subtotal;

DELIMITER $$

CREATE FUNCTION fn_calcular_subtotal(
    p_cantidad DECIMAL(12,3),
    p_precio_unitario DECIMAL(14,2)
)
RETURNS DECIMAL(16,2)
DETERMINISTIC
NO SQL
BEGIN
    RETURN ROUND(COALESCE(p_cantidad, 0) *
                 COALESCE(p_precio_unitario, 0), 2);
END$$

DELIMITER ;


/* ============================================================
   2. FUNCION: CALCULAR PESO DE UNA LINEA
   Multiplica cantidad por peso unitario.
   ============================================================ */

DROP FUNCTION IF EXISTS fn_calcular_peso_linea;

DELIMITER $$

CREATE FUNCTION fn_calcular_peso_linea(
    p_cantidad DECIMAL(12,3),
    p_peso_unitario_kg DECIMAL(10,3)
)
RETURNS DECIMAL(16,3)
DETERMINISTIC
NO SQL
BEGIN
    RETURN ROUND(COALESCE(p_cantidad, 0) *
                 COALESCE(p_peso_unitario_kg, 0), 3);
END$$

DELIMITER ;


/* ============================================================
   3. FUNCION: TOTAL CALCULADO DE UN PEDIDO
   Suma los subtotales de sus detalles.
   ============================================================ */

DROP FUNCTION IF EXISTS fn_total_pedido;

DELIMITER $$

CREATE FUNCTION fn_total_pedido(
    p_id_pedido INT UNSIGNED
)
RETURNS DECIMAL(16,2)
READS SQL DATA
BEGIN
    DECLARE v_total DECIMAL(16,2) DEFAULT 0;

    SELECT COALESCE(SUM(subtotal), 0)
      INTO v_total
    FROM detalle_pedidos
    WHERE id_pedido = p_id_pedido;

    RETURN v_total;
END$$

DELIMITER ;


/* ============================================================
   4. FUNCION: PESO CALCULADO DE UN PEDIDO
   Suma cantidad por peso unitario de cada detalle.
   ============================================================ */

DROP FUNCTION IF EXISTS fn_peso_pedido;

DELIMITER $$

CREATE FUNCTION fn_peso_pedido(
    p_id_pedido INT UNSIGNED
)
RETURNS DECIMAL(16,3)
READS SQL DATA
BEGIN
    DECLARE v_peso DECIMAL(16,3) DEFAULT 0;

    SELECT COALESCE(SUM(cantidad * peso_unitario_kg), 0)
      INTO v_peso
    FROM detalle_pedidos
    WHERE id_pedido = p_id_pedido;

    RETURN v_peso;
END$$

DELIMITER ;


/* ============================================================
   5. FUNCION: CANTIDAD DE DESPACHOS DE UN PEDIDO
   ============================================================ */

DROP FUNCTION IF EXISTS fn_cantidad_despachos_pedido;

DELIMITER $$

CREATE FUNCTION fn_cantidad_despachos_pedido(
    p_id_pedido INT UNSIGNED
)
RETURNS INT
READS SQL DATA
BEGIN
    DECLARE v_cantidad INT DEFAULT 0;

    SELECT COUNT(*)
      INTO v_cantidad
    FROM despachos_asignaciones
    WHERE id_pedido = p_id_pedido;

    RETURN v_cantidad;
END$$

DELIMITER ;


/* ============================================================
   6. FUNCION: DIAS DE DIFERENCIA ENTRE FECHAS
   Devuelve cero si la entrega fue a tiempo o anticipada.
   Devuelve dias de retraso si la fecha real supera la prometida.
   ============================================================ */

DROP FUNCTION IF EXISTS fn_dias_retraso;

DELIMITER $$

CREATE FUNCTION fn_dias_retraso(
    p_fecha_prometida DATETIME,
    p_fecha_real DATETIME
)
RETURNS INT
DETERMINISTIC
NO SQL
BEGIN
    IF p_fecha_prometida IS NULL OR p_fecha_real IS NULL THEN
        RETURN NULL;
    END IF;

    RETURN GREATEST(DATEDIFF(p_fecha_real, p_fecha_prometida), 0);
END$$

DELIMITER ;


/* ============================================================
   7. VERIFICACION DE FUNCIONES CREADAS
   ============================================================ */

SELECT
    ROUTINE_NAME AS nombre_funcion,
    DATA_TYPE AS tipo_retorno,
    ROUTINE_TYPE AS tipo_rutina
FROM information_schema.ROUTINES
WHERE ROUTINE_SCHEMA = 'conectasucre_final'
  AND ROUTINE_TYPE = 'FUNCTION'
ORDER BY ROUTINE_NAME;


/* ============================================================
   8. PRUEBAS DE FUNCIONES ESCALARES
   ============================================================ */

SELECT
    fn_calcular_subtotal(3, 12500.50) AS subtotal_prueba,
    fn_calcular_peso_linea(3, 2.250) AS peso_prueba,
    fn_dias_retraso(
        '2026-01-10 12:00:00',
        '2026-01-13 09:00:00'
    ) AS dias_retraso_prueba;


/* ============================================================
   9. PRUEBAS CON DATOS DEL PROYECTO
   Se toma el primer pedido existente.
   ============================================================ */

SELECT
    p.id_pedido,
    p.numero_pedido,
    fn_total_pedido(p.id_pedido) AS total_calculado_detalles,
    fn_peso_pedido(p.id_pedido) AS peso_calculado_detalles,
    fn_cantidad_despachos_pedido(p.id_pedido) AS cantidad_despachos
FROM pedidos AS p
ORDER BY p.id_pedido
LIMIT 10;

/* ======================= FIN =============================== */
