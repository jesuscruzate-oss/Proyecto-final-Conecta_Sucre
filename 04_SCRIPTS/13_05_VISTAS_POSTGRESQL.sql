-- CONECTASUCRE | 13_05_VISTAS_POSTGRESQL.sql
-- Fuente: CSV_EE3.csv: definiciones de 10 vistas de MySQL.
-- Ejecutar en Query Tool conectado a PostgreSQL 17 / conectasucre_final.
-- Solo crea vistas; NO elimina datos, tablas ni otros objetos.
-- No ejecutar repetidamente si ya existen vistas con modificaciones propias.
BEGIN;

-- vw_auditoria_despachos
CREATE VIEW public."vw_auditoria_despachos" AS
select "a"."id_auditoria" AS "id_auditoria","da"."id_despacho" AS "id_despacho","p"."numero_pedido" AS "numero_pedido","a"."fecha_modificacion" AS "fecha_modificacion","a"."usuario_bd" AS "usuario_bd","a"."estado_anterior" AS "estado_anterior","a"."estado_nuevo" AS "estado_nuevo","a"."observacion" AS "observacion" from ((public."auditoria_despachos" "a" join public."despachos_asignaciones" "da" on(("a"."id_despacho" = "da"."id_despacho"))) join public."pedidos" "p" on(("da"."id_pedido" = "p"."id_pedido")));

-- vw_catalogo_productos
CREATE VIEW public."vw_catalogo_productos" AS
select "pr"."id_producto" AS "id_producto","pr"."codigo_producto" AS "codigo_producto","pr"."nombre_producto" AS "nombre_producto","pr"."unidad_medida" AS "unidad_medida","pr"."peso_unitario_kg" AS "peso_unitario_kg","pr"."precio_unitario" AS "precio_unitario","po"."id_productor" AS "id_productor","po"."nombre_productor" AS "nombre_productor","m"."nombre_municipio" AS "municipio_productor" from ((public."productos" "pr" join public."productores" "po" on(("pr"."id_productor" = "po"."id_productor"))) join public."municipios" "m" on(("po"."id_municipio" = "m"."id_municipio")));

-- vw_clientes_municipio
CREATE VIEW public."vw_clientes_municipio" AS
select "c"."id_cliente" AS "id_cliente","c"."nombre_comercial" AS "nombre_comercial","c"."nombre_contacto" AS "nombre_contacto","c"."telefono" AS "telefono","c"."correo" AS "correo","c"."direccion" AS "direccion","m"."nombre_municipio" AS "nombre_municipio","m"."departamento" AS "departamento" from (public."clientes" "c" join public."municipios" "m" on(("c"."id_municipio" = "m"."id_municipio")));

-- vw_despachos_logisticos
CREATE VIEW public."vw_despachos_logisticos" AS
select "da"."id_despacho" AS "id_despacho","p"."numero_pedido" AS "numero_pedido","c"."nombre_comercial" AS "cliente",concat("co"."nombres",' ',"co"."apellidos") AS "conductor","v"."placa" AS "placa","tv"."nombre_tipo" AS "tipo_vehiculo","r"."nombre_ruta" AS "nombre_ruta","da"."fecha_asignacion" AS "fecha_asignacion","da"."fecha_salida" AS "fecha_salida","da"."estado_despacho" AS "estado_despacho" from ((((((public."despachos_asignaciones" "da" join public."pedidos" "p" on(("da"."id_pedido" = "p"."id_pedido"))) join public."clientes" "c" on(("p"."id_cliente" = "c"."id_cliente"))) join public."conductores" "co" on(("da"."id_conductor" = "co"."id_conductor"))) join public."vehiculos" "v" on(("da"."id_vehiculo" = "v"."id_vehiculo"))) join public."tipos_vehiculo" "tv" on(("v"."id_tipo_vehiculo" = "tv"."id_tipo_vehiculo"))) join public."rutas" "r" on(("da"."id_ruta" = "r"."id_ruta")));

-- vw_detalle_pedidos
CREATE VIEW public."vw_detalle_pedidos" AS
select "dp"."id_detalle" AS "id_detalle","p"."numero_pedido" AS "numero_pedido","p"."fecha_pedido" AS "fecha_pedido","c"."nombre_comercial" AS "cliente","pr"."codigo_producto" AS "codigo_producto","pr"."nombre_producto" AS "nombre_producto","po"."nombre_productor" AS "nombre_productor","dp"."cantidad" AS "cantidad","dp"."precio_unitario" AS "precio_unitario","dp"."peso_unitario_kg" AS "peso_unitario_kg","dp"."subtotal" AS "subtotal" from ((((public."detalle_pedidos" "dp" join public."pedidos" "p" on(("dp"."id_pedido" = "p"."id_pedido"))) join public."clientes" "c" on(("p"."id_cliente" = "c"."id_cliente"))) join public."productos" "pr" on(("dp"."id_producto" = "pr"."id_producto"))) join public."productores" "po" on(("pr"."id_productor" = "po"."id_productor")));

-- vw_historial_pedidos
CREATE VIEW public."vw_historial_pedidos" AS
select "h"."id_historial" AS "id_historial","p"."numero_pedido" AS "numero_pedido","h"."estado_anterior" AS "estado_anterior","h"."estado_nuevo" AS "estado_nuevo","h"."fecha_cambio" AS "fecha_cambio","h"."usuario_bd" AS "usuario_bd","h"."observacion" AS "observacion" from (public."historial_estados_pedido" "h" join public."pedidos" "p" on(("h"."id_pedido" = "p"."id_pedido")));

