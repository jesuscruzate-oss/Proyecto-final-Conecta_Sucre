/* ============================================================
   PROYECTO: CONECTASUCRE
   SCRIPT: 09_PROCEDIMIENTOS.sql
   MOTOR: MySQL 8.0+ / MySQL 9.7
   BASE DE DATOS: conectasucre_final
   OBJETIVO: Crear procedimientos almacenados para consultar
             pedidos, actualizar estados y revisar despachos.

   IMPORTANTE:
   - Ejecutar conectado con una cuenta administradora.
   - Los procedimientos de consulta no modifican datos.
   - sp_actualizar_estado_pedido modifica el pedido y registra
     el cambio en el historial dentro de una transaccion.
   - Ese procedimiento controla su propia transaccion.
   ============================================================ */

USE conectasucre_final;

/* ============================================================
   1. CONSULTAR UN PEDIDO POR SU NUMERO
   Devuelve tres conjuntos de resultados:
   A) Datos generales del pedido.
   B) Detalle de productos.
   C) Despachos y entregas asociadas.
   ============================================================ */

DROP PROCEDURE IF EXISTS sp_consultar_pedido;

DELIMITER $$

CREATE PROCEDURE sp_consultar_pedido(
    IN p_numero_pedido VARCHAR(30)
)
SQL SECURITY INVOKER
BEGIN
    -- A. Datos generales del pedido.
    SELECT
        p.id_pedido,
        p.numero_pedido,
        p.fecha_pedido,
        p.fecha_entrega_prometida,
        p.estado_pedido,
        p.peso_total_kg,
        p.valor_total,
        c.nombre_comercial AS cliente,
        m.nombre_municipio AS municipio_destino,
        m.departamento
    FROM pedidos AS p
    INNER JOIN clientes AS c
        ON c.id_cliente = p.id_cliente
    INNER JOIN municipios AS m
        ON m.id_municipio = p.id_municipio_destino
    WHERE p.numero_pedido = p_numero_pedido;

    -- B. Productos incluidos en el pedido.
    SELECT
        p.numero_pedido,
        pr.codigo_producto,
        pr.nombre_producto,
        dp.cantidad,
        pr.unidad_medida,
        dp.precio_unitario,
        dp.peso_unitario_kg,
        dp.subtotal
    FROM pedidos AS p
    INNER JOIN detalle_pedidos AS dp
        ON dp.id_pedido = p.id_pedido
    INNER JOIN productos AS pr
        ON pr.id_producto = dp.id_producto
    WHERE p.numero_pedido = p_numero_pedido
    ORDER BY pr.nombre_producto;

    -- C. Despachos y entregas del pedido.
    SELECT
        p.numero_pedido,
        da.id_despacho,
        da.fecha_asignacion,
        da.fecha_salida,
        da.estado_despacho,
        e.fecha_entrega_real,
        e.estado_entrega,
        e.peso_entregado_kg,
        e.nombre_receptor
    FROM pedidos AS p
    INNER JOIN despachos_asignaciones AS da
        ON da.id_pedido = p.id_pedido
    LEFT JOIN entregas AS e
        ON e.id_despacho = da.id_despacho
    WHERE p.numero_pedido = p_numero_pedido
    ORDER BY da.fecha_asignacion;
END$$

DELIMITER ;


/* ============================================================
   2. ACTUALIZAR ESTADO DE UN PEDIDO
   Valida el pedido y el nuevo estado, actualiza pedidos e
   inserta el cambio en historial_estados_pedido.
   ============================================================ */

DROP PROCEDURE IF EXISTS sp_actualizar_estado_pedido;

DELIMITER $$

