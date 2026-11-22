-- CONECTASUCRE | COMPONENTE 13.06
-- Migracion de 6 funciones y 4 procedimientos MySQL a PostgreSQL 17.
-- Fuentes: CSV_EE4.csv, 08_FUNCIONES.sql, 09_PROCEDIMIENTOS.sql.
-- Ejecutar SOLO en la base conectasucre_final de PostgreSQL.
-- NO modifica datos existentes durante la instalacion; crea/reemplaza rutinas.
-- IMPORTANTE: los procedimientos que en MySQL retornaban filas ahora utilizan
-- cursores de PostgreSQL; los cursores deben consultarse dentro de BEGIN/COMMIT.
-- El procedimiento de actualizacion NO ejecuta COMMIT interno: el llamador
-- controla la transaccion. Revisar tambien los triggers al probar escrituras.

BEGIN;

-- SECCION A. FUNCIONES: conversion de tipos y expresiones MySQL -> PG.
CREATE OR REPLACE FUNCTION public.fn_calcular_subtotal(
    p_cantidad NUMERIC(12,3), p_precio_unitario NUMERIC(14,2)
) RETURNS NUMERIC(16,2)
LANGUAGE sql IMMUTABLE AS $fn$
    SELECT ROUND(COALESCE(p_cantidad, 0) * COALESCE(p_precio_unitario, 0), 2)::NUMERIC(16,2);
$fn$;

CREATE OR REPLACE FUNCTION public.fn_calcular_peso_linea(
    p_cantidad NUMERIC(12,3), p_peso_unitario_kg NUMERIC(10,3)
) RETURNS NUMERIC(16,3)
LANGUAGE sql IMMUTABLE AS $fn$
    SELECT ROUND(COALESCE(p_cantidad, 0) * COALESCE(p_peso_unitario_kg, 0), 3)::NUMERIC(16,3);
$fn$;

CREATE OR REPLACE FUNCTION public.fn_total_pedido(p_id_pedido BIGINT)
RETURNS NUMERIC(16,2)
LANGUAGE sql STABLE AS $fn$
    SELECT COALESCE(SUM(dp.subtotal),0)::NUMERIC(16,2)
    FROM public.detalle_pedidos dp WHERE dp.id_pedido = p_id_pedido;
$fn$;

CREATE OR REPLACE FUNCTION public.fn_peso_pedido(p_id_pedido BIGINT)
RETURNS NUMERIC(16,3)
LANGUAGE sql STABLE AS $fn$
    SELECT COALESCE(SUM(dp.cantidad * dp.peso_unitario_kg),0)::NUMERIC(16,3)
    FROM public.detalle_pedidos dp WHERE dp.id_pedido = p_id_pedido;
$fn$;

CREATE OR REPLACE FUNCTION public.fn_cantidad_despachos_pedido(p_id_pedido BIGINT)
RETURNS INTEGER
LANGUAGE sql STABLE AS $fn$
    SELECT COUNT(*)::INTEGER FROM public.despachos_asignaciones da
    WHERE da.id_pedido = p_id_pedido;
$fn$;

CREATE OR REPLACE FUNCTION public.fn_dias_retraso(
    p_fecha_prometida TIMESTAMP WITHOUT TIME ZONE,
    p_fecha_real TIMESTAMP WITHOUT TIME ZONE
) RETURNS INTEGER
LANGUAGE sql IMMUTABLE AS $fn$
    -- MySQL DATEDIFF ignora horas y compara solo fechas.
    SELECT CASE WHEN p_fecha_prometida IS NULL OR p_fecha_real IS NULL
        THEN NULL
        ELSE GREATEST(p_fecha_real::date - p_fecha_prometida::date, 0)
    END;
$fn$;

