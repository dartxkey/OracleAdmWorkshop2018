-- 1. Создать последовательность для primary key DEPARTMENT: начало с 100, без ограничений, без кэширования.
-- 2. Выбрать из словаря данных параметры созданной последовательности.
-- 3. Создать неуникальный индекс на произвольном столбце EMPLOYEES, вывести инфо о нем из словаря данных. (имя столбцы, тип,видимость)
-- 4. Создать триггер, обеспечивающий генерацию нового номера отдела, использую sequence
-- 5. Модифицировать последовательность, ограничив сверху, так, чтобы она закнчилась на следующей вставке
-- 6. Модифицировать триггер на вставку так, чтобы исключение из п.5 вызывалось явно и было пользовательским. Код придумать любой.
-- 7. Генерировать всякий раз исключение, если делается попытка изменения зарплаты ген.директора.
-- 8. Создать триггер на регистрацию пользователя с записью времени и имени юзера в отлельную таблицу. —оздать представление, показавающее пользователю только его входы.

-- 1.
create sequence pk_department_sequence
nominvalue          -- _ без
nomaxvalue          --   ограничений
start with 100      -- - начало со 100
increment by 1      -- - шаг
nocache;             -- - без кэширования

-- 2.
select * from ALL_SEQUENCES where SEQUENCE_NAME = 'PK_DEPARTMENT_SEQUENCE';

-- 3.
create index index_employees_salary on hr.employees(salary);
select * from all_indexes where index_name = 'INDEX_EMPLOYEES_SALARY';

-- 4.
create trigger gen_department_number
before insert on hr.departments
for each row
  begin
    :new.department_id := pk_department_sequence.nextval;
  end;

-- 5.
declare
  st varchar(1024);
  maxval number;
begin
  select last_number into maxval from sys.all_sequences where sequence_name = 'PK_DEPARTMENT_SEQUENCE';
  st := 'alter sequence pk_department_sequence maxvalue ' || to_char(maxval + 1000);
  execute immediate st;
end;

-- 6.
create or replace trigger gen_department_number
before insert on hr.departments
for each row
  declare
      excpt exception;
  begin
    :new.department_id := pk_department_sequence.nextval;
    exception
    when OTHERS then raise_application_error(-20003, 'Sequence is over.');
  end;

-- 7.
create or replace trigger disallow_change_gen_dir_salary
before update on hr.employees
for each row
  begin
    if :old.JOB_ID = 'AD_PRES' AND :new.salary <> :old.SALARY
    THEN raise_application_error(-20004, 'Not allow change salary of president');
    end if;
  end;

-- 8.
create table logon_journal (
  logon_date date,
  logon_user varchar(50)
);

create trigger logon_journal_trigger
after logon on database
  begin
    insert into logon_journal (logon_date, logon_user) values (sysdate, user);
  end;

create view logon_journal_view as select * from logon_journal where logon_user = user;