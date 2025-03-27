DROP TABLE detalle_pedido CASCADE CONSTRAINTS;
DROP TABLE pedidos CASCADE CONSTRAINTS;
DROP TABLE platos CASCADE CONSTRAINTS;
DROP TABLE personal_servicio CASCADE CONSTRAINTS;
DROP TABLE clientes CASCADE CONSTRAINTS;

DROP SEQUENCE seq_pedidos;


-- Creación de tablas y secuencias



create sequence seq_pedidos;

CREATE TABLE clientes (
    id_cliente INTEGER PRIMARY KEY,
    nombre VARCHAR2(100) NOT NULL,
    apellido VARCHAR2(100) NOT NULL,
    telefono VARCHAR2(20)
);

CREATE TABLE personal_servicio (
    id_personal INTEGER PRIMARY KEY,
    nombre VARCHAR2(100) NOT NULL,
    apellido VARCHAR2(100) NOT NULL,
    pedidos_activos INTEGER DEFAULT 0 CHECK (pedidos_activos <= 5)
);

CREATE TABLE platos (
    id_plato INTEGER PRIMARY KEY,
    nombre VARCHAR2(100) NOT NULL,
    precio DECIMAL(10, 2) NOT NULL,
    disponible INTEGER DEFAULT 1 CHECK (DISPONIBLE in (0,1)) -- 0 Falso, 1 True
);

CREATE TABLE pedidos (
    id_pedido INTEGER PRIMARY KEY,
    id_cliente INTEGER REFERENCES clientes(id_cliente),
    id_personal INTEGER REFERENCES personal_servicio(id_personal),
    fecha_pedido DATE DEFAULT SYSDATE,
    total DECIMAL(10, 2) DEFAULT 0
);

CREATE TABLE detalle_pedido (
    id_pedido INTEGER REFERENCES pedidos(id_pedido),
    id_plato INTEGER REFERENCES platos(id_plato),
    cantidad INTEGER NOT NULL,
    PRIMARY KEY (id_pedido, id_plato)
);


	
-- Procedimiento a implementar para realizar la reserva
create or replace procedure registrar_pedido(
    arg_id_cliente      INTEGER, 
    arg_id_personal     INTEGER, 
    arg_id_primer_plato INTEGER DEFAULT NULL,
    arg_id_segundo_plato INTEGER DEFAULT NULL
) is 
 --Declaración de excepciones
 PLATOS_NO_DISPONIBLES  exception;      -- Se lanza no hay platos disponibles.
 PRAGMA EXCEPTION_INIT(PLATOS_NO_DISPONIBLES, -20001);
 
 PEDIDO_SIN_PLATO   exception;       -- Se lanza en caso de que el pedido no contenga ningun plato.
 PRAGMA EXCEPTION_INIT(PEDIDO_SIN_PLATO, -20002);
 
 MUCHO_OCUPADO  exception;      -- Se lanza si el personal ha cubierto el cupo maximo de pedidos ## Tu ah muy mucho ocupado ##.
 PRAGMA EXCEPTION_INIT(MUCHO_OCUPADO, -20003);

 disponibilidad_plato1 integer:=2; -- 0 Falso, 1 True, 2 no exisite plato
 disponibilidad_plato2 integer:=2; -- 0 Falso, 1 True, 2 no exisite plato
 arg_id_pedido integer;
 arg_total decimal(10,2):=0;
 begin

  begin
   if arg_id_primer_plato is null and arg_id_segundo_plato is null then
        raise PEDIDO_SIN_PLATO;
   end if;
    
   if arg_id_primer_plato is not null then 
        begin
            SELECT disponible into disponibilidad_plato1
              FROM platos
             WHERE id_plato = arg_id_primer_plato;
        exception
            when NO_DATA_FOUND then
                raise_application_error(-20004, 'El primer plato seleccionado no existe');
        end;
    end if;
    
  -- Verificar el segundo plato
    if arg_id_segundo_plato is not null then
        begin
            SELECT disponible into disponibilidad_plato2
              FROM platos
             WHERE id_plato = arg_id_segundo_plato;
        exception
            when NO_DATA_FOUND then
                raise_application_error(-20004, 'El segundo plato seleccionado no existe');
        end;
    end if;
    
    -- Comprobar la disponibilidad de los platos
    if disponibilidad_plato1 = 0 then
        raise PLATOS_NO_DISPONIBLES;
    end if;
    
    if disponibilidad_plato2 = 0 then
        raise PLATOS_NO_DISPONIBLES;
    end if;
    
    /*
    --Añadimos el pedido a la tabla pedidos
    insert into pedidos values(arg_id_pedido, arg_id_cliente, arg_id_personal, SYSDATE, arg_total);
    --Añadimos los detalles de pedido a la tabla detalle_pedido
    if arg_id_primer_plato is not null then
    insert into detalle_pedido values(arg_id_pedido,arg_id_primer_plato, 1);
    end if;
    
    if arg_id_segundo_plato is not null then
    insert into detalle_pedido values(arg_id_pedido, arg_id_segundo_plato, 1); -- Cantidad fija en 1, ajustar si es necesario
    end if;
    --Actualizamos la tabla personal_servicio
    update personal_servicio
    set pedidos_activos = pedidos_activos+1
    where id_personal = arg_id_personal;
    */
    COMMIT;

  -- Codigo AQUI
  -- NOTE: esto va al final del todo, despues de todo el codigo, faltaría adaptarlo a las necesidades del codigo
  -- Captura de las excepciones lanzadas.
  commit;
  exception
  when PLATOS_NO_DISPONIBLES then
    rollback;
    raise_application_error(-20001,'Uno de los platos seleccionados no está disponible.');
    
  when PEDIDO_SIN_PLATO then
    raise_application_error(-20002, 'El pedido deber contener al menos un plato.');
        
  when MUCHO_OCUPADO then
    raise_application_error(-20003, 'El personal de servicio tiene demasiados pedidos');
    
  when others then 
    rollback;
    raise;
  end;