CREATE PROCEDURE sp_actualizar_estado_pedido(
    IN p_numero_pedido VARCHAR(30),
    IN p_nuevo_estado VARCHAR(25),
    IN p_usuario_bd VARCHAR(100),
    IN p_observacion VARCHAR(300)
)
SQL SECURITY INVOKER
BEGIN
    DECLARE v_id_pedido INT UNSIGNED DEFAULT NULL;
    DECLARE v_estado_anterior VARCHAR(25) DEFAULT NULL;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    IF p_nuevo_estado IS NULL OR p_nuevo_estado NOT IN (
        'PENDIENTE',
        'EN_PREPARACION',
        'EN_TRANSITO',
        'ENTREGADO',
        'CANCELADO'
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Estado de pedido no permitido';
    END IF;

    START TRANSACTION;

    SELECT id_pedido, estado_pedido
      INTO v_id_pedido, v_estado_anterior
    FROM pedidos
    WHERE numero_pedido = p_numero_pedido
    LIMIT 1
    FOR UPDATE;

    IF v_id_pedido IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'No existe el numero de pedido indicado';
    END IF;

    IF v_estado_anterior <> p_nuevo_estado THEN
        UPDATE pedidos
        SET estado_pedido = p_nuevo_estado
        WHERE id_pedido = v_id_pedido;

        INSERT INTO historial_estados_pedido (
            id_pedido,
            estado_anterior,
            estado_nuevo,
            fecha_cambio,
            usuario_bd,
            observacion
        )
        VALUES (
            v_id_pedido,
            v_estado_anterior,
            p_nuevo_estado,
            CURRENT_TIMESTAMP,
            COALESCE(p_usuario_bd, CURRENT_USER()),
            p_observacion
        );
    END IF;

    COMMIT;

    SELECT
        p.numero_pedido,
        v_estado_anterior AS estado_anterior,
        p.estado_pedido AS estado_actual,
        'Actualizacion procesada' AS resultado
    FROM pedidos AS p
    WHERE p.id_pedido = v_id_pedido;
END$$

DELIMITER ;


/* ============================================================
   3. CONSULTAR DESPACHOS POR ESTADO
   Ejemplos de estado: ASIGNADO, EN_TRANSITO, ENTREGADO,
   CANCELADO.
   ============================================================ */

DROP PROCEDURE IF EXISTS sp_consultar_despachos_estado;

DELIMITER $$

CREATE PROCEDURE sp_consultar_despachos_estado(
    IN p_estado_despacho VARCHAR(20)
)
SQL SECURITY INVOKER
BEGIN
    SELECT
        da.id_despacho,
        p.numero_pedido,
        c.nombre_comercial AS cliente,
        CONCAT(co.nombres, ' ', co.apellidos) AS conductor,
        v.placa,
        r.nombre_ruta,
        da.fecha_asignacion,
        da.fecha_salida,
        da.estado_despacho
    FROM despachos_asignaciones AS da
    INNER JOIN pedidos AS p
        ON p.id_pedido = da.id_pedido
    INNER JOIN clientes AS c
        ON c.id_cliente = p.id_cliente
    INNER JOIN conductores AS co
        ON co.id_conductor = da.id_conductor
    INNER JOIN vehiculos AS v
        ON v.id_vehiculo = da.id_vehiculo
    INNER JOIN rutas AS r
        ON r.id_ruta = da.id_ruta
    WHERE p_estado_despacho IS NULL
       OR da.estado_despacho = p_estado_despacho
    ORDER BY da.fecha_asignacion DESC;
END$$

DELIMITER ;


/* ============================================================
   4. RESUMEN DE PEDIDOS POR CLIENTE
   ============================================================ */

DROP PROCEDURE IF EXISTS sp_resumen_pedidos_cliente;

DELIMITER $$

CREATE PROCEDURE sp_resumen_pedidos_cliente(
    IN p_id_cliente INT UNSIGNED
)
SQL SECURITY INVOKER
BEGIN
    SELECT
        c.id_cliente,
        c.nombre_comercial,
        COUNT(p.id_pedido) AS cantidad_pedidos,
        COALESCE(SUM(p.valor_total), 0) AS valor_total_pedidos,
        COALESCE(AVG(p.valor_total), 0) AS valor_promedio_pedido,
        SUM(
            CASE
                WHEN p.estado_pedido = 'ENTREGADO' THEN 1
                ELSE 0
            END
        ) AS pedidos_entregados,
        SUM(
            CASE
                WHEN p.estado_pedido IN ('PENDIENTE', 'EN_PREPARACION')
                THEN 1
                ELSE 0
            END
        ) AS pedidos_pendientes_o_preparacion
    FROM clientes AS c
    LEFT JOIN pedidos AS p
        ON p.id_cliente = c.id_cliente
    WHERE p_id_cliente IS NULL
       OR c.id_cliente = p_id_cliente
    GROUP BY c.id_cliente, c.nombre_comercial
    ORDER BY valor_total_pedidos DESC;
END$$

DELIMITER ;


/* ============================================================
   5. VERIFICACION DE PROCEDIMIENTOS CREADOS
   ============================================================ */

SELECT
    ROUTINE_NAME AS nombre_procedimiento,
    ROUTINE_TYPE AS tipo_rutina,
    SECURITY_TYPE AS seguridad
FROM information_schema.ROUTINES
WHERE ROUTINE_SCHEMA = 'conectasucre_final'
  AND ROUTINE_TYPE = 'PROCEDURE'
ORDER BY ROUTINE_NAME;


/* ============================================================
   6. PRUEBAS DE EJECUCION DE PROCEDIMIENTOS
   Las siguientes llamadas son de consulta y no modifican datos.
   El numero de pedido se obtiene de la tabla para no inventarlo.
   ============================================================ */

SET @pedido_prueba = (
    SELECT numero_pedido
    FROM pedidos
    ORDER BY id_pedido
    LIMIT 1
);

CALL sp_consultar_pedido(@pedido_prueba);

CALL sp_consultar_despachos_estado('ENTREGADO');

CALL sp_resumen_pedidos_cliente(NULL);

/* ============================================================
   7. EJEMPLO CONTROLADO DE ACTUALIZACION
   NO se ejecuta automaticamente para no alterar el estado de
   los pedidos de prueba. Para demostrarlo, descomentar las
   siguientes lineas y usar un pedido que se pueda modificar:

   CALL sp_actualizar_estado_pedido(
       'NUMERO_PEDIDO_EXISTENTE',
       'EN_PREPARACION',
       'usuario_pruebas',
       'Cambio de estado para demostracion'
   );

   Luego consultar:
   SELECT * FROM historial_estados_pedido
   ORDER BY fecha_cambio DESC LIMIT 10;
   ============================================================ */

/* ======================= FIN =============================== */
