/* ============================================================
   PROYECTO: CONECTASUCRE
   SCRIPT: 02_DML.sql
   MOTOR: MySQL 8.0+ (compatible con MySQL 9.7)
   BASE DE DATOS: conectasucre_final
   DESCRIPCION: Carga de datos sinteticos para pruebas.

   IMPORTANTE:
   1. Ejecutar primero 01_DDL.sql y verificar que existan las 15 tablas.
   2. Este archivo carga datos de demostracion, no datos reales.
   3. Ejecutar este archivo UNA SOLA VEZ sobre el esquema vacio.
   4. No elimina ni modifica el esquema anterior conectasucre.
   ============================================================ */

USE conectasucre_final;

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 1;

/* ============================================================
   1. MUNICIPIOS DE SUCRE
   ============================================================ */

INSERT INTO municipios
    (id_municipio, nombre_municipio, departamento)
VALUES
    (1, 'Sincelejo', 'Sucre'),
    (2, 'Corozal', 'Sucre'),
    (3, 'Sampues', 'Sucre'),
    (4, 'Tolu', 'Sucre'),
    (5, 'Covenas', 'Sucre'),
    (6, 'San Onofre', 'Sucre'),
    (7, 'Morroa', 'Sucre'),
    (8, 'Los Palmitos', 'Sucre'),
    (9, 'Sincé', 'Sucre'),
    (10, 'San Pedro', 'Sucre'),
    (11, 'Buenavista', 'Sucre'),
    (12, 'Galeras', 'Sucre'),
    (13, 'El Roble', 'Sucre'),
    (14, 'San Benito Abad', 'Sucre'),
    (15, 'Sucre', 'Sucre'),
    (16, 'Majagual', 'Sucre'),
    (17, 'Guaranda', 'Sucre'),
    (18, 'Caimito', 'Sucre'),
    (19, 'La Union', 'Sucre'),
    (20, 'San Marcos', 'Sucre'),
    (21, 'Toluviejo', 'Sucre'),
    (22, 'Chalan', 'Sucre'),
    (23, 'Coloso', 'Sucre'),
    (24, 'Ovejas', 'Sucre'),
    (25, 'Palmito', 'Sucre'),
    (26, 'Betulia', 'Sucre');

/* ============================================================
   2. TIPOS DE VEHICULO
   ============================================================ */

INSERT INTO tipos_vehiculo
    (id_tipo_vehiculo, nombre_tipo, descripcion)
VALUES
    (1, 'Motocarga', 'Vehiculo liviano para entregas de pequena escala'),
    (2, 'Camioneta', 'Vehiculo utilitario para carga'),
    (3, 'Camion NPR', 'Camion de capacidad media'),
    (4, 'Camion sencillo', 'Vehiculo de carga para recorridos regionales');

/* ============================================================
   3. CLIENTES (20 REGISTROS)
   ============================================================ */

INSERT INTO clientes
    (id_cliente, tipo_documento, numero_documento, nombre_comercial,
     nombre_contacto, telefono, correo, direccion, id_municipio,
     fecha_registro, estado_cliente)
SELECT
    n,
    'NIT',
    CONCAT('900', LPAD(100000 + n, 6, '0'), '-1'),
    CONCAT('Comercializadora Sucre ', LPAD(n, 2, '0')),
    CONCAT('Contacto Cliente ', n),
    CONCAT('300', LPAD(1000000 + n, 7, '0')),
    CONCAT('cliente', n, '@conectasucre.test'),
    CONCAT('Calle ', 10 + n, ' # ', 5 + n, '-', 20 + n),
    MOD(n - 1, 26) + 1,
    '2026-01-01 08:00:00',
    'ACTIVO'
FROM (
    SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
    UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8
    UNION ALL SELECT 9 UNION ALL SELECT 10 UNION ALL SELECT 11 UNION ALL SELECT 12
    UNION ALL SELECT 13 UNION ALL SELECT 14 UNION ALL SELECT 15 UNION ALL SELECT 16
    UNION ALL SELECT 17 UNION ALL SELECT 18 UNION ALL SELECT 19 UNION ALL SELECT 20
) AS numeros;

/* ============================================================
   4. PRODUCTORES (10 REGISTROS)
   ============================================================ */

INSERT INTO productores
    (id_productor, tipo_documento, numero_documento, nombre_productor,
     telefono, correo, direccion, id_municipio, estado_productor)
SELECT
    n,
    'CC',
    CONCAT('1100', LPAD(200000 + n, 6, '0')),
    CONCAT('Asociacion de Productores ', n),
    CONCAT('310', LPAD(2000000 + n, 7, '0')),
    CONCAT('productor', n, '@conectasucre.test'),
    CONCAT('Vereda productiva ', n),
    MOD(n - 1, 26) + 1,
    'ACTIVO'
