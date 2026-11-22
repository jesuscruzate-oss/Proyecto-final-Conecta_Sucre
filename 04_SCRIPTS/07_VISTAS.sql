/* ============================================================
   PROYECTO: CONECTASUCRE
   SCRIPT: 07_VISTAS.sql
   MOTOR: MySQL 8.0+ / MySQL 9.7
   BASE DE DATOS: conectasucre_final
   OBJETIVO: Crear vistas para consultar informacion clave
             comercial, logistica y de seguimiento.
   NOTA: Las vistas no duplican datos; guardan consultas SQL.
   ============================================================ */

USE conectasucre_final;

/* ============================================================
   1. VISTA DE CLIENTES Y MUNICIPIOS
   ============================================================ */

CREATE OR REPLACE VIEW vw_clientes_municipio AS
SELECT
    c.id_cliente,
    c.nombre_comercial,
    c.nombre_contacto,
    c.telefono,
    c.correo,
    c.direccion,
    m.nombre_municipio,
    m.departamento
FROM clientes AS c
INNER JOIN municipios AS m
    ON c.id_municipio = m.id_municipio;


/* ============================================================
   2. VISTA DE PRODUCTOS Y PRODUCTORES
   ============================================================ */

CREATE OR REPLACE VIEW vw_catalogo_productos AS
SELECT
    pr.id_producto,
    pr.codigo_producto,
    pr.nombre_producto,
    pr.unidad_medida,
    pr.peso_unitario_kg,
    pr.precio_unitario,
    po.id_productor,
    po.nombre_productor,
    m.nombre_municipio AS municipio_productor
FROM productos AS pr
INNER JOIN productores AS po
    ON pr.id_productor = po.id_productor
INNER JOIN municipios AS m
    ON po.id_municipio = m.id_municipio;


/* ============================================================
   3. VISTA DE PEDIDOS CON CLIENTE Y DESTINO
   ============================================================ */

CREATE OR REPLACE VIEW vw_pedidos_clientes AS
SELECT
    p.id_pedido,
    p.numero_pedido,
    p.fecha_pedido,
    p.fecha_entrega_prometida,
    p.estado_pedido,
    p.peso_total_kg,
    p.valor_total,
    c.id_cliente,
    c.nombre_comercial AS cliente,
    m.nombre_municipio AS municipio_destino,
    m.departamento
FROM pedidos AS p
INNER JOIN clientes AS c
    ON p.id_cliente = c.id_cliente
INNER JOIN municipios AS m
    ON p.id_municipio_destino = m.id_municipio;


/* ============================================================
   4. VISTA DE DETALLE DE PEDIDOS
   ============================================================ */

CREATE OR REPLACE VIEW vw_detalle_pedidos AS
SELECT
    dp.id_detalle,
    p.numero_pedido,
    p.fecha_pedido,
    c.nombre_comercial AS cliente,
    pr.codigo_producto,
    pr.nombre_producto,
    po.nombre_productor,
    dp.cantidad,
    dp.precio_unitario,
    dp.peso_unitario_kg,
    dp.subtotal
FROM detalle_pedidos AS dp
INNER JOIN pedidos AS p
    ON dp.id_pedido = p.id_pedido
INNER JOIN clientes AS c
    ON p.id_cliente = c.id_cliente
INNER JOIN productos AS pr
    ON dp.id_producto = pr.id_producto
INNER JOIN productores AS po
    ON pr.id_productor = po.id_productor;


/* ============================================================
   5. VISTA DE DESPACHOS Y RECURSOS LOGISTICOS
   ============================================================ */

CREATE OR REPLACE VIEW vw_despachos_logisticos AS
SELECT
    da.id_despacho,
    p.numero_pedido,
    c.nombre_comercial AS cliente,
    CONCAT(co.nombres, ' ', co.apellidos) AS conductor,
    v.placa,
    tv.nombre_tipo AS tipo_vehiculo,
    r.nombre_ruta,
    da.fecha_asignacion,
    da.fecha_salida,
    da.estado_despacho
FROM despachos_asignaciones AS da
INNER JOIN pedidos AS p
    ON da.id_pedido = p.id_pedido
INNER JOIN clientes AS c
    ON p.id_cliente = c.id_cliente
INNER JOIN conductores AS co
    ON da.id_conductor = co.id_conductor
INNER JOIN vehiculos AS v
    ON da.id_vehiculo = v.id_vehiculo
INNER JOIN tipos_vehiculo AS tv
    ON v.id_tipo_vehiculo = tv.id_tipo_vehiculo
INNER JOIN rutas AS r
    ON da.id_ruta = r.id_ruta;


