
/* =========================================================
   PROYECTO: CONECTASUCRE - MODELO FINAL
   INSTITUCION: CECAR
   SCRIPT: 01_DDL_FINAL.sql
   MOTOR: MySQL 8.0 Community Edition
   MOTOR DE ALMACENAMIENTO: InnoDB
   CODIFICACION: UTF8MB4
   DESCRIPCION: Creacion del modelo relacional
   ========================================================= */


/* NOTA DE SEGURIDAD:
   Este script crea un esquema NUEVO llamado conectasucre_final.
   No elimina ni modifica la base existente conectasucre.
   Ejecutar el script completo una sola vez sobre MySQL 9.7.
   ========================================================= */


/* =========================================================
   1. CREACION DE LA BASE DE DATOS
   ========================================================= */

CREATE DATABASE IF NOT EXISTS conectasucre_final
CHARACTER SET utf8mb4
COLLATE utf8mb4_0900_ai_ci;

USE conectasucre_final;


/* =========================================================
   2. TABLA: MUNICIPIOS
   ========================================================= */

CREATE TABLE municipios (
    id_municipio INT UNSIGNED AUTO_INCREMENT,
    nombre_municipio VARCHAR(100) NOT NULL,
    departamento VARCHAR(100) NOT NULL DEFAULT 'Sucre',

    PRIMARY KEY (id_municipio),
    UNIQUE KEY uk_municipio (nombre_municipio, departamento)
) ENGINE=InnoDB;


/* =========================================================
   3. TABLA: CLIENTES
   ========================================================= */

CREATE TABLE clientes (
    id_cliente INT UNSIGNED AUTO_INCREMENT,
    tipo_documento VARCHAR(15) NOT NULL,
    numero_documento VARCHAR(30) NOT NULL,
    nombre_comercial VARCHAR(150) NOT NULL,
    nombre_contacto VARCHAR(120),
    telefono VARCHAR(25),
    correo VARCHAR(120),
    direccion VARCHAR(200),
    id_municipio INT UNSIGNED NOT NULL,
    fecha_registro DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    estado_cliente VARCHAR(15) NOT NULL DEFAULT 'ACTIVO',

    PRIMARY KEY (id_cliente),
    UNIQUE KEY uk_cliente_documento
        (tipo_documento, numero_documento),

    CONSTRAINT fk_cliente_municipio
        FOREIGN KEY (id_municipio)
        REFERENCES municipios(id_municipio)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    CONSTRAINT chk_cliente_estado
        CHECK (estado_cliente IN ('ACTIVO','INACTIVO'))
) ENGINE=InnoDB;


/* =========================================================
   4. TABLA: PRODUCTORES
   ========================================================= */

CREATE TABLE productores (
    id_productor INT UNSIGNED AUTO_INCREMENT,
    tipo_documento VARCHAR(15) NOT NULL,
    numero_documento VARCHAR(30) NOT NULL,
    nombre_productor VARCHAR(150) NOT NULL,
    telefono VARCHAR(25),
    correo VARCHAR(120),
    direccion VARCHAR(200),
    id_municipio INT UNSIGNED NOT NULL,
    estado_productor VARCHAR(15) NOT NULL DEFAULT 'ACTIVO',

    PRIMARY KEY (id_productor),
    UNIQUE KEY uk_productor_documento
        (tipo_documento, numero_documento),

    CONSTRAINT fk_productor_municipio
        FOREIGN KEY (id_municipio)
        REFERENCES municipios(id_municipio)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    CONSTRAINT chk_productor_estado
        CHECK (estado_productor IN ('ACTIVO','INACTIVO'))
) ENGINE=InnoDB;


/* =========================================================
   5. TABLA: PRODUCTOS
   ========================================================= */