FROM (
    SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
    UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8
    UNION ALL SELECT 9 UNION ALL SELECT 10
) AS numeros;

/* ============================================================
   5. PRODUCTOS (20 REGISTROS)
   ============================================================ */

INSERT INTO productos
    (id_producto, id_productor, codigo_producto, nombre_producto,
     descripcion, unidad_medida, peso_unitario_kg, precio_unitario,
     estado_producto)
SELECT
    n,
    MOD(n - 1, 10) + 1,
    CONCAT('PRD-', LPAD(n, 4, '0')),
    ELT(MOD(n - 1, 10) + 1,
        'Yuca', 'Ñame', 'Ajonjoli', 'Maiz', 'Arroz',
        'Aguacate', 'Platano', 'Mango', 'Ñame espino', 'Frijol'),
    CONCAT('Producto agricola de demostracion numero ', n),
    'Kilogramo',
    CAST(0.50 + (n * 0.10) AS DECIMAL(10,3)),
    CAST(2000 + (n * 500) AS DECIMAL(14,2)),
    'ACTIVO'
FROM (
    SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
    UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8
    UNION ALL SELECT 9 UNION ALL SELECT 10 UNION ALL SELECT 11 UNION ALL SELECT 12
    UNION ALL SELECT 13 UNION ALL SELECT 14 UNION ALL SELECT 15 UNION ALL SELECT 16
    UNION ALL SELECT 17 UNION ALL SELECT 18 UNION ALL SELECT 19 UNION ALL SELECT 20
) AS numeros;

/* ============================================================
   6. CONDUCTORES (12 REGISTROS)
   ============================================================ */

INSERT INTO conductores
    (id_conductor, tipo_documento, numero_documento, nombres, apellidos,
     telefono, numero_licencia, categoria_licencia,
     fecha_vencimiento_licencia, estado_conductor)
SELECT
    n,
    'CC',
    CONCAT('1000', LPAD(300000 + n, 6, '0')),
    CONCAT('Conductor ', n),
    CONCAT('Sucre ', n),
    CONCAT('320', LPAD(3000000 + n, 7, '0')),
    CONCAT('LIC-SUC-', LPAD(n, 4, '0')),
    'C2',
    '2028-12-31',
    'DISPONIBLE'
FROM (
    SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
    UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8
    UNION ALL SELECT 9 UNION ALL SELECT 10 UNION ALL SELECT 11 UNION ALL SELECT 12
) AS numeros;

/* ============================================================
   7. VEHICULOS (12 REGISTROS)
   ============================================================ */

INSERT INTO vehiculos
    (id_vehiculo, placa, id_tipo_vehiculo, marca, modelo, anio,
     capacidad_carga_kg, estado_vehiculo)
SELECT
    n,
    CONCAT('SUC', LPAD(n, 3, '0'), 'A'),
    MOD(n - 1, 4) + 1,
    ELT(MOD(n - 1, 4) + 1, 'Chevrolet', 'Nissan', 'Kia', 'JAC'),
    CONCAT('Modelo ', 2018 + MOD(n, 7)),
    2018 + MOD(n, 7),
    CASE MOD(n - 1, 4)
        WHEN 0 THEN 500
        WHEN 1 THEN 1200
        WHEN 2 THEN 3500
        ELSE 5000
    END,
    'DISPONIBLE'
FROM (
    SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
    UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8
    UNION ALL SELECT 9 UNION ALL SELECT 10 UNION ALL SELECT 11 UNION ALL SELECT 12
) AS numeros;

/* ============================================================
   8. RUTAS (26 REGISTROS)
   ============================================================ */

INSERT INTO rutas
    (id_ruta, nombre_ruta, id_municipio_origen,
     id_municipio_destino, distancia_km, tiempo_estimado_horas,
     descripcion, estado_ruta)
SELECT
    n,
    CONCAT('Ruta regional ', LPAD(n, 2, '0')),
    n,
    MOD(n, 26) + 1,
    CAST(12 + n * 2.5 AS DECIMAL(10,2)),
    CAST(0.5 + n * 0.08 AS DECIMAL(8,2)),
    CONCAT('Ruta de demostracion entre municipios de Sucre ', n),
    'ACTIVA'