end;
/

------ Deja aquí tus respuestas a las preguntas del enunciado:
-- NO SE CORREGIRÁN RESPUESTAS QUE NO ESTÉN AQUÍ (utiliza el espacio que necesites apra cada una)
-- * P4.1
-- En el código proporcionado, existe una restricción en la tabla personal_servicio que limita la cantidad de pedidos activos que puede tener un miembro del personal de servicio:
-- pedidos_activos INTEGER DEFAULT 0 CHECK (pedidos_activos <= 5)
-- Para garantizar que un miembro del personal de servicio no supere el límite, se debería agregar una consulta que verifique el número de pedidos activos antes de asignarle un nuevo pedido.
-- Esto permitiría capturar la condición antes de insertar el pedido en la base de datos.
-- Sin esta verificación, el procedimiento no está realmente garantizando que el personal no supere el límite de pedidos activos.
-- Y aqui te dejo el fragmento de código:
-- * P4.2
-- Para evitar que dos transacciones concurrentes asignen un pedido al mismo miembro del personal de servicio y superen el límite de pedidos activos, se deben aplicar mecanismos de control de concurrencia.
-- 1. Uso de SELECT ... FOR UPDATE (Bloqueo de fila)
/* DECLARE pedidos_actuales INTEGER;
   BEGIN
    -- Bloqueamos la fila del personal seleccionado
    SELECT pedidos_activos INTO pedidos_actuales 
    FROM personal_servicio 
    WHERE id_personal = arg_id_personal
    FOR UPDATE;  -- 🔒 Bloquea la fila hasta que se haga COMMIT o ROLLBACK

    IF pedidos_actuales >= 5 THEN
        raise MUCHO_OCUPADO;
    END IF;

    -- Continuar con la lógica de inserción del pedido
    ...
*/
-- 2. Uso de Aislamiento de Transacciones (SERIALIZABLE)
-- SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
-- Esto evita que dos transacciones vean la misma información al mismo tiempo.
-- * P4.3
--
-- * P4.4
--
-- * P4.5
-- 


create or replace
procedure reset_seq( p_seq_name varchar )
is
    l_val number;
begin
    execute immediate
    'select ' || p_seq_name || '.nextval from dual' INTO l_val;

    execute immediate
    'alter sequence ' || p_seq_name || ' increment by -' || l_val || 
                                                          ' minvalue 0';
    execute immediate
    'select ' || p_seq_name || '.nextval from dual' INTO l_val;

    execute immediate
    'alter sequence ' || p_seq_name || ' increment by 1 minvalue 0';

end;
/


create or replace procedure inicializa_test is
begin
    
    reset_seq('seq_pedidos');
        
  
    delete from Detalle_pedido;
    delete from Pedidos;
    delete from Platos;
    delete from Personal_servicio;
    delete from Clientes;
    
    -- Insertar datos de prueba
    insert into Clientes (id_cliente, nombre, apellido, telefono) values (1, 'Pepe', 'Perez', '123456789');
    insert into Clientes (id_cliente, nombre, apellido, telefono) values (2, 'Ana', 'Garcia', '987654321');
    
    insert into Personal_servicio (id_personal, nombre, apellido, pedidos_activos) values (1, 'Carlos', 'Lopez', 0);
    insert into Personal_servicio (id_personal, nombre, apellido, pedidos_activos) values (2, 'Maria', 'Fernandez', 5);
    
    insert into Platos (id_plato, nombre, precio, disponible) values (1, 'Sopa', 10.0, 1);
    insert into Platos (id_plato, nombre, precio, disponible) values (2, 'Pasta', 12.0, 1);
    insert into Platos (id_plato, nombre, precio, disponible) values (3, 'Carne', 15.0, 0);

    commit;
end;
/

exec inicializa_test;

-- Completa lost test, incluyendo al menos los del enunciado y añadiendo los que consideres necesarios

