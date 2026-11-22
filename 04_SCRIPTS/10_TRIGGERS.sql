/* ============================================================
   PROYECTO: CONECTASUCRE
   SCRIPT: 10_TRIGGERS.sql
   MOTOR: MySQL 8.0 Community Edition
   BASE DE DATOS: conectasucre_final
   OBJETIVO: Automatizar validaciones, actualización de totales
             y auditoría de operaciones logísticas.

   TRIGGERS:
   1. trg_validar_despacho_bi
   2. trg_detalle_pedido_ai
   3. trg_detalle_pedido_au
   4. trg_detalle_pedido_ad
   5. trg_auditar_despacho_au

   NOTA:
   - Los triggers se ejecutan automáticamente ante INSERT,
     UPDATE o DELETE en las tablas correspondientes.
   - La creación de estos triggers no modifica los registros
     existentes; aplican a las operaciones futuras.
   - Se pueden ejecutar nuevamente porque primero eliminan
     los triggers con estos nombres, si ya existen.
   ============================================================ */

USE conectasucre_final;


/* ============================================================
   1. VALIDAR UN DESPACHO ANTES DE INSERTARLO
   Verifica que:
   - El vehículo exista y esté DISPONIBLE.
   - El conductor exista y esté DISPONIBLE.
   - La capacidad del vehículo soporte el peso del pedido.
   ============================================================ */

DROP TRIGGER IF EXISTS trg_validar_despacho_bi;

DELIMITER $$

CREATE TRIGGER trg_validar_despacho_bi
BEFORE INSERT ON despachos_asignaciones
FOR EACH ROW
BEGIN
    DECLARE v_capacidad DECIMAL(12,2) DEFAULT NULL;
    DECLARE v_estado_vehiculo VARCHAR(25) DEFAULT NULL;
    DECLARE v_estado_conductor VARCHAR(20) DEFAULT NULL;
    DECLARE v_peso_pedido DECIMAL(12,2) DEFAULT NULL;

    SELECT
        ve.capacidad_carga_kg,
        ve.estado_vehiculo,
        co.estado_conductor,
        pe.peso_total_kg
    INTO
        v_capacidad,
        v_estado_vehiculo,
        v_estado_conductor,
        v_peso_pedido
    FROM vehiculos AS ve
    INNER JOIN conductores AS co
        ON co.id_conductor = NEW.id_conductor
    INNER JOIN pedidos AS pe
        ON pe.id_pedido = NEW.id_pedido
    WHERE ve.id_vehiculo = NEW.id_vehiculo;

    IF v_capacidad IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT =
                'No fue posible validar el vehiculo, conductor o pedido';
    END IF;

    IF v_estado_vehiculo <> 'DISPONIBLE' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El vehiculo no esta disponible';
    END IF;

    IF v_estado_conductor <> 'DISPONIBLE' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El conductor no esta disponible';
    END IF;

    IF v_peso_pedido > v_capacidad THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT =
                'El peso del pedido supera la capacidad del vehiculo';
    END IF;
END$$

DELIMITER ;


/* ============================================================
   2. ACTUALIZAR TOTALES DEL PEDIDO DESPUES DE INSERTAR DETALLE
   Recalcula valor_total y peso_total_kg desde detalle_pedidos.
   ============================================================ */

DROP TRIGGER IF EXISTS trg_detalle_pedido_ai;

DELIMITER $$

CREATE TRIGGER trg_detalle_pedido_ai
AFTER INSERT ON detalle_pedidos
FOR EACH ROW
BEGIN
    UPDATE pedidos
    SET
        valor_total = valor_total + NEW.subtotal,
        peso_total_kg = peso_total_kg
            + (NEW.cantidad * NEW.peso_unitario_kg)
    WHERE id_pedido = NEW.id_pedido;
END$$

DELIMITER ;


/* ============================================================
   3. ACTUALIZAR TOTALES DESPUES DE MODIFICAR UN DETALLE
   Aplica solamente la diferencia entre los valores anteriores
   y los nuevos. Si cambia de pedido, ajusta ambos pedidos.
   ============================================================ */

