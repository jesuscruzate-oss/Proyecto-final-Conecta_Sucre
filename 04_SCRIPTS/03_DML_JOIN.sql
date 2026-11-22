/* ============================================================
   PROYECTO: CONECTASUCRE
   SCRIPT: 03_DML_JOIN.sql
   MOTOR: MySQL 8.0+ / MySQL 9.7
   BASE DE DATOS: conectasucre_final
   OBJETIVO: Consultas JOIN basicas, intermedias y avanzadas.
   ============================================================ */

USE conectasucre_final;

/* ============================================================
   A. CONSULTAS BASICAS
   ============================================================ */

-- 1. Clientes con el municipio donde estan registrados.
SELECT
    c.id_cliente,
    c.nombre_comercial,
    c.nombre_contacto,
    c.telefono,
    m.nombre_municipio,
    m.departamento
FROM clientes AS c
INNER JOIN municipios AS m
    ON c.id_municipio = m.id_municipio
ORDER BY m.nombre_municipio, c.nombre_comercial;


-- 2. Productores con su municipio.
SELECT
    p.id_productor,
    p.nombre_productor,
    p.numero_documento,
    p.telefono,
    m.nombre_municipio
FROM productores AS p
INNER JOIN municipios AS m
    ON p.id_municipio = m.id_municipio
ORDER BY p.nombre_productor;


-- 3. Catalogo de productos con el productor que los ofrece.
SELECT
    pr.id_producto,
    pr.codigo_producto,
    pr.nombre_producto,
    pr.unidad_medida,
    pr.peso_unitario_kg,
    pr.precio_unitario,
    po.nombre_productor
FROM productos AS pr
INNER JOIN productores AS po
    ON pr.id_productor = po.id_productor
ORDER BY po.nombre_productor, pr.nombre_producto;


/* ============================================================
   B. CONSULTAS INTERMEDIAS
   ============================================================ */

-- 4. Pedidos con cliente y municipio de destino.
SELECT
    pe.numero_pedido,
    pe.fecha_pedido,
    pe.fecha_entrega_prometida,
    pe.estado_pedido,
    pe.valor_total,
    c.nombre_comercial AS cliente,
    m.nombre_municipio AS municipio_destino
FROM pedidos AS pe
INNER JOIN clientes AS c
    ON pe.id_cliente = c.id_cliente
INNER JOIN municipios AS m
    ON pe.id_municipio_destino = m.id_municipio
ORDER BY pe.fecha_pedido DESC;


-- 5. Detalle de cada pedido: producto, productor, cantidad y subtotal.
SELECT
    pe.numero_pedido,
    pr.nombre_producto,
    po.nombre_productor,
    dp.cantidad,
    dp.precio_unitario,
    dp.subtotal
FROM detalle_pedidos AS dp
INNER JOIN pedidos AS pe
    ON dp.id_pedido = pe.id_pedido
INNER JOIN productos AS pr
    ON dp.id_producto = pr.id_producto
INNER JOIN productores AS po
    ON pr.id_productor = po.id_productor
ORDER BY pe.numero_pedido, pr.nombre_producto;


-- 6. Despachos con pedido, cliente, conductor, vehiculo y ruta.
SELECT
    da.id_despacho,
    pe.numero_pedido,
    c.nombre_comercial AS cliente,
    CONCAT(co.nombres, ' ', co.apellidos) AS conductor,
    v.placa,
    tv.nombre_tipo AS tipo_vehiculo,
    r.nombre_ruta,
    da.fecha_asignacion,
    da.fecha_salida,
    da.estado_despacho
FROM despachos_asignaciones AS da
INNER JOIN pedidos AS pe
    ON da.id_pedido = pe.id_pedido
INNER JOIN clientes AS c
    ON pe.id_cliente = c.id_cliente
INNER JOIN conductores AS co
    ON da.id_conductor = co.id_conductor
INNER JOIN vehiculos AS v
    ON da.id_vehiculo = v.id_vehiculo
INNER JOIN tipos_vehiculo AS tv
    ON v.id_tipo_vehiculo = tv.id_tipo_vehiculo
INNER JOIN rutas AS r
    ON da.id_ruta = r.id_ruta
ORDER BY da.fecha_asignacion DESC;


-- 7. Seguimiento de entregas, incluyendo despachos sin entrega registrada.
SELECT
    da.id_despacho,
    pe.numero_pedido,
    c.nombre_comercial AS cliente,
    e.fecha_entrega_real,
    e.peso_entregado_kg,
    e.estado_entrega,
    e.nombre_receptor
FROM despachos_asignaciones AS da
INNER JOIN pedidos AS pe
    ON da.id_pedido = pe.id_pedido
INNER JOIN clientes AS c
    ON pe.id_cliente = c.id_cliente
LEFT JOIN entregas AS e
    ON da.id_despacho = e.id_despacho
ORDER BY da.id_despacho;


-- 8. Novedades operativas con su despacho, entrega y ruta.
SELECT
    n.id_novedad,
    n.tipo_novedad,
    n.descripcion,
    n.fecha_novedad,
    n.minutos_retraso,
    n.estado_novedad,
    da.id_despacho,
    e.id_entrega,
    r.nombre_ruta
FROM novedades_relacionales AS n
LEFT JOIN despachos_asignaciones AS da
    ON n.id_despacho = da.id_despacho
LEFT JOIN entregas AS e
    ON n.id_entrega = e.id_entrega
LEFT JOIN rutas AS r
    ON n.id_ruta = r.id_ruta
ORDER BY n.fecha_novedad DESC;