create or replace procedure test_registrar_pedido is
begin
	 
  --Caso 1 Pedido correct, se realiza
  begin
    inicializa_test;
    registrar_pedido(1,2,1,2);
    dbms_output.put_line('Detecta OK pedido: '||sqlerrm);
  exception
    when others then
      dbms_output.put_line('Mal no detecta pedido: '||sqlerrm);
  end;
  
  
  --Caso 2: Si se realiza un pedido vacío (sin platos) devuelve el error -20002.
  begin
    inicializa_test;
    registrar_pedido(1,2);
    dbms_output.put_line('Mal no detecta PEDIDO_SIN_PLATO');
  exception
    when others then
      if sqlcode = -20002 then
        dbms_output.put_line('Detecta OK PEDIDO_SIN_PLATO: '||sqlerrm);
      else
        dbms_output.put_line('Mal no detecta PEDIDO_SIN_PLATO: '||sqlerrm);
      end if;
  end;
  
  --Caso 3: Si se realiza un pedido con un plato que no existe devuelve en error -20004.
  --Caso 3.1 --> no exisite el plato 1
  begin
    inicializa_test;
    registrar_pedido(1,2,87,NULL);
    dbms_output.put_line('Mal no detecta PLATO_INEXISTENTE');
  exception
    when others then
      if sqlcode = -20004 then
        dbms_output.put_line('Detecta OK PLATO_INEXISTENTE: '||sqlerrm);
      else
        dbms_output.put_line('Mal no detecta PLATO_INEXISTENTE: '||sqlerrm);
      end if;
  end;
  
  -- Caso 3.2 --> No exisite el plato 2
  begin
    inicializa_test;
    registrar_pedido(1,2,NULL,100);
    dbms_output.put_line('Mal no detecta PLATO_INEXISTENTE');
  exception
    when others then
      if sqlcode = -20004 then
        dbms_output.put_line('Detecta OK PLATO_INEXISTENTE: '||sqlerrm);
      else
        dbms_output.put_line('Mal no detecta PLATO_INEXISTENTE: '||sqlerrm);
      end if;
  end;
  
  -- Caso 3.3 --> Exisite el plato 2 pero no el 1
  begin
    inicializa_test;
    registrar_pedido(1,2,87,1);
    dbms_output.put_line('Mal no detecta PLATO_INEXISTENTE');
  exception
    when others then
      if sqlcode = -20004 then
        dbms_output.put_line('Detecta OK PLATO_INEXISTENTE: '||sqlerrm);
      else
        dbms_output.put_line('Mal no detecta PLATO_INEXISTENTE: '||sqlerrm);
      end if;
  end;
  
  -- Caso 3.4 --> Exisite el plato 1 pero no el 2
  begin
    inicializa_test;
    registrar_pedido(1,2,1,100);
    dbms_output.put_line('Mal no detecta PLATO_INEXISTENTE');
  exception
    when others then
      if sqlcode = -20004 then
        dbms_output.put_line('Detecta OK PLATO_INEXISTENTE: '||sqlerrm);
      else
        dbms_output.put_line('Mal no detecta PLATO_INEXISTENTE: '||sqlerrm);
      end if;
  end;

  --Caso 4: Si se realiza un pedido que incluye un plato que no est´a ya disponible devuelve el error -20001.
  --Caso 4.1 --> plato null y plato no disponible
  begin
    inicializa_test;
    registrar_pedido(1,1,3,NULL);
    dbms_output.put_line('Mal no detecta PLATOS_NO_DISPONIBLES');
  exception
    when others then
      if sqlcode = -20001 then
        dbms_output.put_line('Detecta OK PLATOS_NO_DISPONIBLES: '||sqlerrm);
      else
        dbms_output.put_line('Mal no detecta PLATOS_NO_DISPONIBLES: '||sqlerrm);
      end if;
  end;
  
  --Caso 4.2 --> Plato no disponible, y plato disponible
  begin
    inicializa_test;
    registrar_pedido(1,1,3,1);
    dbms_output.put_line('Mal no detecta PLATOS_NO_DISPONIBLES');
  exception
    when others then
      if sqlcode = -20001 then
        dbms_output.put_line('Detecta OK PLATOS_NO_DISPONIBLES: '||sqlerrm);
      else
        dbms_output.put_line('Mal no detecta PLATOS_NO_DISPONIBLES: '||sqlerrm);
      end if;
  end;
  /*
  --Caso 5: Personal de servicio ya tiene 5 pedidos activos y se le asigna otro pedido devuelve el error -20003
  begin
    inicializa_test;
    registrar_pedido(1,2,1,2);
    dbms_output.put_line('Mal no detecta MUCHO_OCUPADO');
  exception
    when others then
      if sqlcode = -20003 then
        dbms_output.put_line('Detecta OK MUCHO_OCUPADO: '||sqlerrm);
      else
        dbms_output.put_line('Mal no detecta MUCHO_OCUPADO: '||sqlerrm);
      end if;
  end;
    */

-- ... los que os puedan ocurrir que puedan ser necesarios para comprobar el correcto funcionamiento del procedimiento

end;
/


set serveroutput on;
exec test_registrar_pedido;