DROP TRIGGER IF EXISTS trg_detalle_pedido_au;

DELIMITER $$

CREATE TRIGGER trg_detalle_pedido_au
AFTER UPDATE ON detalle_pedidos
FOR EACH ROW
BEGIN
    IF NEW.id_pedido = OLD.id_pedido THEN
        UPDATE pedidos
        SET
            valor_total = valor_total + (NEW.subtotal - OLD.subtotal),
            peso_total_kg = peso_total_kg
                + (
                    NEW.cantidad * NEW.peso_unitario_kg
                    - OLD.cantidad * OLD.peso_unitario_kg
                )
        WHERE id_pedido = NEW.id_pedido;
    ELSE
        -- Restar los valores del pedido anterior.
        UPDATE pedidos
        SET
            valor_total = valor_total - OLD.subtotal,
            peso_total_kg = peso_total_kg
                - (OLD.cantidad * OLD.peso_unitario_kg)
        WHERE id_pedido = OLD.id_pedido;

        -- Sumar los valores al nuevo pedido.
        UPDATE pedidos
        SET
            valor_total = valor_total + NEW.subtotal,
            peso_total_kg = peso_total_kg
                + (NEW.cantidad * NEW.peso_unitario_kg)
        WHERE id_pedido = NEW.id_pedido;
    END IF;
END$$

DELIMITER ;


/* ============================================================
   4. ACTUALIZAR TOTALES DESPUES DE ELIMINAR UN DETALLE
   Resta del pedido el valor y peso del detalle eliminado.
   ============================================================ */

DROP TRIGGER IF EXISTS trg_detalle_pedido_ad;

DELIMITER $$

CREATE TRIGGER trg_detalle_pedido_ad
AFTER DELETE ON detalle_pedidos
FOR EACH ROW
BEGIN
    UPDATE pedidos
    SET
        valor_total = valor_total - OLD.subtotal,
        peso_total_kg = peso_total_kg
            - (OLD.cantidad * OLD.peso_unitario_kg)
    WHERE id_pedido = OLD.id_pedido;
END$$

DELIMITER ;


/* ============================================================
   5. AUDITAR CAMBIOS EN EL ESTADO DE UN DESPACHO
   Cuando cambia estado_despacho, registra el cambio en
   auditoria_despachos con usuario, fecha y estados.
   ============================================================ */

DROP TRIGGER IF EXISTS trg_auditar_despacho_au;

DELIMITER $$

CREATE TRIGGER trg_auditar_despacho_au
AFTER UPDATE ON despachos_asignaciones
FOR EACH ROW
BEGIN
    IF NOT (OLD.estado_despacho <=> NEW.estado_despacho) THEN
        INSERT INTO auditoria_despachos (
            id_despacho,
            fecha_modificacion,
            usuario_bd,
            estado_anterior,
            estado_nuevo,
            observacion
        )
        VALUES (
            NEW.id_despacho,
            CURRENT_TIMESTAMP,
            CURRENT_USER(),
            OLD.estado_despacho,
            NEW.estado_despacho,
            'Cambio de estado registrado automaticamente por trigger'
        );
    END IF;
END$$

DELIMITER ;


/* ============================================================
   6. VERIFICAR TRIGGERS CREADOS
   Deben aparecer cinco registros.
   ============================================================ */

SELECT
    TRIGGER_NAME AS nombre_trigger,
    EVENT_MANIPULATION AS evento,
    EVENT_OBJECT_TABLE AS tabla,
    ACTION_TIMING AS momento,
    ACTION_STATEMENT AS accion
FROM information_schema.TRIGGERS
WHERE TRIGGER_SCHEMA = 'conectasucre_final'
ORDER BY EVENT_OBJECT_TABLE, EVENT_MANIPULATION, TRIGGER_NAME;


/* Resumen de cantidad de triggers del proyecto. */
SELECT
    COUNT(*) AS total_triggers
FROM information_schema.TRIGGERS
WHERE TRIGGER_SCHEMA = 'conectasucre_final';


/* ======================= FIN =============================== */