CREATE TABLE productos (
    id_producto INT UNSIGNED AUTO_INCREMENT,
    id_productor INT UNSIGNED NOT NULL,
    codigo_producto VARCHAR(40) NOT NULL,
    nombre_producto VARCHAR(150) NOT NULL,
    descripcion TEXT,
    unidad_medida VARCHAR(30) NOT NULL,
    peso_unitario_kg DECIMAL(10,3) NOT NULL,
    precio_unitario DECIMAL(14,2) NOT NULL,
    estado_producto VARCHAR(15) NOT NULL DEFAULT 'ACTIVO',

    PRIMARY KEY (id_producto),
    UNIQUE KEY uk_producto_codigo (codigo_producto),

    CONSTRAINT fk_producto_productor
        FOREIGN KEY (id_productor)
        REFERENCES productores(id_productor)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    CONSTRAINT chk_producto_peso
        CHECK (peso_unitario_kg > 0),

    CONSTRAINT chk_producto_precio
        CHECK (precio_unitario >= 0),

    CONSTRAINT chk_producto_estado
        CHECK (estado_producto IN ('ACTIVO','INACTIVO'))
) ENGINE=InnoDB;


/* =========================================================
   6. TABLA: TIPOS_VEHICULO
   Catalogo normalizado de tipos de vehiculo
   ========================================================= */

CREATE TABLE tipos_vehiculo (
    id_tipo_vehiculo INT UNSIGNED AUTO_INCREMENT,
    nombre_tipo VARCHAR(60) NOT NULL,
    descripcion VARCHAR(200),
    PRIMARY KEY (id_tipo_vehiculo),
    UNIQUE KEY uk_tipo_vehiculo_nombre (nombre_tipo)
) ENGINE=InnoDB;


/* =========================================================
   7. TABLA: VEHICULOS
   ========================================================= */

CREATE TABLE vehiculos (
    id_vehiculo INT UNSIGNED AUTO_INCREMENT,
    placa VARCHAR(10) NOT NULL,
    id_tipo_vehiculo INT UNSIGNED NOT NULL,
    marca VARCHAR(60),
    modelo VARCHAR(60),
    anio YEAR,
    capacidad_carga_kg DECIMAL(12,2) NOT NULL,
    estado_vehiculo VARCHAR(25) NOT NULL DEFAULT 'DISPONIBLE',

    PRIMARY KEY (id_vehiculo),
    UNIQUE KEY uk_vehiculo_placa (placa),

    CONSTRAINT fk_vehiculo_tipo
        FOREIGN KEY (id_tipo_vehiculo)
        REFERENCES tipos_vehiculo(id_tipo_vehiculo)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    CONSTRAINT chk_vehiculo_capacidad
        CHECK (capacidad_carga_kg > 0),

    CONSTRAINT chk_vehiculo_estado
        CHECK (estado_vehiculo IN (
            'DISPONIBLE',
            'EN_RUTA',
            'EN_MANTENIMIENTO',
            'FUERA_DE_SERVICIO'
        ))
) ENGINE=InnoDB;


/* =========================================================
   7. TABLA: CONDUCTORES
   ========================================================= */

CREATE TABLE conductores (
    id_conductor INT UNSIGNED AUTO_INCREMENT,
    tipo_documento VARCHAR(15) NOT NULL,
    numero_documento VARCHAR(30) NOT NULL,
    nombres VARCHAR(100) NOT NULL,
    apellidos VARCHAR(100) NOT NULL,
    telefono VARCHAR(25),
    numero_licencia VARCHAR(40) NOT NULL,
    categoria_licencia VARCHAR(10) NOT NULL,
    fecha_vencimiento_licencia DATE,
    estado_conductor VARCHAR(20) NOT NULL DEFAULT 'DISPONIBLE',

    PRIMARY KEY (id_conductor),

    UNIQUE KEY uk_conductor_documento
        (tipo_documento, numero_documento),

    UNIQUE KEY uk_conductor_licencia
        (numero_licencia),

    CONSTRAINT chk_conductor_estado
        CHECK (estado_conductor IN (
            'DISPONIBLE',
            'EN_RUTA',
            'INACTIVO'
        ))
) ENGINE=InnoDB;


