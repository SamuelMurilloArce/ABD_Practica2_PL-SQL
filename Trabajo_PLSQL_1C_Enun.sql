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
 
 NO_EXISTE_1    exception;     --Se lanza si el plato 1 no exisite.
 PRAGMA EXCEPTION_INIT(NO_EXISTE_1, -20004);

 NO_EXISTE_2   exception;     --Se lanza si el plato 2 no exisite
 PRAGMA EXCEPTION_INIT(NO_EXISTE_2, -20004);

 disponibilidad_plato1 integer:=2; -- 0 Falso, 1 True, 2 no exisite plato
 disponibilidad_plato2 integer:=2; -- 0 Falso, 1 True, 2 no exisite plato
 arg_id_pedido integer;
 arg_total decimal(10,2):=0;
 begin

  begin
   -- Comprobamos si esta disponible el plato 1
   SELECT disponible as disponibilidad_plato1
   FROM platos
   WHERE id_plato = arg_id_primer_plato;
 
   -- Comprobamos si esta disponible el plato 2
   SELECT disponible as disponibilidad_plato2
   FROM platos
   WHERE id_plato = arg_id_segundo_plato;

   -- Except 1 y 4 plato 1
    if arg_id_primer_plato != NULL then
   
        if arg_id_primer_plato = 0 then
            raise PLATOS_NO_DISPONIBLES;
        end if;

    else
        raise NO_EXISTE_1;
    end if;
   
   -- Except 1 y 4 plato 2
    if arg_id_segundo_plato != NULL then 

        if arg_id_segundo_plato = 0 then
            raise PLATOS_NO_DISPONIBLES;
        end if;

    else
        raise NO_EXISTE_2;
    end if;
    
    --Añadimos el pedido a la tabla pedidos
    insert into pedidos values(arg_id_pedido, arg_id_cliente, arg_id_personal, SYSDATE, arg_total);
    --Añadimos los detalles de pedido a la tabla detalle_pedido
    insert into detalle_pedido values(arg_id_pedido, );
    --Actualizamos la tabla personal_servicio
    update personal_servicio
    set pedidos_activos = pedidos_activos+1
    where id_personal = arg_id_personal;
    
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

  when NO_EXISTE_1 then
    raise_application_error(-20004, 'El primer plato seleccionado no exisite');

  when NO_EXISTE_2 then
    raise_application_error(-20004, 'El segundo plato seleccionado no exisite');
    
  when others then 
    rollback;
    raise;
  end;
end;
/

------ Deja aquí tus respuestas a las preguntas del enunciado:
-- NO SE CORREGIRÁN RESPUESTAS QUE NO ESTÉN AQUÍ (utiliza el espacio que necesites apra cada una)
-- * P4.1
--
-- * P4.2
--
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
    
    insert into Platos (id_plato, nombre, precio, disponible) values (1, 'Sopa', 10.0, TRUE);
    insert into Platos (id_plato, nombre, precio, disponible) values (2, 'Pasta', 12.0, TRUE);
    insert into Platos (id_plato, nombre, precio, disponible) values (3, 'Carne', 15.0, FALSE);

    commit;
end;
/

exec inicializa_test;

-- Completa lost test, incluyendo al menos los del enunciado y añadiendo los que consideres necesarios

create or replace procedure test_registrar_pedido is
begin
	 
  --caso 1 Pedido correct, se realiza
  begin
    inicializa_test;
  end;
  
  -- Idem para el resto de casos

  /* - Si se realiza un pedido vac´ıo (sin platos) devuelve el error -200002.
     - Si se realiza un pedido con un plato que no existe devuelve en error -20004.
     - Si se realiza un pedido que incluye un plato que no est´a ya disponible devuelve el error -20001.
     - Personal de servicio ya tiene 5 pedidos activos y se le asigna otro pedido devuelve el error -20003
     - ... los que os puedan ocurrir que puedan ser necesarios para comprobar el correcto funcionamiento del procedimiento
*/
  
end;
/


set serveroutput on;
exec test_registrar_pedido;