-- vw_indicadores_pedidos
CREATE VIEW public."vw_indicadores_pedidos" AS
select public."pedidos"."estado_pedido" AS "estado_pedido",COUNT(*) AS "cantidad_pedidos",sum(public."pedidos"."valor_total") AS "valor_total",avg(public."pedidos"."valor_total") AS "valor_promedio",sum(public."pedidos"."peso_total_kg") AS "peso_total_kg" from public."pedidos" group by public."pedidos"."estado_pedido";

-- vw_novedades_operativas
CREATE VIEW public."vw_novedades_operativas" AS
select "n"."id_novedad" AS "id_novedad","n"."tipo_novedad" AS "tipo_novedad","n"."descripcion" AS "descripcion","n"."fecha_novedad" AS "fecha_novedad","n"."minutos_retraso" AS "minutos_retraso","n"."responsable" AS "responsable","n"."estado_novedad" AS "estado_novedad","da"."id_despacho" AS "id_despacho","p"."numero_pedido" AS "numero_pedido","e"."id_entrega" AS "id_entrega","r"."nombre_ruta" AS "nombre_ruta" from ((((public."novedades_relacionales" "n" left join public."despachos_asignaciones" "da" on(("n"."id_despacho" = "da"."id_despacho"))) left join public."pedidos" "p" on(("da"."id_pedido" = "p"."id_pedido"))) left join public."entregas" "e" on(("n"."id_entrega" = "e"."id_entrega"))) left join public."rutas" "r" on(("n"."id_ruta" = "r"."id_ruta")));

-- vw_pedidos_clientes
CREATE VIEW public."vw_pedidos_clientes" AS
select "p"."id_pedido" AS "id_pedido","p"."numero_pedido" AS "numero_pedido","p"."fecha_pedido" AS "fecha_pedido","p"."fecha_entrega_prometida" AS "fecha_entrega_prometida","p"."estado_pedido" AS "estado_pedido","p"."peso_total_kg" AS "peso_total_kg","p"."valor_total" AS "valor_total","c"."id_cliente" AS "id_cliente","c"."nombre_comercial" AS "cliente","m"."nombre_municipio" AS "municipio_destino","m"."departamento" AS "departamento" from ((public."pedidos" "p" join public."clientes" "c" on(("p"."id_cliente" = "c"."id_cliente"))) join public."municipios" "m" on(("p"."id_municipio_destino" = "m"."id_municipio")));

-- vw_seguimiento_entregas
CREATE VIEW public."vw_seguimiento_entregas" AS
select "da"."id_despacho" AS "id_despacho","p"."numero_pedido" AS "numero_pedido","c"."nombre_comercial" AS "cliente","da"."estado_despacho" AS "estado_despacho","e"."id_entrega" AS "id_entrega","e"."fecha_entrega_real" AS "fecha_entrega_real","e"."peso_entregado_kg" AS "peso_entregado_kg","e"."estado_entrega" AS "estado_entrega","e"."nombre_receptor" AS "nombre_receptor","e"."observaciones" AS "observaciones_entrega" from (((public."despachos_asignaciones" "da" join public."pedidos" "p" on(("da"."id_pedido" = "p"."id_pedido"))) join public."clientes" "c" on(("p"."id_cliente" = "c"."id_cliente"))) left join public."entregas" "e" on(("da"."id_despacho" = "e"."id_despacho")));

COMMIT;

-- VALIDACION: listado de las 10 vistas y cantidad de filas (solo lectura).
SELECT vista, registros FROM (
  SELECT 'vw_auditoria_despachos'::text AS vista, COUNT(*)::bigint AS registros FROM public."vw_auditoria_despachos" UNION ALL
  SELECT 'vw_catalogo_productos'::text AS vista, COUNT(*)::bigint AS registros FROM public."vw_catalogo_productos" UNION ALL
  SELECT 'vw_clientes_municipio'::text AS vista, COUNT(*)::bigint AS registros FROM public."vw_clientes_municipio" UNION ALL
  SELECT 'vw_despachos_logisticos'::text AS vista, COUNT(*)::bigint AS registros FROM public."vw_despachos_logisticos" UNION ALL
  SELECT 'vw_detalle_pedidos'::text AS vista, COUNT(*)::bigint AS registros FROM public."vw_detalle_pedidos" UNION ALL
  SELECT 'vw_historial_pedidos'::text AS vista, COUNT(*)::bigint AS registros FROM public."vw_historial_pedidos" UNION ALL
  SELECT 'vw_indicadores_pedidos'::text AS vista, COUNT(*)::bigint AS registros FROM public."vw_indicadores_pedidos" UNION ALL
  SELECT 'vw_novedades_operativas'::text AS vista, COUNT(*)::bigint AS registros FROM public."vw_novedades_operativas" UNION ALL
  SELECT 'vw_pedidos_clientes'::text AS vista, COUNT(*)::bigint AS registros FROM public."vw_pedidos_clientes" UNION ALL
  SELECT 'vw_seguimiento_entregas'::text AS vista, COUNT(*)::bigint AS registros FROM public."vw_seguimiento_entregas"
) AS conteos ORDER BY vista;