/* =========================================================
   8. TABLA: RUTAS
   ========================================================= */

CREATE TABLE rutas (
    id_ruta INT UNSIGNED AUTO_INCREMENT,
    nombre_ruta VARCHAR(120) NOT NULL,
    id_municipio_origen INT UNSIGNED NOT NULL,
    id_municipio_destino INT UNSIGNED NOT NULL,
    distancia_km DECIMAL(10,2),
    tiempo_estimado_horas DECIMAL(8,2),
    descripcion TEXT,
    estado_ruta VARCHAR(15) NOT NULL DEFAULT 'ACTIVA',

    PRIMARY KEY (id_ruta),

    CONSTRAINT fk_ruta_origen
        FOREIGN KEY (id_municipio_origen)
        REFERENCES municipios(id_municipio),

    CONSTRAINT fk_ruta_destino
        FOREIGN KEY (id_municipio_destino)
        REFERENCES municipios(id_municipio),

    CONSTRAINT chk_ruta_distancia
        CHECK (distancia_km IS NULL OR distancia_km > 0),

    CONSTRAINT chk_ruta_tiempo
        CHECK (tiempo_estimado_horas IS NULL
               OR tiempo_estimado_horas > 0),

    CONSTRAINT chk_ruta_estado
        CHECK (estado_ruta IN ('ACTIVA','INACTIVA'))
) ENGINE=InnoDB;


/* =========================================================
   9. TABLA: PEDIDOS
   ========================================================= */

CREATE TABLE pedidos (
    id_pedido INT UNSIGNED AUTO_INCREMENT,
    numero_pedido VARCHAR(30) NOT NULL,
    id_cliente INT UNSIGNED NOT NULL,
    id_municipio_destino INT UNSIGNED NOT NULL,
    fecha_pedido DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_entrega_prometida DATETIME NOT NULL,
    peso_total_kg DECIMAL(12,2) NOT NULL DEFAULT 0,
    valor_total DECIMAL(14,2) NOT NULL DEFAULT 0,
    estado_pedido VARCHAR(25) NOT NULL DEFAULT 'PENDIENTE',
    observaciones TEXT,

    PRIMARY KEY (id_pedido),
    UNIQUE KEY uk_pedido_numero (numero_pedido),

    CONSTRAINT fk_pedido_cliente
        FOREIGN KEY (id_cliente)
        REFERENCES clientes(id_cliente)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    CONSTRAINT fk_pedido_municipio
        FOREIGN KEY (id_municipio_destino)
        REFERENCES municipios(id_municipio)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    CONSTRAINT chk_pedido_peso
        CHECK (peso_total_kg >= 0),

    CONSTRAINT chk_pedido_valor
        CHECK (valor_total >= 0),

    CONSTRAINT chk_pedido_estado
        CHECK (estado_pedido IN (
            'PENDIENTE',
            'EN_PREPARACION',
            'EN_TRANSITO',
            'ENTREGADO',
            'CANCELADO'
        )),

    INDEX idx_pedido_estado (estado_pedido),
    INDEX idx_pedido_fecha (fecha_pedido)
) ENGINE=InnoDB;


/* =========================================================
   10. TABLA: DETALLE_PEDIDOS
   ========================================================= */

