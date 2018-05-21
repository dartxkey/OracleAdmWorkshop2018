-- 1. Создать последовательность для primary key DEPARTMENT:
-- начало с 100, без ограничений, без кэширования.

--  Последовательность CREATE SEQUENCE – это объект базы данных,
-- который генерирует целые числа в соответствии с правилами,
-- установленными во время его создания.

CREATE SEQUENCE DEPARTMENT
  START WITH 100
  NOMAXVALUE
  NOCACHE;

--
--
--
--
--

-- 2. Выбрать из словаря данных параметры созданной последовательности.

-- Словарь данных Oracle - множество таблиц и объектов базы данных, которое хранится
-- в специальной области базы данных и ведется исключительно ядром Oracle

SELECT *
FROM SYS.ALL_SEQUENCES
WHERE SEQUENCE_NAME = 'DEPARTMENT';

-- SEQUENCE_OWNER	SEQUENCE_NAME	MIN_VALUE	MAX_VALUE	INCREMENT_BY	CYCLE_FLAG	ORDER_FLAG	CACHE_SIZE	LAST_NUMBER
-- SYS	DEPARTMENT	1	9999999999999999999999999999	1	N	N	0	100


--
--
--
--
--

-- 3. Создать неуникальный индекс на произвольном столбце EMPLOYEES, вывести инфо о нем из словаря данных. (имя столбцы, тип, видимость)
-- Создаём индекс:
CREATE INDEX EMP
  ON HR.EMPLOYEES (FIRST_NAME);

-- Выводим информацию из словаря данных:
SELECT
  INDEX_NAME,
  INDEX_TYPE,
  VISIBILITY
FROM SYS.DBA_INDEXES
WHERE INDEX_NAME = 'EMP';

-- INDEX_NAME	INDEX_TYPE	VISIBILITY
-- EMP	NORMAL	VISIBLE

--
--
--
--
--

-- 4. Создать триггер, обеспечивающий генерацию нового номера отдела, используя sequence
CREATE OR REPLACE TRIGGER NEW_DEPARTMENT_ID_TRIGGER
  BEFORE INSERT
  ON HR.DEPARTMENTS
  FOR EACH ROW
  WHEN (new.DEPARTMENT_ID IS NULL)
  BEGIN
    SELECT DEPARTMENT.NEXTVAL
    INTO :new.DEPARTMENT_ID
    FROM dual;
  END;

-- Проверка создания триггера:
SELECT *
FROM SYS.ALL_TRIGGERS
WHERE TRIGGER_NAME = 'NEW_DEPARTMENT_ID_TRIGGER';

-- Проверка работоспособности триггера (Создаём новые отделы):
INSERT INTO HR.DEPARTMENTS (DEPARTMENT_NAME) VALUES ('NEW TEST DEPARTMENT 1');
INSERT INTO HR.DEPARTMENTS (DEPARTMENT_NAME) VALUES ('NEW TEST DEPARTMENT 2');
INSERT INTO HR.DEPARTMENTS (DEPARTMENT_NAME) VALUES ('NEW TEST DEPARTMENT 3');
INSERT INTO HR.DEPARTMENTS (DEPARTMENT_NAME) VALUES ('NEW TEST DEPARTMENT 4');

-- Смотрим новые строки:
SELECT DEPARTMENT_ID
FROM HR.DEPARTMENTS
WHERE DEPARTMENT_NAME LIKE 'NEW TEST DEPARTMENT%';

-- DEPARTMENT_ID
-- 119
-- 121
-- 122
-- 123
-- 126

--
--
--
--
--

-- 5. Модифицировать последовательность, ограничив сверху, так, чтобы она закончилась на следующей вставке
-- Получаем последнее значение последовательности (126):
SELECT LAST_NUMBER
FROM USER_SEQUENCES
WHERE SEQUENCE_NAME = 'DEPARTMENT';

-- Выставляем это значение в качестве максимального:
ALTER SEQUENCE DEPARTMENT MAXVALUE 126;

-- Смотрим новое максимальное значение
SELECT MAX_VALUE
FROM SYS.ALL_SEQUENCES
WHERE SEQUENCE_NAME = 'DEPARTMENT';

