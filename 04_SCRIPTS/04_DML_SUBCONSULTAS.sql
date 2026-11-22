/* ============================================================
   PROYECTO: CONECTASUCRE
   SCRIPT: 04_DML_SUBCONSULTAS.sql
   MOTOR: MySQL 8.0+ / MySQL 9.7
   BASE DE DATOS: conectasucre_final
   OBJETIVO: Consultas con subconsultas correlacionadas y
             no correlacionadas para analisis del negocio.
   REQUISITO: Haber ejecutado 01_DDL.sql y 02_DML.sql.
   NOTA: Este script es de solo lectura; no modifica registros.
   ============================================================ */

USE conectasucre_final;

/* ============================================================
   A. SUBCONSULTAS NO CORRELACIONADAS
   ============================================================ */

-- 1. Pedidos cuyo valor supera el promedio general de pedidos.
SELECT
    p.numero_pedido,
    c.nombre_comercial AS cliente,
    p.valor_total
FROM pedidos AS p
INNER JOIN clientes AS c
    ON c.id_cliente = p.id_cliente
WHERE p.valor_total > (
    SELECT AVG(valor_total)
    FROM pedidos
)
ORDER BY p.valor_total DESC;


-- 2. Productos cuyo precio supera el precio promedio del catalogo.
SELECT
    id_producto,
    codigo_producto,
    nombre_producto,
    precio_unitario
FROM productos
WHERE precio_unitario > (
    SELECT AVG(precio_unitario)
    FROM productos
)
ORDER BY precio_unitario DESC;


-- 3. Clientes que han realizado al menos un pedido usando IN.
SELECT
    id_cliente,
    nombre_comercial,
    telefono
FROM clientes
WHERE id_cliente IN (
    SELECT id_cliente
    FROM pedidos
)
ORDER BY nombre_comercial;


-- 4. Productos que nunca han sido incluidos en un pedido.
SELECT
    pr.id_producto,
    pr.codigo_producto,
    pr.nombre_producto
FROM productos AS pr
WHERE pr.id_producto NOT IN (
    SELECT dp.id_producto
    FROM detalle_pedidos AS dp
    WHERE dp.id_producto IS NOT NULL
)
ORDER BY pr.nombre_producto;


-- 5. Rutas cuya distancia es superior al promedio de las rutas.
SELECT
    id_ruta,
    nombre_ruta,
    distancia_km,
    tiempo_estimado_horas
FROM rutas
WHERE distancia_km > (
    SELECT AVG(distancia_km)
    FROM rutas
    WHERE distancia_km IS NOT NULL
)
ORDER BY distancia_km DESC;


-- 6. Conductores que tienen asignaciones por encima del promedio
-- de despachos por conductor (incluye conductores sin despachos).
SELECT
    d.id_conductor,
    CONCAT(d.nombres, ' ', d.apellidos) AS conductor,
    COUNT(da.id_despacho) AS total_despachos
FROM conductores AS d
LEFT JOIN despachos_asignaciones AS da
    ON da.id_conductor = d.id_conductor
GROUP BY d.id_conductor, d.nombres, d.apellidos
HAVING COUNT(da.id_despacho) > (
    SELECT AVG(total_por_conductor)
    FROM (
        SELECT COUNT(da2.id_despacho) AS total_por_conductor
        FROM conductores AS d2
        LEFT JOIN despachos_asignaciones AS da2
            ON da2.id_conductor = d2.id_conductor
        GROUP BY d2.id_conductor
    ) AS promedio_despachos
)
ORDER BY total_despachos DESC;


/* ============================================================
   B. SUBCONSULTAS CORRELACIONADAS
   ============================================================ */

-- 7. Pedidos que superan el promedio de valor de los pedidos
-- del mismo cliente.
SELECT
    p.numero_pedido,
    c.nombre_comercial AS cliente,
    p.valor_total
FROM pedidos AS p
INNER JOIN clientes AS c
    ON c.id_cliente = p.id_cliente
WHERE p.valor_total > (
    SELECT AVG(p2.valor_total)
    FROM pedidos AS p2
    WHERE p2.id_cliente = p.id_cliente
)
ORDER BY c.nombre_comercial, p.valor_total DESC;


-- 8. Pedido de mayor valor de cada cliente.
SELECT
    p.numero_pedido,
    c.nombre_comercial AS cliente,
    p.valor_total
FROM pedidos AS p
INNER JOIN clientes AS c
    ON c.id_cliente = p.id_cliente
WHERE p.valor_total = (
    SELECT MAX(p2.valor_total)
    FROM pedidos AS p2
    WHERE p2.id_cliente = p.id_cliente
)
ORDER BY c.nombre_comercial;


-- 9. Último cambio de estado registrado para cada pedido.
SELECT
    p.numero_pedido,
    h.estado_anterior,
    h.estado_nuevo,
    h.fecha_cambio,
    h.usuario_bd
FROM pedidos AS p
INNER JOIN historial_estados_pedido AS h
    ON h.id_pedido = p.id_pedido