FROM (
    SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
    UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8
    UNION ALL SELECT 9 UNION ALL SELECT 10 UNION ALL SELECT 11 UNION ALL SELECT 12
    UNION ALL SELECT 13 UNION ALL SELECT 14 UNION ALL SELECT 15 UNION ALL SELECT 16
    UNION ALL SELECT 17 UNION ALL SELECT 18 UNION ALL SELECT 19 UNION ALL SELECT 20
    UNION ALL SELECT 21 UNION ALL SELECT 22 UNION ALL SELECT 23 UNION ALL SELECT 24
    UNION ALL SELECT 25 UNION ALL SELECT 26
) AS numeros;

/* ============================================================
   9. GENERADOR DE 200 NUMEROS PARA LOS REGISTROS TRANSACCIONALES
   ============================================================ */

CREATE TEMPORARY TABLE tmp_consecutivos (
    n INT PRIMARY KEY
);

INSERT INTO tmp_consecutivos (n)
WITH RECURSIVE secuencia AS (
    SELECT 1 AS n
    UNION ALL
    SELECT n + 1
    FROM secuencia
    WHERE n < 200
)
SELECT n FROM secuencia;

/* ============================================================
   10. PEDIDOS (200 REGISTROS)
   ============================================================ */

INSERT INTO pedidos
    (id_pedido, numero_pedido, id_cliente, id_municipio_destino,
     fecha_pedido, fecha_entrega_prometida, peso_total_kg,
     valor_total, estado_pedido, observaciones)
SELECT
    n,
    CONCAT('CS-2026-', LPAD(n, 5, '0')),
    MOD(n - 1, 20) + 1,
    MOD(n, 26) + 1,
    DATE_ADD('2026-01-01 08:00:00', INTERVAL n DAY),
    DATE_ADD('2026-01-06 08:00:00', INTERVAL n DAY),
    CAST((2 + MOD(n, 5)) * (0.50 + ((MOD(n - 1, 20) + 1) * 0.10)) AS DECIMAL(12,2)),
    CAST((2 + MOD(n, 5)) * (2000 + ((MOD(n - 1, 20) + 1) * 500)) AS DECIMAL(14,2)),
    CASE
        WHEN MOD(n, 10) = 0 THEN 'PENDIENTE'
        WHEN MOD(n, 10) IN (1, 2) THEN 'EN_TRANSITO'
        ELSE 'ENTREGADO'
    END,
    CONCAT('Pedido sintetico de demostracion ', n)
FROM tmp_consecutivos;

/* ============================================================
   11. DETALLE DE PEDIDOS (200 REGISTROS)
   ============================================================ */

INSERT INTO detalle_pedidos
    (id_detalle, id_pedido, id_producto, cantidad,
     precio_unitario, peso_unitario_kg)
SELECT
    n,
    n,
    MOD(n - 1, 20) + 1,
    2 + MOD(n, 5),
    2000 + ((MOD(n - 1, 20) + 1) * 500),
    0.50 + ((MOD(n - 1, 20) + 1) * 0.10)
FROM tmp_consecutivos;

/* ============================================================
   12. DESPACHOS / ASIGNACIONES (200 REGISTROS)
   ============================================================ */

INSERT INTO despachos_asignaciones
    (id_despacho, id_pedido, id_vehiculo, id_conductor, id_ruta,
     fecha_asignacion, fecha_salida, estado_despacho)
SELECT
    n,
    n,
    MOD(n - 1, 12) + 1,
    MOD(n - 1, 12) + 1,
    MOD(n - 1, 26) + 1,
    DATE_ADD('2026-01-02 07:00:00', INTERVAL n DAY),
    DATE_ADD('2026-01-02 08:00:00', INTERVAL n DAY),
    CASE
        WHEN MOD(n, 10) = 0 THEN 'ASIGNADO'
        WHEN MOD(n, 10) IN (1, 2) THEN 'EN_TRANSITO'
        ELSE 'ENTREGADO'
    END
FROM tmp_consecutivos;

/* ============================================================
   13. ENTREGAS (200 REGISTROS)
   ============================================================ */

INSERT INTO entregas
    (id_entrega, id_despacho, fecha_entrega_real,
     peso_entregado_kg, estado_entrega, nombre_receptor, observaciones)
SELECT
    n,
    n,
    CASE
        WHEN MOD(n, 10) = 0 THEN NULL
        ELSE DATE_ADD('2026-01-03 12:00:00', INTERVAL n DAY)
    END,
    CASE
        WHEN MOD(n, 10) = 0 THEN 0
        ELSE CAST((2 + MOD(n, 5)) * (0.50 + ((MOD(n - 1, 20) + 1) * 0.10)) AS DECIMAL(12,2))
    END,
    CASE
        WHEN MOD(n, 10) = 0 THEN 'PENDIENTE'
        WHEN MOD(n, 10) = 1 THEN 'PARCIAL'
        ELSE 'COMPLETA'
    END,
    CASE WHEN MOD(n, 10) = 0 THEN NULL ELSE CONCAT('Receptor ', n) END,
    CONCAT('Registro de entrega sintetico ', n)
