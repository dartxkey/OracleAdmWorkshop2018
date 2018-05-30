-- 1. Создать последовательность для primary key DEPARTMENT:
-- начало с 100, без ограничений, без кэширования.
create sequence MY_DEPARTMENT_SEQUENCE
  start with 100
  nominvalue
  nomaxvalue
  nocache;

-- 2. Выбрать из словаря данных параметры созданной последовательности.
select *
from ALL_SEQUENCES
where SEQUENCE_NAME = 'MY_DEPARTMENT_SEQUENCE';

-- 3. Создать неуникальный индекс на произвольном столбце EMPLOYEES, вывести инфо о нем из словаря данных. (имя столбцы, тип,видимость)
create index MY_EMPLOYEE_PHONE_INDEX
  on HR.EMPLOYEES (PHONE_NUMBER);

select *
from ALL_INDEXES
where INDEX_NAME = 'MY_DEPARTMENT_SEQUENCE';

-- 4. Создать триггер, обеспечивающий генерацию нового номера отдела, использую sequence
create or replace trigger MY_DEPARTMENT_INSERT_TRIGGER
  before insert
  on HR.DEPARTMENTS
  for each row
  begin
    :NEW.DEPARTMENT_ID := HR.MY_DEPARTMENT_SEQUENCE.nextval;
  end;

-- 5. Модифицировать последовательность, ограничив сверху, так, чтобы она закнчилась на следующей вставке
alter sequence HR.MY_DEPARTMENT_SEQUENCE maxvalue 100;

-- 6. Модифицировать триггер на вставку так, чтобы исключение из п.5 вызывалось явно и было пользовательским. Код придумать любой.
-- ORA-08004: sequence string.NEXTVAL string stringVALUE and cannot be instantiated
-- Cause: instantiating NEXTVAL would violate one of MAX/MINVALUE
-- Action: alter the sequence so that a new value can be requested
create or replace trigger MY_DEPARTMENT_INSERT_TRIGGER
  before insert
  ON HR.DEPARTMENTS
  for each row
  declare
      EOS_EXCEPTION exception;
    pragma exception_init (EOS_EXCEPTION, -8004);
  begin
    :NEW.DEPARTMENT_ID := HR.MY_DEPARTMENT_SEQUENCE.nextval;
    exception
    when EOS_EXCEPTION
    then
      raise_application_error(-20222, 'You can not insert a record because the sequence has ended!');
  end;

-- 7. Генерировать всякий раз исключение, если делается попытка изменения зарплаты ген.директора.
create or replace trigger ANTI_CORRUPTION_TRIGGER
  before update
  on HR.EMPLOYEES
  for each row
  declare
      CORRUPTION_EXCEPTION exception;
  begin
    if :NEW.JOB_ID = 'AD_PRES' and :NEW.SALARY > :OLD.SALARY
    then
      raise CORRUPTION_EXCEPTION;
    end if;
    exception
    when CORRUPTION_EXCEPTION
    then
      raise_application_error(-20111, 'Corruption was discovered!');
  end;

-- 8. Создать триггер на регистрацию пользователя с записью времени и имени юзера в отлельную таблицу. cоздать представление, показавающее пользователю только его входы.
-- Для начала создадим таблицу, где будем фиксировать все посещения пользователей БД.
drop table SYS.USERS_LOGON_TABLE;
create table SYS.USERS_LOGON_TABLE (
  login_time DATE,
  username   varchar(128)
);

-- Создадим триггер, который будет срабатывать каждый раз при входе любого пользователя в БД
-- и логировать в созданную ранее таблицу.
create or replace trigger SYS.USERS_LOGON_TRIGGER
  after logon on database
  begin
    insert into SYS.USERS_LOGON_TABLE (login_time, username) values (SYSDATE, USER);
  end;

-- Создадим представление, которое будет отражать пользователю только его статистику по входам.
create or replace view SYS.USERS_LOGON_VIEW
  as
    select
      username,
      login_time
    from SYS.USERS_LOGON_TABLE
    where USERNAME = USER;

-- Права на доступ к представлению всем пользователям БД.
grant select on SYS.USERS_LOGON_VIEW to public;
