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
 disp_servicio integer;
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
    
    
    --Añadimos el pedido a la tabla pedidos
    BEGIN
    Select MAX(id_pedido) into arg_id_pedido
        FROM pedidos;
    END;
    
    -- Esto se puede cambiar por un "NVL(MAX(id_pedido), 0) + 1" en el propio select, pero como no lo hemos dado asi se queda
    if arg_id_pedido is NULL then
        arg_id_pedido := 1;
    else
        arg_id_pedido := arg_id_pedido + 1;
    end if;
    
    insert into pedidos values(arg_id_pedido, arg_id_cliente, arg_id_personal, SYSDATE, arg_total);
    
    --Añadimos los detalles de pedido a la tabla detalle_pedido
    if arg_id_primer_plato is not null then
    insert into detalle_pedido values(arg_id_pedido,arg_id_primer_plato, 1);
    end if;
    
    if arg_id_segundo_plato is not null then
    insert into detalle_pedido values(arg_id_pedido, arg_id_segundo_plato, 1); -- Cantidad fija en 1, ajustar si es necesario
    end if;

    --Actualizamos la tabla personal_servicio
    BEGIN
        SELECT pedidos_activos into disp_servicio
        FROM personal_servicio
        WHERE id_personal = arg_id_personal;
    END;

    if disp_servicio >= 5 then
        raise MUCHO_OCUPADO;
    else
        update personal_servicio
        set pedidos_activos = pedidos_activos+1
        where id_personal = arg_id_personal;
    end if;
    
    COMMIT;
    

  -- Codigo AQUI
  -- NOTE: esto va al final del todo, despues de todo el codigo, faltaría adaptarlo a las necesidades del codigo
  -- Captura de las excepciones lanzadas.
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
/*
BEGIN
        SELECT pedidos_activos into disp_servicio
        FROM personal_servicio
        WHERE id_personal = arg_id_personal;
    END;

    if disp_servicio >= 5 then
        raise MUCHO_OCUPADO;
    else
        update personal_servicio
        set pedidos_activos = pedidos_activos+1
        where id_personal = arg_id_personal;
    end if;
*/
-- * P4.2
-- Para evitar que dos transacciones concurrentes asignen un pedido al mismo miembro del personal de servicio y superen el límite de pedidos activos, se deben aplicar mecanismos de control de concurrencia.
-- 1. Uso de SELECT ... FOR UPDATE (Bloqueo de fila)
/* DECLARE pedidos_actuales INTEGER;
   BEGIN
    -- Bloqueamos la fila del personal seleccionado
    SELECT pedidos_activos INTO pedidos_actuales 
    FROM personal_servicio 
    WHERE id_personal = arg_id_personal
    FOR UPDATE;  -- Bloquea la fila hasta que se haga COMMIT o ROLLBACK

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
/* No se puede asegurar al 100% que el pedido se realizará correctamente en el paso 4 solo con las comprobaciones de los pasos 1 y 2, 
   porque en entornos concurrentes siempre existe el riesgo de que otro proceso modifique los datos entre una verificación y la ejecución del pedido. 
   Esto se debe a un problema conocido como condición de carrera.
   1. Si dos transacciones leen los pedidos activos al mismo tiempo antes de que alguna haga la actualización, ambas podrían concluir que el empleado tiene disponibilidad.
   Luego, ambas intentarían asignarle pedidos simultáneamente, superando el límite permitido.
   2. Supongamos que en el paso 2 verificamos que el empleado tiene 4 pedidos activos y, por lo tanto, podemos asignarle uno más. 
   Pero, antes de que nuestra transacción haga la actualización, otra transacción que también verificó lo mismo logra completar su commit primero, asignando un pedido al mismo empleado.

   Cuando nuestra transacción intenta hacer su commit, el empleado ya tiene 5 pedidos activos (o más), lo que lleva a una inconsistencia.
*/
-- * P4.4
/* Si añadimos la restricción CHECK (pedidos_activos ≤ 5) en la tabla personal_servicio, esto garantizaría a nivel de base de datos que un miembro del personal no pueda tener más de 5 pedidos activos.
   Sin embargo, esta restricción no evita completamente los problemas de concurrencia y podría generar errores inesperados en nuestro código.
   1. La restricción CHECK actúa como última barrera

   Si dos transacciones intentan asignar pedidos al mismo empleado de manera simultánea y superan el límite, una de ellas fallará cuando intente hacer el UPDATE en la tabla personal_servicio.

   Se generará un error de integridad en la base de datos cuando una de las transacciones intente guardar un sexto pedido.
   
   2. No evita condiciones de carrera

   La restricción CHECK solo se valida al momento del UPDATE, pero no evita que dos transacciones concurrentes lean el mismo número de pedidos activos antes de la actualización,
   lo que aún puede provocar inconsistencias.

   Es necesario un mecanismo adicional para manejar esta situación correctamente.
   
   3.Cambio en la gestión de excepciones

   Actualmente, la excepción MUCHO_OCUPADO (-20003) se lanza en nuestro código antes de actualizar la base de datos.

   Con la nueva restricción CHECK, debemos capturar el error de la base de datos cuando ocurra un UPDATE inválido e interpretar el error de integridad como una nueva versión de MUCHO_OCUPADO.
   
   
   Modificaciones necesarias en el código
   1. Capturar el error de violación de CHECK

   En el bloque EXCEPTION, deberíamos interceptar la excepción generada por la base de datos cuando la restricción CHECK falle y lanzar nuestra propia excepción personalizada.

   2. Bloqueo preventivo para evitar concurrencia

   Antes de asignar el pedido, debemos bloquear la fila del personal de servicio (SELECT ... FOR UPDATE) para evitar que otras transacciones lean y modifiquen la misma información al mismo tiempo.
   
   BLOQUEO DE LA FILA DEL EMPLEADO
   SELECT pedidos_activos 
   INTO pedidos_actuales 
   FROM personal_servicio 
   WHERE id_personal = arg_id_personal
   FOR UPDATE;
   
   MANEJO DE LA EXCEPCIÓN POR LA VILOACIÓN DEL CHECK
   EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -2290 THEN -- Código de error de restricción CHECK
            RAISE_APPLICATION_ERROR(-20003, 'El personal de servicio tiene demasiados pedidos');
        ELSE
            RAISE;
        END IF;
*/
-- * P4.5
/* 1. Programación Defensiva
   Esta estrategia se basa en anticipar posibles errores y validar condiciones antes de ejecutar operaciones críticas. Se puede ver en el código en los siguientes aspectos:
   Validaciones antes de insertar datos:

   Se comprueba que al menos un plato sea seleccionado antes de procesar el pedido.

   Se verifica si los platos existen y si están disponibles antes de agregarlos al pedido.

   Se valida si el personal de servicio ya tiene 5 pedidos activos antes de asignarle uno nuevo.
   Gestión de excepciones personalizadas:

   Se han definido excepciones específicas como PLATOS_NO_DISPONIBLES, PEDIDO_SIN_PLATO y MUCHO_OCUPADO para manejar errores esperados de manera estructurada.

   Se usan códigos de error personalizados (-20001, -20002, -20003) para identificar el tipo exacto de problema.
   
   ¿Cómo se ve reflejada en el código?
   1. Validaciones antes de operaciones críticas (if para comprobar platos, existencia, disponibilidad).

   2. Uso de excepciones personalizadas (RAISE_APPLICATION_ERROR).

   3. Respaldo en restricciones de base de datos (CHECK (pedidos_activos ≤ 5)).

   4. Manejo de excepciones SQL (WHEN OTHERS THEN ... IF SQLCODE = -2290 THEN ...).
*/ 



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
    registrar_pedido(1,1,1,2);
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


-- ... los que os puedan ocurrir que puedan ser necesarios para comprobar el correcto funcionamiento del procedimiento

end;
/


set serveroutput on;
exec test_registrar_pedido;