/* ============================================================
   C. CONSULTAS AVANZADAS Y ANALITICAS
   ============================================================ */

-- 9. Valor y peso real de los pedidos a partir de sus detalles.
-- Se agrupa para evitar duplicar valores al unir tablas.
SELECT
    pe.numero_pedido,
    c.nombre_comercial AS cliente,
    COUNT(dp.id_detalle) AS lineas_de_producto,
    SUM(dp.cantidad) AS unidades_solicitadas,
    SUM(dp.subtotal) AS valor_calculado,
    SUM(dp.cantidad * dp.peso_unitario_kg) AS peso_calculado_kg
FROM pedidos AS pe
INNER JOIN clientes AS c
    ON pe.id_cliente = c.id_cliente
INNER JOIN detalle_pedidos AS dp
    ON pe.id_pedido = dp.id_pedido
GROUP BY
    pe.id_pedido,
    pe.numero_pedido,
    c.nombre_comercial
ORDER BY valor_calculado DESC;


-- 10. Resumen de pedidos por municipio de destino y estado.
SELECT
    m.nombre_municipio,
    pe.estado_pedido,
    COUNT(pe.id_pedido) AS cantidad_pedidos,
    SUM(pe.valor_total) AS valor_total_pedidos,
    AVG(pe.valor_total) AS valor_promedio
FROM municipios AS m
INNER JOIN pedidos AS pe
    ON m.id_municipio = pe.id_municipio_destino
GROUP BY
    m.id_municipio,
    m.nombre_municipio,
    pe.estado_pedido
ORDER BY m.nombre_municipio, cantidad_pedidos DESC;


-- 11. Rendimiento operativo por conductor.
SELECT
    co.id_conductor,
    CONCAT(co.nombres, ' ', co.apellidos) AS conductor,
    COUNT(DISTINCT da.id_despacho) AS despachos_asignados,
    SUM(CASE WHEN da.estado_despacho = 'ENTREGADO' THEN 1 ELSE 0 END)
        AS despachos_entregados,
    SUM(CASE WHEN da.estado_despacho = 'EN_TRANSITO' THEN 1 ELSE 0 END)
        AS despachos_en_transito
FROM conductores AS co
LEFT JOIN despachos_asignaciones AS da
    ON co.id_conductor = da.id_conductor
GROUP BY co.id_conductor, co.nombres, co.apellidos
ORDER BY despachos_entregados DESC, despachos_asignados DESC;


-- 12. Historial de cambios de estado de los pedidos.
SELECT
    pe.numero_pedido,
    h.estado_anterior,
    h.estado_nuevo,
    h.fecha_cambio,
    h.usuario_bd,
    h.observacion
FROM historial_estados_pedido AS h
INNER JOIN pedidos AS pe
    ON h.id_pedido = pe.id_pedido
ORDER BY pe.numero_pedido, h.fecha_cambio;


-- 13. Auditoria de cambios en los despachos.
SELECT
    a.id_auditoria,
    da.id_despacho,
    pe.numero_pedido,
    a.fecha_modificacion,
    a.usuario_bd,
    a.estado_anterior,
    a.estado_nuevo,
    a.observacion
FROM auditoria_despachos AS a
INNER JOIN despachos_asignaciones AS da
    ON a.id_despacho = da.id_despacho
INNER JOIN pedidos AS pe
    ON da.id_pedido = pe.id_pedido
ORDER BY a.fecha_modificacion DESC;


-- 14. Rutas con municipios de origen y destino.
SELECT
    r.id_ruta,
    r.nombre_ruta,
    origen.nombre_municipio AS municipio_origen,
    destino.nombre_municipio AS municipio_destino,
    r.distancia_km,
    r.tiempo_estimado_horas,
    r.estado_ruta
FROM rutas AS r
INNER JOIN municipios AS origen
    ON r.id_municipio_origen = origen.id_municipio
INNER JOIN municipios AS destino
    ON r.id_municipio_destino = destino.id_municipio
ORDER BY r.distancia_km DESC;


/* ============================================================
   D. VALIDACION EXACTA DE REGISTROS
   COUNT(*) consulta las filas reales; TABLE_ROWS de
   information_schema es solo una estimacion para InnoDB.
   ============================================================ */

SELECT 'municipios' AS tabla, COUNT(*) AS registros FROM municipios
UNION ALL SELECT 'tipos_vehiculo', COUNT(*) FROM tipos_vehiculo
UNION ALL SELECT 'clientes', COUNT(*) FROM clientes
UNION ALL SELECT 'productores', COUNT(*) FROM productores
UNION ALL SELECT 'productos', COUNT(*) FROM productos
UNION ALL SELECT 'vehiculos', COUNT(*) FROM vehiculos
UNION ALL SELECT 'conductores', COUNT(*) FROM conductores
UNION ALL SELECT 'rutas', COUNT(*) FROM rutas
UNION ALL SELECT 'pedidos', COUNT(*) FROM pedidos
UNION ALL SELECT 'detalle_pedidos', COUNT(*) FROM detalle_pedidos
UNION ALL SELECT 'despachos_asignaciones', COUNT(*) FROM despachos_asignaciones
UNION ALL SELECT 'entregas', COUNT(*) FROM entregas
UNION ALL SELECT 'novedades_relacionales', COUNT(*) FROM novedades_relacionales
UNION ALL SELECT 'historial_estados_pedido', COUNT(*) FROM historial_estados_pedido
UNION ALL SELECT 'auditoria_despachos', COUNT(*) FROM auditoria_despachos
ORDER BY tabla;

/* ======================= FIN =============================== */