/* ============================================================
   6. VISTA DE SEGUIMIENTO DE ENTREGAS
   Incluye despachos aun sin entrega registrada.
   ============================================================ */

CREATE OR REPLACE VIEW vw_seguimiento_entregas AS
SELECT
    da.id_despacho,
    p.numero_pedido,
    c.nombre_comercial AS cliente,
    da.estado_despacho,
    e.id_entrega,
    e.fecha_entrega_real,
    e.peso_entregado_kg,
    e.estado_entrega,
    e.nombre_receptor,
    e.observaciones AS observaciones_entrega
FROM despachos_asignaciones AS da
INNER JOIN pedidos AS p
    ON da.id_pedido = p.id_pedido
INNER JOIN clientes AS c
    ON p.id_cliente = c.id_cliente
LEFT JOIN entregas AS e
    ON da.id_despacho = e.id_despacho;


/* ============================================================
   7. VISTA DE NOVEDADES OPERATIVAS
   ============================================================ */

CREATE OR REPLACE VIEW vw_novedades_operativas AS
SELECT
    n.id_novedad,
    n.tipo_novedad,
    n.descripcion,
    n.fecha_novedad,
    n.minutos_retraso,
    n.responsable,
    n.estado_novedad,
    da.id_despacho,
    p.numero_pedido,
    e.id_entrega,
    r.nombre_ruta
FROM novedades_relacionales AS n
LEFT JOIN despachos_asignaciones AS da
    ON n.id_despacho = da.id_despacho
LEFT JOIN pedidos AS p
    ON da.id_pedido = p.id_pedido
LEFT JOIN entregas AS e
    ON n.id_entrega = e.id_entrega
LEFT JOIN rutas AS r
    ON n.id_ruta = r.id_ruta;


/* ============================================================
   8. VISTA DE HISTORIAL DE ESTADOS DE PEDIDOS
   ============================================================ */

CREATE OR REPLACE VIEW vw_historial_pedidos AS
SELECT
    h.id_historial,
    p.numero_pedido,
    h.estado_anterior,
    h.estado_nuevo,
    h.fecha_cambio,
    h.usuario_bd,
    h.observacion
FROM historial_estados_pedido AS h
INNER JOIN pedidos AS p
    ON h.id_pedido = p.id_pedido;


/* ============================================================
   9. VISTA DE INDICADORES DE PEDIDOS POR ESTADO
   ============================================================ */

CREATE OR REPLACE VIEW vw_indicadores_pedidos AS
SELECT
    estado_pedido,
    COUNT(*) AS cantidad_pedidos,
    SUM(valor_total) AS valor_total,
    AVG(valor_total) AS valor_promedio,
    SUM(peso_total_kg) AS peso_total_kg
FROM pedidos
GROUP BY estado_pedido;


/* ============================================================
   10. VISTA DE AUDITORIA DE DESPACHOS
   ============================================================ */

CREATE OR REPLACE VIEW vw_auditoria_despachos AS
SELECT
    a.id_auditoria,
    da.id_despacho,
    p.numero_pedido,
    a.fecha_modificacion,
    a.usuario_bd,
    a.estado_anterior,
    a.estado_nuevo,
    a.observacion
FROM auditoria_despachos AS a
INNER JOIN despachos_asignaciones AS da
    ON a.id_despacho = da.id_despacho
INNER JOIN pedidos AS p
    ON da.id_pedido = p.id_pedido;


/* ============================================================
   11. VERIFICACION: LISTAR VISTAS CREADAS
   ============================================================ */

SELECT
    TABLE_NAME AS nombre_vista
FROM information_schema.VIEWS
WHERE TABLE_SCHEMA = 'conectasucre_final'
ORDER BY TABLE_NAME;


/* ============================================================
   12. PRUEBAS DE CONSULTA DE LAS VISTAS
   ============================================================ */

SELECT * FROM vw_clientes_municipio LIMIT 10;
SELECT * FROM vw_catalogo_productos LIMIT 10;
SELECT * FROM vw_pedidos_clientes LIMIT 10;
SELECT * FROM vw_detalle_pedidos LIMIT 10;
SELECT * FROM vw_despachos_logisticos LIMIT 10;
SELECT * FROM vw_seguimiento_entregas LIMIT 10;
SELECT * FROM vw_novedades_operativas LIMIT 10;
SELECT * FROM vw_historial_pedidos LIMIT 10;
SELECT * FROM vw_indicadores_pedidos;
SELECT * FROM vw_auditoria_despachos LIMIT 10;

/* ======================= FIN =============================== */