CREATE TABLE detalle_pedidos (
    id_detalle INT UNSIGNED AUTO_INCREMENT,
    id_pedido INT UNSIGNED NOT NULL,
    id_producto INT UNSIGNED NOT NULL,
    cantidad DECIMAL(12,3) NOT NULL,
    precio_unitario DECIMAL(14,2) NOT NULL,
    peso_unitario_kg DECIMAL(10,3) NOT NULL,
    subtotal DECIMAL(14,2)
        GENERATED ALWAYS AS (cantidad * precio_unitario) STORED,

    PRIMARY KEY (id_detalle),

    CONSTRAINT fk_detalle_pedido
        FOREIGN KEY (id_pedido)
        REFERENCES pedidos(id_pedido)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    CONSTRAINT fk_detalle_producto
        FOREIGN KEY (id_producto)
        REFERENCES productos(id_producto)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    CONSTRAINT chk_detalle_cantidad
        CHECK (cantidad > 0),

    CONSTRAINT chk_detalle_precio
        CHECK (precio_unitario >= 0),

    CONSTRAINT chk_detalle_peso
        CHECK (peso_unitario_kg > 0),

    INDEX idx_detalle_pedido (id_pedido)
) ENGINE=InnoDB;


/* =========================================================
   11. TABLA: DESPACHOS_ASIGNACIONES
   ========================================================= */

CREATE TABLE despachos_asignaciones (
    id_despacho INT UNSIGNED AUTO_INCREMENT,
    id_pedido INT UNSIGNED NOT NULL,
    id_vehiculo INT UNSIGNED NOT NULL,
    id_conductor INT UNSIGNED NOT NULL,
    id_ruta INT UNSIGNED NOT NULL,

    fecha_asignacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_salida DATETIME,
    estado_despacho VARCHAR(20) NOT NULL DEFAULT 'ASIGNADO',

    PRIMARY KEY (id_despacho),

    CONSTRAINT fk_despacho_pedido
        FOREIGN KEY (id_pedido)
        REFERENCES pedidos(id_pedido)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    CONSTRAINT fk_despacho_vehiculo
        FOREIGN KEY (id_vehiculo)
        REFERENCES vehiculos(id_vehiculo)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    CONSTRAINT fk_despacho_conductor
        FOREIGN KEY (id_conductor)
        REFERENCES conductores(id_conductor)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    CONSTRAINT fk_despacho_ruta
        FOREIGN KEY (id_ruta)
        REFERENCES rutas(id_ruta)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    CONSTRAINT chk_despacho_estado
        CHECK (estado_despacho IN (
            'ASIGNADO',
            'EN_TRANSITO',
            'ENTREGADO',
            'CANCELADO'
        )),

    INDEX idx_despacho_pedido_estado
        (id_pedido, estado_despacho),

    INDEX idx_despacho_vehiculo_estado
        (id_vehiculo, estado_despacho),

    INDEX idx_despacho_conductor_estado
        (id_conductor, estado_despacho)
) ENGINE=InnoDB;


/* =========================================================
   12. TABLA: ENTREGAS
   ========================================================= */

CREATE TABLE entregas (
    id_entrega INT UNSIGNED AUTO_INCREMENT,
    id_despacho INT UNSIGNED NOT NULL,
    fecha_entrega_real DATETIME,
    peso_entregado_kg DECIMAL(12,2) NOT NULL DEFAULT 0,
    estado_entrega VARCHAR(20) NOT NULL DEFAULT 'PENDIENTE',
    nombre_receptor VARCHAR(120),
    observaciones TEXT,

    PRIMARY KEY (id_entrega),

    CONSTRAINT fk_entrega_despacho
        FOREIGN KEY (id_despacho)
        REFERENCES despachos_asignaciones(id_despacho)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    CONSTRAINT chk_entrega_peso
        CHECK (peso_entregado_kg >= 0),

    CONSTRAINT chk_entrega_estado
        CHECK (estado_entrega IN (
            'PENDIENTE',
            'COMPLETA',
            'PARCIAL',
            'RECHAZADA'
        )),

    INDEX idx_entrega_despacho (id_despacho),
    INDEX idx_entrega_fecha (fecha_entrega_real)
) ENGINE=InnoDB;


/* =========================================================
   13. TABLA: NOVEDADES_RELACIONALES
   ========================================================= */