-- SECCION B. PROCEDIMIENTOS DE CONSULTA: salidas por REF CURSOR.
-- Se deben llamar con cursores nombrados dentro de una transaccion:
-- BEGIN;
-- CALL public.sp_consultar_pedido('CS-2026-00001', 'general', 'items', 'envios');
-- FETCH ALL FROM general;
-- FETCH ALL FROM items;
-- FETCH ALL FROM envios;
-- COMMIT;
CREATE OR REPLACE PROCEDURE public.sp_consultar_pedido(
    IN p_numero_pedido VARCHAR(30),
    INOUT p_cursor_general REFCURSOR,
    INOUT p_cursor_detalle REFCURSOR,
    INOUT p_cursor_despachos REFCURSOR
) LANGUAGE plpgsql AS $proc$
BEGIN
    OPEN p_cursor_general FOR
        SELECT p.id_pedido,p.numero_pedido,p.fecha_pedido,p.fecha_entrega_prometida,
               p.estado_pedido,p.peso_total_kg,p.valor_total,
               c.nombre_comercial AS cliente,m.nombre_municipio AS municipio_destino,m.departamento
        FROM public.pedidos p
        JOIN public.clientes c ON c.id_cliente=p.id_cliente
        JOIN public.municipios m ON m.id_municipio=p.id_municipio_destino
        WHERE p.numero_pedido=p_numero_pedido;

    OPEN p_cursor_detalle FOR
        SELECT p.numero_pedido,pr.codigo_producto,pr.nombre_producto,
               dp.cantidad,pr.unidad_medida,dp.precio_unitario,dp.peso_unitario_kg,dp.subtotal
        FROM public.pedidos p
        JOIN public.detalle_pedidos dp ON dp.id_pedido=p.id_pedido
        JOIN public.productos pr ON pr.id_producto=dp.id_producto
        WHERE p.numero_pedido=p_numero_pedido
        ORDER BY pr.nombre_producto;

    OPEN p_cursor_despachos FOR
        SELECT p.numero_pedido,da.id_despacho,da.fecha_asignacion,
               da.fecha_salida,da.estado_despacho,e.fecha_entrega_real,
               e.estado_entrega,e.peso_entregado_kg,e.nombre_receptor
        FROM public.pedidos p
        JOIN public.despachos_asignaciones da ON da.id_pedido=p.id_pedido
        LEFT JOIN public.entregas e ON e.id_despacho=da.id_despacho
        WHERE p.numero_pedido=p_numero_pedido
        ORDER BY da.fecha_asignacion;
END;
$proc$;

CREATE OR REPLACE PROCEDURE public.sp_consultar_despachos_estado(
    IN p_estado_despacho VARCHAR(20), INOUT p_cursor REFCURSOR
) LANGUAGE plpgsql AS $proc$
BEGIN
    OPEN p_cursor FOR
        SELECT da.id_despacho,p.numero_pedido,c.nombre_comercial AS cliente,
               CONCAT(co.nombres,' ',co.apellidos) AS conductor,
               v.placa,r.nombre_ruta,da.fecha_asignacion,da.fecha_salida,da.estado_despacho
        FROM public.despachos_asignaciones da
        JOIN public.pedidos p ON p.id_pedido=da.id_pedido
        JOIN public.clientes c ON c.id_cliente=p.id_cliente
        JOIN public.conductores co ON co.id_conductor=da.id_conductor
        JOIN public.vehiculos v ON v.id_vehiculo=da.id_vehiculo
        JOIN public.rutas r ON r.id_ruta=da.id_ruta
        WHERE p_estado_despacho IS NULL OR da.estado_despacho=p_estado_despacho
        ORDER BY da.fecha_asignacion DESC;
END;
$proc$;