FROM tmp_consecutivos;

/* ============================================================
   14. NOVEDADES (20 REGISTROS)
   ============================================================ */

INSERT INTO novedades_relacionales
    (id_novedad, id_despacho, id_entrega, id_ruta,
     tipo_novedad, descripcion, fecha_novedad,
     minutos_retraso, responsable, estado_novedad)
SELECT
    n,
    n,
    n,
    MOD(n - 1, 26) + 1,
    ELT(MOD(n - 1, 4) + 1,
        'RETRASO', 'CLIMA', 'AVERIA', 'DIRECCION_INCORRECTA'),
    CONCAT('Novedad sintetica para pruebas numero ', n),
    DATE_ADD('2026-02-01 10:00:00', INTERVAL n DAY),
    MOD(n * 7, 90),
    CONCAT('Coordinador ', MOD(n - 1, 5) + 1),
    CASE WHEN MOD(n, 3) = 0 THEN 'RESUELTA' ELSE 'ABIERTA' END
FROM tmp_consecutivos
WHERE n <= 20;

/* ============================================================
   15. HISTORIAL DE ESTADOS (200 REGISTROS)
   ============================================================ */

INSERT INTO historial_estados_pedido
    (id_historial, id_pedido, estado_anterior, estado_nuevo,
     fecha_cambio, usuario_bd, observacion)
SELECT
    n,
    n,
    'PENDIENTE',
    CASE
        WHEN MOD(n, 10) = 0 THEN 'PENDIENTE'
        WHEN MOD(n, 10) IN (1, 2) THEN 'EN_TRANSITO'
        ELSE 'ENTREGADO'
    END,
    DATE_ADD('2026-01-01 09:00:00', INTERVAL n DAY),
    'usuario_pruebas',
    CONCAT('Cambio de estado sintetico del pedido ', n)
FROM tmp_consecutivos;

/* ============================================================
   16. AUDITORIA DE DESPACHOS (200 REGISTROS)
   ============================================================ */

INSERT INTO auditoria_despachos
    (id_auditoria, id_despacho, fecha_modificacion,
     usuario_bd, estado_anterior, estado_nuevo, observacion)
SELECT
    n,
    n,
    DATE_ADD('2026-01-02 09:00:00', INTERVAL n DAY),
    'usuario_pruebas',
    'ASIGNADO',
    CASE
        WHEN MOD(n, 10) = 0 THEN 'ASIGNADO'
        WHEN MOD(n, 10) IN (1, 2) THEN 'EN_TRANSITO'
        ELSE 'ENTREGADO'
    END,
    CONCAT('Auditoria sintetica del despacho ', n)
FROM tmp_consecutivos;

/* ============================================================
   17. RESUMEN DE CARGA
   ============================================================ */

SELECT 'municipios' AS tabla, COUNT(*) AS registros FROM municipios
UNION ALL SELECT 'tipos_vehiculo', COUNT(*) FROM tipos_vehiculo
UNION ALL SELECT 'clientes', COUNT(*) FROM clientes
UNION ALL SELECT 'productores', COUNT(*) FROM productores
UNION ALL SELECT 'productos', COUNT(*) FROM productos
UNION ALL SELECT 'conductores', COUNT(*) FROM conductores
UNION ALL SELECT 'vehiculos', COUNT(*) FROM vehiculos
UNION ALL SELECT 'rutas', COUNT(*) FROM rutas
UNION ALL SELECT 'pedidos', COUNT(*) FROM pedidos
UNION ALL SELECT 'detalle_pedidos', COUNT(*) FROM detalle_pedidos
UNION ALL SELECT 'despachos_asignaciones', COUNT(*) FROM despachos_asignaciones
UNION ALL SELECT 'entregas', COUNT(*) FROM entregas
UNION ALL SELECT 'novedades_relacionales', COUNT(*) FROM novedades_relacionales
UNION ALL SELECT 'historial_estados_pedido', COUNT(*) FROM historial_estados_pedido
UNION ALL SELECT 'auditoria_despachos', COUNT(*) FROM auditoria_despachos
ORDER BY tabla;

SELECT
    SUM(TABLE_ROWS) AS total_registros_estimados
FROM information_schema.TABLES
WHERE TABLE_SCHEMA = 'conectasucre_final'
  AND TABLE_TYPE = 'BASE TABLE';

/* ============================================================
   FIN DEL SCRIPT 02_DML.sql
   ============================================================ */