WHERE h.fecha_cambio = (
    SELECT MAX(h2.fecha_cambio)
    FROM historial_estados_pedido AS h2
    WHERE h2.id_pedido = p.id_pedido
)
ORDER BY h.fecha_cambio DESC;


-- 10. Conductores que tienen al menos un despacho en estado
-- EN_TRANSITO mediante EXISTS.
SELECT
    d.id_conductor,
    CONCAT(d.nombres, ' ', d.apellidos) AS conductor,
    d.telefono
FROM conductores AS d
WHERE EXISTS (
    SELECT 1
    FROM despachos_asignaciones AS da
    WHERE da.id_conductor = d.id_conductor
      AND da.estado_despacho = 'EN_TRANSITO'
)
ORDER BY conductor;


-- 11. Clientes que todavía no tienen pedidos pendientes
-- mediante NOT EXISTS.
SELECT
    c.id_cliente,
    c.nombre_comercial
FROM clientes AS c
WHERE NOT EXISTS (
    SELECT 1
    FROM pedidos AS p
    WHERE p.id_cliente = c.id_cliente
      AND p.estado_pedido = 'PENDIENTE'
)
ORDER BY c.nombre_comercial;


-- 12. Despachos que tienen una novedad abierta.
SELECT
    da.id_despacho,
    p.numero_pedido,
    n.tipo_novedad,
    n.descripcion,
    n.fecha_novedad
FROM despachos_asignaciones AS da
INNER JOIN pedidos AS p
    ON p.id_pedido = da.id_pedido
INNER JOIN novedades_relacionales AS n
    ON n.id_despacho = da.id_despacho
WHERE EXISTS (
    SELECT 1
    FROM novedades_relacionales AS n2
    WHERE n2.id_despacho = da.id_despacho
      AND n2.estado_novedad = 'ABIERTA'
)
ORDER BY n.fecha_novedad DESC;


-- 13. Productos cuyo precio es superior al promedio de los
-- productos del mismo productor.
SELECT
    pr.id_producto,
    pr.nombre_producto,
    po.nombre_productor,
    pr.precio_unitario
FROM productos AS pr
INNER JOIN productores AS po
    ON po.id_productor = pr.id_productor
WHERE pr.precio_unitario > (
    SELECT AVG(pr2.precio_unitario)
    FROM productos AS pr2
    WHERE pr2.id_productor = pr.id_productor
)
ORDER BY po.nombre_productor, pr.precio_unitario DESC;


/* ============================================================
   C. SUBCONSULTAS ESCALARES Y EN CLAUSULA FROM
   ============================================================ */

-- 14. Comparar el valor de cada pedido con el promedio general.
SELECT
    p.numero_pedido,
    p.valor_total,
    promedio.valor_promedio,
    p.valor_total - promedio.valor_promedio AS diferencia_promedio
FROM pedidos AS p
CROSS JOIN (
    SELECT AVG(valor_total) AS valor_promedio
    FROM pedidos
) AS promedio
ORDER BY diferencia_promedio DESC;


-- 15. Municipios con cantidad de pedidos superior al promedio
-- de pedidos por municipio.
SELECT
    m.nombre_municipio,
    COUNT(p.id_pedido) AS cantidad_pedidos
FROM municipios AS m
INNER JOIN pedidos AS p
    ON p.id_municipio_destino = m.id_municipio
GROUP BY m.id_municipio, m.nombre_municipio
HAVING COUNT(p.id_pedido) > (
    SELECT AVG(pedidos_por_municipio)
    FROM (
        SELECT COUNT(p2.id_pedido) AS pedidos_por_municipio
        FROM municipios AS m2
        LEFT JOIN pedidos AS p2
            ON p2.id_municipio_destino = m2.id_municipio
        GROUP BY m2.id_municipio
    ) AS promedio_municipal
)
ORDER BY cantidad_pedidos DESC;


/* ============================================================
   D. CONSULTAS DE VALIDACION
   ============================================================ */

-- 16. Verificar que cada pedido tenga al menos un detalle.
SELECT
    p.numero_pedido,
    p.estado_pedido
FROM pedidos AS p
WHERE NOT EXISTS (
    SELECT 1
    FROM detalle_pedidos AS dp
    WHERE dp.id_pedido = p.id_pedido
)
ORDER BY p.numero_pedido;


-- 17. Entregas completas con fecha posterior a la fecha prometida.
SELECT
    p.numero_pedido,
    p.fecha_entrega_prometida,
    e.fecha_entrega_real,
    DATEDIFF(e.fecha_entrega_real, p.fecha_entrega_prometida)
        AS dias_despues_de_fecha_prometida
FROM pedidos AS p
INNER JOIN despachos_asignaciones AS da
    ON da.id_pedido = p.id_pedido
INNER JOIN entregas AS e
    ON e.id_despacho = da.id_despacho
WHERE e.estado_entrega = 'COMPLETA'
  AND e.fecha_entrega_real > p.fecha_entrega_prometida
ORDER BY dias_despues_de_fecha_prometida DESC;


/* ======================= FIN =============================== */