CREATE OR REPLACE PROCEDURE public.sp_resumen_pedidos_cliente(
    IN p_id_cliente BIGINT, INOUT p_cursor REFCURSOR
) LANGUAGE plpgsql AS $proc$
BEGIN
    OPEN p_cursor FOR
        SELECT c.id_cliente,c.nombre_comercial,
               COUNT(p.id_pedido) AS cantidad_pedidos,
               COALESCE(SUM(p.valor_total),0) AS valor_total_pedidos,
               COALESCE(AVG(p.valor_total),0) AS valor_promedio_pedido,
               SUM(CASE WHEN p.estado_pedido='ENTREGADO' THEN 1 ELSE 0 END) AS pedidos_entregados,
               SUM(CASE WHEN p.estado_pedido IN ('PENDIENTE','EN_PREPARACION') THEN 1 ELSE 0 END)
                   AS pedidos_pendientes_o_preparacion
        FROM public.clientes c
        LEFT JOIN public.pedidos p ON p.id_cliente=c.id_cliente
        WHERE p_id_cliente IS NULL OR c.id_cliente=p_id_cliente
        GROUP BY c.id_cliente,c.nombre_comercial
        ORDER BY valor_total_pedidos DESC;
END;
$proc$;

-- PROCEDIMIENTO CON ESCRITURA: actualizar estado e insertar historial.
-- A diferencia de MySQL, el CALL se controla con transaccion exterior.
-- No ejecutar sobre datos migrados para validar sin usar ROLLBACK.
CREATE OR REPLACE PROCEDURE public.sp_actualizar_estado_pedido(
    IN p_numero_pedido VARCHAR(30),
    IN p_nuevo_estado VARCHAR(25),
    IN p_usuario_bd VARCHAR(100),
    IN p_observacion VARCHAR(300)
) LANGUAGE plpgsql AS $proc$
DECLARE
    v_id_pedido BIGINT;
    v_estado_anterior VARCHAR(25);
BEGIN
    IF p_nuevo_estado IS NULL OR p_nuevo_estado NOT IN (
        'PENDIENTE','EN_PREPARACION','EN_TRANSITO','ENTREGADO','CANCELADO'
    ) THEN
        RAISE EXCEPTION 'Estado de pedido no permitido' USING ERRCODE='22023';
    END IF;

    SELECT p.id_pedido,p.estado_pedido
    INTO v_id_pedido,v_estado_anterior
    FROM public.pedidos p WHERE p.numero_pedido=p_numero_pedido
    LIMIT 1 FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'No existe el numero de pedido indicado' USING ERRCODE='P0002';
    END IF;

    IF v_estado_anterior IS DISTINCT FROM p_nuevo_estado THEN
        UPDATE public.pedidos SET estado_pedido=p_nuevo_estado
        WHERE id_pedido=v_id_pedido;

        INSERT INTO public.historial_estados_pedido
        (id_pedido,estado_anterior,estado_nuevo,fecha_cambio,usuario_bd,observacion)
        VALUES (v_id_pedido,v_estado_anterior,p_nuevo_estado,CURRENT_TIMESTAMP,
                COALESCE(p_usuario_bd,CURRENT_USER),p_observacion);
    END IF;
    RAISE NOTICE 'Pedido %, estado anterior %, estado actual %, actualizacion procesada',
        p_numero_pedido,v_estado_anterior,p_nuevo_estado;
END;
$proc$;

COMMIT;

-- VERIFICACION DEL CATALOGO: esperados 6 FUNCTION y 4 PROCEDURE.
SELECT routine_type AS tipo, COUNT(*) AS total
FROM information_schema.routines
WHERE routine_schema='public' AND routine_name LIKE 'fn_%'
GROUP BY routine_type
UNION ALL
SELECT routine_type, COUNT(*) FROM information_schema.routines
WHERE routine_schema='public' AND routine_name LIKE 'sp_%'
GROUP BY routine_type
ORDER BY tipo;

-- PRUEBAS SIN ESCRITURA (resultado de la ultima SELECT visible en Data Output).
SELECT public.fn_calcular_subtotal(3::numeric,12500.50::numeric) AS subtotal_prueba,
       public.fn_calcular_peso_linea(2::numeric,1.250::numeric) AS peso_prueba,
       public.fn_total_pedido(1) AS total_pedido_1,
       public.fn_peso_pedido(1) AS peso_pedido_1,
       public.fn_cantidad_despachos_pedido(1) AS despachos_pedido_1,
       public.fn_dias_retraso('2026-01-01'::timestamp,'2026-01-04'::timestamp)
           AS dias_retraso_prueba;
