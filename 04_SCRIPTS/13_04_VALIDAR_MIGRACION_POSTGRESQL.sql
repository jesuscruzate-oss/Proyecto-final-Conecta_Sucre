-- CONECTASUCRE | Comparacion de registros desde el respaldo original
-- Esperado vs real, y estado de migracion por tabla.
WITH esperado(tabla, registros_mysql) AS (
 VALUES ('auditoria_despachos',200),
        ('clientes',20),
        ('conductores',12),
        ('despachos_asignaciones',200),
        ('detalle_pedidos',200),
        ('entregas',200),
        ('historial_estados_pedido',200),
        ('municipios',26),
        ('novedades_relacionales',20),
        ('pedidos',200),
        ('productores',10),
        ('productos',20),
        ('rutas',26),
        ('tipos_vehiculo',4),
        ('vehiculos',12)
) ,
real AS (
SELECT 'auditoria_despachos'::text AS tabla, count(*)::bigint AS registros_postgres FROM public."auditoria_despachos"
 UNION ALL
SELECT 'clientes'::text AS tabla, count(*)::bigint AS registros_postgres FROM public."clientes"
 UNION ALL
SELECT 'conductores'::text AS tabla, count(*)::bigint AS registros_postgres FROM public."conductores"
 UNION ALL
SELECT 'despachos_asignaciones'::text AS tabla, count(*)::bigint AS registros_postgres FROM public."despachos_asignaciones"
 UNION ALL
SELECT 'detalle_pedidos'::text AS tabla, count(*)::bigint AS registros_postgres FROM public."detalle_pedidos"
 UNION ALL
SELECT 'entregas'::text AS tabla, count(*)::bigint AS registros_postgres FROM public."entregas"
 UNION ALL
SELECT 'historial_estados_pedido'::text AS tabla, count(*)::bigint AS registros_postgres FROM public."historial_estados_pedido"
 UNION ALL
SELECT 'municipios'::text AS tabla, count(*)::bigint AS registros_postgres FROM public."municipios"
 UNION ALL
SELECT 'novedades_relacionales'::text AS tabla, count(*)::bigint AS registros_postgres FROM public."novedades_relacionales"
 UNION ALL
SELECT 'pedidos'::text AS tabla, count(*)::bigint AS registros_postgres FROM public."pedidos"
 UNION ALL
SELECT 'productores'::text AS tabla, count(*)::bigint AS registros_postgres FROM public."productores"
 UNION ALL
SELECT 'productos'::text AS tabla, count(*)::bigint AS registros_postgres FROM public."productos"
 UNION ALL
SELECT 'rutas'::text AS tabla, count(*)::bigint AS registros_postgres FROM public."rutas"
 UNION ALL
SELECT 'tipos_vehiculo'::text AS tabla, count(*)::bigint AS registros_postgres FROM public."tipos_vehiculo"
 UNION ALL
SELECT 'vehiculos'::text AS tabla, count(*)::bigint AS registros_postgres FROM public."vehiculos"
)
SELECT e.tabla,e.registros_mysql,r.registros_postgres, CASE WHEN e.registros_mysql=r.registros_postgres THEN 'OK' ELSE 'REVISAR' END AS estado FROM esperado e JOIN real r USING (tabla) ORDER BY e.tabla;

-- Tablas y claves foraneas:
SELECT (SELECT count(*) FROM information_schema.tables WHERE table_schema='public' AND table_type='BASE TABLE') AS tablas, (SELECT count(*) FROM information_schema.table_constraints WHERE table_schema='public' AND constraint_type='FOREIGN KEY') AS claves_foraneas;