CREATE TABLE novedades_relacionales (
    id_novedad INT UNSIGNED AUTO_INCREMENT,
    id_despacho INT UNSIGNED,
    id_entrega INT UNSIGNED,
    id_ruta INT UNSIGNED,
    tipo_novedad VARCHAR(60) NOT NULL,
    descripcion TEXT NOT NULL,
    fecha_novedad DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    minutos_retraso INT UNSIGNED NOT NULL DEFAULT 0,
    responsable VARCHAR(120),
    estado_novedad VARCHAR(20) NOT NULL DEFAULT 'ABIERTA',

    PRIMARY KEY (id_novedad),

    CONSTRAINT fk_novedad_despacho
        FOREIGN KEY (id_despacho)
        REFERENCES despachos_asignaciones(id_despacho),

    CONSTRAINT fk_novedad_entrega
        FOREIGN KEY (id_entrega)
        REFERENCES entregas(id_entrega),

    CONSTRAINT fk_novedad_ruta
        FOREIGN KEY (id_ruta)
        REFERENCES rutas(id_ruta),

    CONSTRAINT chk_novedad_asociacion
        CHECK (
            id_despacho IS NOT NULL
            OR id_entrega IS NOT NULL
            OR id_ruta IS NOT NULL
        ),

    CONSTRAINT chk_novedad_estado
        CHECK (estado_novedad IN (
            'ABIERTA',
            'EN_REVISION',
            'RESUELTA'
        )),

    INDEX idx_novedad_fecha (fecha_novedad)
) ENGINE=InnoDB;


/* =========================================================
   14. TABLA: HISTORIAL_ESTADOS_PEDIDO
   ========================================================= */

CREATE TABLE historial_estados_pedido (
    id_historial INT UNSIGNED AUTO_INCREMENT,
    id_pedido INT UNSIGNED NOT NULL,
    estado_anterior VARCHAR(25),
    estado_nuevo VARCHAR(25) NOT NULL,
    fecha_cambio DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    usuario_bd VARCHAR(100),
    observacion VARCHAR(300),

    PRIMARY KEY (id_historial),

    CONSTRAINT fk_historial_pedido
        FOREIGN KEY (id_pedido)
        REFERENCES pedidos(id_pedido)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    INDEX idx_historial_pedido_fecha
        (id_pedido, fecha_cambio)
) ENGINE=InnoDB;


/* =========================================================
   15. TABLA: AUDITORIA_DESPACHOS
   ========================================================= */

CREATE TABLE auditoria_despachos (
    id_auditoria INT UNSIGNED AUTO_INCREMENT,
    id_despacho INT UNSIGNED NOT NULL,
    fecha_modificacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    usuario_bd VARCHAR(100) NOT NULL,
    estado_anterior VARCHAR(20),
    estado_nuevo VARCHAR(20) NOT NULL,
    observacion VARCHAR(300),

    PRIMARY KEY (id_auditoria),

    CONSTRAINT fk_auditoria_despacho
        FOREIGN KEY (id_despacho)
        REFERENCES despachos_asignaciones(id_despacho)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    INDEX idx_auditoria_despacho_fecha
        (id_despacho, fecha_modificacion)
) ENGINE=InnoDB;


/* =========================================================
   16. VERIFICACION DE LA ESTRUCTURA
   ========================================================= */

SELECT
    TABLE_NAME,
    ENGINE,
    TABLE_ROWS
FROM information_schema.TABLES
WHERE TABLE_SCHEMA = 'conectasucre_final'
ORDER BY TABLE_NAME;

-- Verificar cantidad de tablas (15 tablas esperadas)
SELECT COUNT(*) AS total_tablas
FROM information_schema.TABLES
WHERE TABLE_SCHEMA = 'conectasucre_final'
AND TABLE_TYPE = 'BASE TABLE';

-- Mostrar las tablas creadas
SHOW TABLES;
