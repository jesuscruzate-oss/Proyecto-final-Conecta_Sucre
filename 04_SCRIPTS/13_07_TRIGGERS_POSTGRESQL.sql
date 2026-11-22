-- CONECTASUCRE | 13.07 | Migracion de cinco triggers desde MySQL a PostgreSQL 17
-- Fuente: CSV_EE5.csv. Destino: conectasucre_final / esquema public.
-- Instala funciones y disparadores; NO modifica los 1.350 registros existentes.
-- Ejecutar UNA vez en pgAdmin > Query Tool, conectado a conectasucre_final.
-- Los triggers se activan para operaciones FUTURAS, no recalculan datos existentes.

BEGIN;

-- 1. Validar peso, estado del vehiculo y disponibilidad del conductor al asignar.
CREATE FUNCTION public.cs_trg_validar_despacho_bi_fn()
RETURNS trigger
LANGUAGE plpgsql
AS $fn$
DECLARE
    v_capacidad numeric(12,2);
    v_estado_vehiculo varchar(25);
    v_estado_conductor varchar(20);
    v_peso_pedido numeric(12,2);
BEGIN
    SELECT ve.capacidad_carga_kg, ve.estado_vehiculo,
           co.estado_conductor, pe.peso_total_kg
      INTO v_capacidad, v_estado_vehiculo, v_estado_conductor, v_peso_pedido
      FROM public.vehiculos ve
      JOIN public.conductores co ON co.id_conductor = NEW.id_conductor
      JOIN public.pedidos pe ON pe.id_pedido = NEW.id_pedido
     WHERE ve.id_vehiculo = NEW.id_vehiculo;

    IF NOT FOUND OR v_capacidad IS NULL THEN
        RAISE EXCEPTION 'No fue posible validar el vehiculo, conductor o pedido'
          USING ERRCODE = 'P0001';
    END IF;
    IF v_estado_vehiculo <> 'DISPONIBLE' THEN
        RAISE EXCEPTION 'El vehiculo no esta disponible' USING ERRCODE = 'P0001';
    END IF;
    IF v_estado_conductor <> 'DISPONIBLE' THEN
        RAISE EXCEPTION 'El conductor no esta disponible' USING ERRCODE = 'P0001';
    END IF;
    IF v_peso_pedido > v_capacidad THEN
        RAISE EXCEPTION 'El peso del pedido supera la capacidad del vehiculo'
          USING ERRCODE = 'P0001';
    END IF;
    RETURN NEW;
END;
$fn$;

CREATE TRIGGER trg_validar_despacho_bi
BEFORE INSERT ON public.despachos_asignaciones
FOR EACH ROW EXECUTE FUNCTION public.cs_trg_validar_despacho_bi_fn();

-- 2. Auditar cuando cambia el estado de un despacho; equivalencia MySQL <=>.
CREATE FUNCTION public.cs_trg_auditar_despacho_au_fn()
RETURNS trigger
LANGUAGE plpgsql
AS $fn$
BEGIN
    IF OLD.estado_despacho IS DISTINCT FROM NEW.estado_despacho THEN
        INSERT INTO public.auditoria_despachos
            (id_despacho, fecha_modificacion, usuario_bd,
             estado_anterior, estado_nuevo, observacion)
        VALUES
            (NEW.id_despacho, CURRENT_TIMESTAMP, CURRENT_USER,
             OLD.estado_despacho, NEW.estado_despacho,
             'Cambio de estado registrado automaticamente por trigger');
    END IF;
    RETURN NEW;
END;
$fn$;

CREATE TRIGGER trg_auditar_despacho_au
AFTER UPDATE ON public.despachos_asignaciones
FOR EACH ROW EXECUTE FUNCTION public.cs_trg_auditar_despacho_au_fn();

-- 3. Agregar subtotal y peso al insertar un detalle de pedido.
CREATE FUNCTION public.cs_trg_detalle_pedido_ai_fn()
RETURNS trigger
LANGUAGE plpgsql
AS $fn$
BEGIN
    UPDATE public.pedidos
       SET valor_total = valor_total + NEW.subtotal,
           peso_total_kg = peso_total_kg + (NEW.cantidad * NEW.peso_unitario_kg)
     WHERE id_pedido = NEW.id_pedido;
    RETURN NEW;
