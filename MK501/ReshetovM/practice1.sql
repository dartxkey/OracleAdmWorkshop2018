/* 1. создать последовательность для primary key departament начало с 100, без ограничений, без кэширования. */

insert into HR.DEPARTMENTS values (null, 'test department', null, 1700); /* cannot insert null into ("hr"."departments"."department_id") */

create sequence DEPARTMENTS_AI_SEQ start with 300 nocache; /* в задании указано значение 100, но такой департамент уже есть */

create or replace trigger DEPARTMENTS_AI_TR
  before insert on HR.DEPARTMENTS
  for each row
  begin
    select DEPARTMENTS_AI_SEQ.nextval
    into   :NEW.DEPARTMENT_ID
    from   DUAL;
  end;

insert into HR.DEPARTMENTS values (null, 'test department', null, 1700); /* success */

select DEPARTMENT_NAME from HR.DEPARTMENTS where DEPARTMENT_ID = 300; /* test department */

/* 2. выбрать из словаря данных параметры созданной последовательности. */

select * from ALL_SEQUENCES where SEQUENCE_NAME = 'DEPARTMENTS_AI_SEQ';

/* 3. создать неуникальный индекс на произвольном столбце employees, вывести инфо о нем из словаря данных. (имя, столбцы, тип, видимость) */

create index EMPLOYEES_PHONE_NUMBER_IDX on HR.EMPLOYEES(PHONE_NUMBER);
select * from USER_INDEXES where INDEX_NAME = 'EMPLOYEES_PHONE_NUMBER_IDX';
select * from USER_IND_COLUMNS where INDEX_NAME = 'EMPLOYEES_PHONE_NUMBER_IDX';

/* 4. Создать триггер, обеспечивающий генерацию нового номера отдела, используя sequence */

/* Сделал в задании 1. */

/* 5. Модифицировать последовательность, ограничив сверху, так, чтобы она закнчилась на следующей вставке */

declare
  new_max_value number;
  statement varchar2(1024);
begin
  select DEPARTMENTS_AI_SEQ.currval + 1 into new_max_value from DUAL;
  statement := 'alter sequence DEPARTMENTS_AI_SEQ maxvalue ' || new_max_value;
  execute immediate(statement);
end;

insert into HR.DEPARTMENTS values (null, 'test department', null, 1700); /* success */
insert into HR.DEPARTMENTS values (null, 'test department', null, 1700); /* sequence DEPARTMENTS_AI_SEQ.NEXTVAL exceeds MAXVALUE and cannot be instantiated */

/* 6. Модифицировать триггер на вставку так, чтобы исключение из п.5 вызывалось явно и было пользовательским. Код придумать любой. */

create or replace trigger DEPARTMENTS_AI_TR
  before insert on HR.DEPARTMENTS
  for each row
  declare
    departments_limit constant number := 310;
    new_department_id number;
      departments_overflow_exception exception;
  begin
    select DEPARTMENTS_AI_SEQ.nextval
    into new_department_id
    from DUAL;

    if new_department_id >= departments_limit
    then
      raise departments_overflow_exception;
    else
      :NEW.DEPARTMENT_ID := new_department_id;
    end if;
  exception
    when departments_overflow_exception then
      raise_application_error(-20100, 'the number of departments can not exceed ' || departments_limit);
  end;

/* 7. Генерировать всякий раз исключение, если делается попытка изменения зарплаты ген.директора. */

create or replace trigger PRESIDENT_SALARY_DEFENSE_TR
  before update on HR.EMPLOYEES
  for each row
  declare
    job_id constant varchar2(10) := 'AD_PRES';
      president_salary_def_ex exception;
  begin
    if :OLD.JOB_ID = job_id and (:OLD.SALARY != :NEW.SALARY) then
      raise president_salary_def_ex;
    end if;
  exception
    when president_salary_def_ex then
      raise_application_error(-20200, 'do not touch the president''s salary!');
  end;

/* 8. Создать триггер на регистрацию пользователя с записью времени и имени юзера в отлельную таблицу.
      Создать представление, показавающее пользователю только его входы. */

create or replace trigger access_log_tr
  after logon on database
  begin
    insert into SYS.ACCESS_LOG VALUES (user, sysdate);
  end;

create view access_log_view
  as (select * from SYS.ACCESS_LOG where USER_NAME = user);
grant select on SYS.ACCESS_LOG to public;