-- Первый запрос успешно выполнится:
INSERT INTO HR.DEPARTMENTS (DEPARTMENT_NAME) VALUES ('NEW TEST DEPARTMENT 5');

-- Последовательность закончилась и при следующем запросе возникнет исключение:
INSERT INTO HR.DEPARTMENTS (DEPARTMENT_NAME) VALUES ('NEW TEST DEPARTMENT 6');
-- [72000][8004] ORA-08004: sequence DEPARTMENT.NEXTVAL exceeds MAXVALUE and cannot be instantiated

--
--
--
--
--

-- 6. Модифицировать триггер на вставку так, чтобы исключение из п.5 вызывалось явно и было пользовательским. Код придумать любой.
CREATE OR REPLACE TRIGGER DEPARTMENT_SEQUENCE_TRIGGER
  BEFORE INSERT
  ON HR.DEPARTMENTS
  FOR EACH ROW
  DECLARE
      DEPARTMENT_SEQUENCE_IS_OVER EXCEPTION;
  BEGIN
    IF new.DEPARTMENT_ID := DEPARTMENT.nextval
    THEN RAISE DEPARTMENT_SEQUENCE_IS_OVER;
    END IF;
    EXCEPTION WHEN DEPARTMENT_SEQUENCE_IS_OVER THEN
    raise_application_error(-20001, 'Sequence DEPARTMENT is over.');
  END;

-- Проверка создания триггера:
SELECT *
FROM SYS.ALL_TRIGGERS
WHERE TRIGGER_NAME = 'DEPARTMENT_SEQUENCE_TRIGGER';

-- OWNER	TRIGGER_NAME	TRIGGER_TYPE	TRIGGERING_EVENT	TABLE_OWNER	BASE_OBJECT_TYPE	TABLE_NAME	COLUMN_NAME	REFERENCING_NAMES	WHEN_CLAUSE	STATUS	DESCRIPTION	ACTION_TYPE	TRIGGER_BODY	CROSSEDITION	BEFORE_STATEMENT	BEFORE_ROW	AFTER_ROW	AFTER_STATEMENT	INSTEAD_OF_ROW	FIRE_ONCE	APPLY_SERVER_ONLY
-- SYS	DEPARTMENT_SEQUENCE_TRIGGER	BEFORE EACH ROW	INSERT	HR	TABLE	DEPARTMENTS		REFERENCING NEW AS NEW OLD AS OLD		ENABLED	"DEPARTMENT_SEQUENCE_TRIGGER
--   BEFORE INSERT
--   ON HR.DEPARTMENTS
--   FOR EACH ROW
--   "	PL/SQL     	"DECLARE
--       DEPARTMENT_SEQUENCE_IS_OVER EXCEPTION;
--   BEGIN
--     IF new.DEPARTMENT_ID := DEPARTMENT.nextval
--     THEN RAISE DEPARTMENT_SEQUENCE_IS_OVER;
--     END IF;
--     EXCEPTION WHEN DEPARTMENT_SEQUENCE_IS_OVER THEN
--     raise_application_error(-20203, 'Sequence DEPARTMENT is over.');
--   END;"	NO	NO	NO	NO	NO	NO	YES	NO

-- Пытаемся снова добавить отдел:
INSERT INTO HR.DEPARTMENTS (DEPARTMENT_NAME) VALUES ('NEW TEST DEPARTMENT 7');

-- [72000][20002] ORA-20002: Sequence DEPARTMENT is over.
-- ORA-06512: at "SYS.DEPARTMENT_SEQUENCE_TRIGGER", line 8
-- ORA-04088: error during execution of trigger 'SYS.DEPARTMENT_SEQUENCE_TRIGGER'

--
--
--
--
--

-- 7. Генерировать всякий раз исключение, если делается попытка изменения зарплаты ген.директора.
CREATE OR REPLACE TRIGGER SALARY_TRIGGER
  BEFORE UPDATE
  ON HR.EMPLOYEES
  FOR EACH ROW
  DECLARE
      DIRECTOR_SALARY_ALTERING EXCEPTION;
  BEGIN
    IF :NEW.SALARY <> :OLD.SALARY AND :OLD.JOB_ID = 'AD_PRES'
    THEN RAISE DIRECTOR_SALARY_ALTERING;
    END IF;
    EXCEPTION WHEN DIRECTOR_SALARY_ALTERING THEN
    raise_application_error(-20002, 'Changing director`s salary was forbidden');
  END;