END;
$fn$;

CREATE TRIGGER trg_detalle_pedido_ai
AFTER INSERT ON public.detalle_pedidos
FOR EACH ROW EXECUTE FUNCTION public.cs_trg_detalle_pedido_ai_fn();

-- 4. Descontar subtotal y peso al eliminar un detalle de pedido.
CREATE FUNCTION public.cs_trg_detalle_pedido_ad_fn()
RETURNS trigger
LANGUAGE plpgsql
AS $fn$
BEGIN
    UPDATE public.pedidos
       SET valor_total = valor_total - OLD.subtotal,
           peso_total_kg = peso_total_kg - (OLD.cantidad * OLD.peso_unitario_kg)
     WHERE id_pedido = OLD.id_pedido;
    RETURN OLD;
END;
$fn$;

CREATE TRIGGER trg_detalle_pedido_ad
AFTER DELETE ON public.detalle_pedidos
FOR EACH ROW EXECUTE FUNCTION public.cs_trg_detalle_pedido_ad_fn();

-- 5. Ajustar totales cuando se edita un detalle o cambia de pedido.
CREATE FUNCTION public.cs_trg_detalle_pedido_au_fn()
RETURNS trigger
LANGUAGE plpgsql
AS $fn$
BEGIN
    IF NEW.id_pedido = OLD.id_pedido THEN
        UPDATE public.pedidos
           SET valor_total = valor_total + (NEW.subtotal - OLD.subtotal),
               peso_total_kg = peso_total_kg
                   + (NEW.cantidad * NEW.peso_unitario_kg
                      - OLD.cantidad * OLD.peso_unitario_kg)
         WHERE id_pedido = NEW.id_pedido;
    ELSE
        UPDATE public.pedidos
           SET valor_total = valor_total - OLD.subtotal,
               peso_total_kg = peso_total_kg
                   - (OLD.cantidad * OLD.peso_unitario_kg)
         WHERE id_pedido = OLD.id_pedido;

        UPDATE public.pedidos
           SET valor_total = valor_total + NEW.subtotal,
               peso_total_kg = peso_total_kg
                   + (NEW.cantidad * NEW.peso_unitario_kg)
         WHERE id_pedido = NEW.id_pedido;
    END IF;
    RETURN NEW;
END;
$fn$;

CREATE TRIGGER trg_detalle_pedido_au
AFTER UPDATE ON public.detalle_pedidos
FOR EACH ROW EXECUTE FUNCTION public.cs_trg_detalle_pedido_au_fn();

-- Confirmar que existen exactamente los cinco triggers creados por este script.
DO $check$
DECLARE v_total integer;
BEGIN
    SELECT count(*) INTO v_total
      FROM pg_trigger t
      JOIN pg_class c ON c.oid = t.tgrelid
      JOIN pg_namespace n ON n.oid = c.relnamespace
     WHERE n.nspname = 'public' AND NOT t.tgisinternal
       AND t.tgname IN (
          'trg_validar_despacho_bi', 'trg_auditar_despacho_au',
          'trg_detalle_pedido_ai', 'trg_detalle_pedido_ad', 'trg_detalle_pedido_au'
       );
    IF v_total <> 5 THEN
        RAISE EXCEPTION 'Se esperaban 5 triggers ConectaSucre; encontrados: %', v_total;
    END IF;
END;
$check$;

COMMIT;

-- Resultado de verificacion (5 filas, enabled = O).
SELECT c.relname AS tabla, t.tgname AS trigger, 
       CASE t.tgenabled WHEN 'O' THEN 'ACTIVO' ELSE 'REVISAR' END AS estado
  FROM pg_trigger t
  JOIN pg_class c ON c.oid = t.tgrelid
  JOIN pg_namespace n ON n.oid = c.relnamespace
 WHERE n.nspname = 'public' AND NOT t.tgisinternal
   AND t.tgname IN (
      'trg_validar_despacho_bi', 'trg_auditar_despacho_au',
      'trg_detalle_pedido_ai', 'trg_detalle_pedido_ad', 'trg_detalle_pedido_au'
   )
 ORDER BY c.relname, t.tgname;