-- Проверка создания триггера:
SELECT *
FROM SYS.ALL_TRIGGERS
WHERE TRIGGER_NAME = 'SALARY_TRIGGER';

-- OWNER	TRIGGER_NAME	TRIGGER_TYPE	TRIGGERING_EVENT	TABLE_OWNER	BASE_OBJECT_TYPE	TABLE_NAME	COLUMN_NAME	REFERENCING_NAMES	WHEN_CLAUSE	STATUS	DESCRIPTION	ACTION_TYPE	TRIGGER_BODY	CROSSEDITION	BEFORE_STATEMENT	BEFORE_ROW	AFTER_ROW	AFTER_STATEMENT	INSTEAD_OF_ROW	FIRE_ONCE	APPLY_SERVER_ONLY
-- SYS	SALARY_TRIGGER	BEFORE EACH ROW	UPDATE	HR	TABLE	EMPLOYEES		REFERENCING NEW AS NEW OLD AS OLD		ENABLED	"SALARY_TRIGGER
--   BEFORE UPDATE
--   ON HR.EMPLOYEES
--   FOR EACH ROW
--   "	PL/SQL     	"DECLARE
--       DIRECTOR_SALARY_ALTERING EXCEPTION;
--   BEGIN
--     IF :NEW.SALARY <> :OLD.SALARY AND :OLD.JOB_ID = 'AD_PRES'
--     THEN RAISE DIRECTOR_SALARY_ALTERING;
--     END IF;
--     EXCEPTION WHEN DIRECTOR_SALARY_ALTERING THEN
--     raise_application_error(-20002, 'Changing director`s salary was forbidden');
--   END;"	NO	NO	NO	NO	NO	NO	YES	NO

-- Проверка работоспособности триггера (Изменяем зарплату на новое значение):
UPDATE HR.EMPLOYEES
SET SALARY = 150
WHERE EMPLOYEE_ID = 100;
-- Возникнет исключение:
-- [72000][20002] ORA-20002: Changing director`s salary was forbidden
-- ORA-06512: at "SYS.SALARY_TRIGGER", line 8
-- ORA-04088: error during execution of trigger 'SYS.SALARY_TRIGGER'

-- Проверяем, что не изменилась зарплата на новое значение:
SELECT SALARY
FROM HR.EMPLOYEES
WHERE EMPLOYEE_ID = 100;

-- SALARY
-- 90.00

-- При необходимости можем удалить триггер и при повторном изменении зарплаты она успешно изменится:
DROP TRIGGER SALARY_TRIGGER;

--
--
--
--
--

-- 8. Создать триггер на регистрацию пользователя с записью времени и имени юзера в отдельную таблицу.
CREATE TABLE LOGONS (
  TIME    DATE,
  USER_ID VARCHAR2(100)
);

CREATE OR REPLACE TRIGGER LOGON_TRIGGER
  AFTER LOGON ON DATABASE
  BEGIN
    INSERT INTO LOGONS (TIME, USER_ID) VALUES (SYSDATE, USER);
  END;

-- Создать представление, показавающее пользователю только его входы.

-- Представление – это виртуальная таблица. В действительности представление – всего лишь результат выполнения
-- оператора SELECT, который хранится в структуре памяти, напоминающей SQL таблицу
CREATE OR REPLACE VIEW LOGONS_VIEW AS
  SELECT TIME
  FROM LOGONS
  WHERE USER_ID = USER;

-- Выводим данные:

SELECT *
FROM LOGONS_VIEW;

-- 2018-04-16 17:34:16	SYS
-- 2018-04-16 17:34:48	SYS
-- 2018-04-16 17:35:00	SYS
-- 2018-04-16 17:35:07	SYS
-- 2018-04-16 17:37:05	SYS
-- 2018-04-16 17:37:11	SYS