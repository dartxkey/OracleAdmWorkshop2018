-- Practice 3. Аудит, VPD

-- 1. Включить стандартный, детализированный аудит Oracle, запись в базу.

-- Чтобы провести аудит активности любого пользователя внутри базы данных, и даже
-- попыток входа в БД, необходимо активизировать аудит, указав параметр AUDIT_TRAIL
-- в файле init.ora.
-- Параметр может принимать следующие значения:
-- 1. NONE
-- 2. OS
-- 3. DB
-- 4. DB, EXTENDED
-- 5. XML
-- 6. XML, EXTENDED

SHOW PARAMETERS AUDIT_TRAIL;
-- NAME                   TYPE              VALUE
-- ---------------------- ----------------- ---------------------
-- audit_trail            string            DB, EXTENDED.

--
--
--
--
--

-- 2. Для пользователя "владелец приложения" из Lab2 аудировать:
-- а) все действия по созданию/изменению триггеров и представлений БД. Каждое изменение - отдельной записью.

AUDIT CREATE ANY TRIGGER BY APP_OWNER BY ACCESS;
-- Audit succeeded.
AUDIT ALTER ANY TRIGGER BY APP_OWNER BY ACCESS;
-- Audit succeeded.
AUDIT CREATE ANY VIEW BY APP_OWNER BY ACCESS;
-- Audit succeeded.

-- б) фиксировать только неудачные попытки удаления из таблиц вашим пользователем. Одна запись на сессию.
AUDIT DELETE ANY TABLE BY APP_OWNER BY SESSION WHENEVER NOT SUCCESSFUL;
-- Audit succeeded.

-- в) продеменострировать содержимое журнала аудита для стандартного аудита.
SELECT
  TO_CHAR(TIMESTAMP, 'DD.MM.YYYY HH24:MI:SS') TIME_STAMP,
  USERNAME,
  ACTION_NAME
FROM DBA_AUDIT_TRAIL
ORDER BY TIMESTAMP;
--
-- TIME_STAMP						          USERNAME										   ACTION_NAME
-- --------------------------------------------------------- -------------------------------------
-- 07.05.2018 17:56:03					  SYSTEM										     LOGON
-- 07.05.2018 17:56:03					  SYSTEM										     CREATE PUBLIC SYNONYM
-- 07.05.2018 17:56:03					  SYSTEM										     LOGOFF
--
--   ...
--
-- 28.05.2018 15:28:10					  IKSENT										     LOGON
-- 28.05.2018 15:35:01					  IKSENT										     SYSTEM AUDIT
--
-- 48 rows selected.

--
--
--
--
--

-- 3. VPD:
-- а) на таблицу протоколирования входов пользователя в БД (лаб 1.) переписывать запрос так, чтобы показывались только записи по тек. пользователю
CREATE USER test_1 IDENTIFIED BY oracle
  DEFAULT TABLESPACE USERS
  TEMPORARY TABLESPACE TEMP
  QUOTA UNLIMITED ON USERS;

CREATE USER test_2 IDENTIFIED BY oracle
  DEFAULT TABLESPACE USERS
  TEMPORARY TABLESPACE TEMP
  QUOTA UNLIMITED ON USERS;

GRANT
CREATE SESSION,
ALTER SESSION,
CREATE ANY TABLE,
SELECT ANY TABLE,
INSERT ANY TABLE,
UPDATE ANY TABLE,
DELETE ANY TABLE
TO test_1, test_2;

CONNECT APP_OWNER/APP_OWNER;

CREATE TABLE LOGONS (
  TIME    DATE,
  USER_ID VARCHAR2(100)
);

CREATE OR REPLACE TRIGGER LOGON_TRIGGER
  AFTER LOGON ON DATABASE
  BEGIN
    INSERT INTO APP_OWNER.LOGONS (TIME, USER_ID) VALUES (SYSDATE, USER);
  END;
/

CONNECT test_1/oracle;
SET SQLPROMPT "test_1>"

CONNECT test_2/oracle;
SET SQLPROMPT "test_2>"
-- Выполняем эти входы несколько раз

SELECT *
FROM APP_OWNER.LOGONS;
--
-- TIME
-- --------
-- USER_ID
-- --------
-- 28.05.18
-- TEST_2
--
-- 28.05.18
-- SYS
--
-- 28.05.18
-- TEST_1
--
-- 28.05.18
-- TEST_1
--
-- 28.05.18
-- TEST_2
--
-- 28.05.18
-- SYS

CREATE OR REPLACE FUNCTION LOGONS_PREDICATE(schema_p IN VARCHAR2, table_p IN VARCHAR2)

  RETURN VARCHAR2 AS condition VARCHAR2(200);

  BEGIN
    condition := 'USER_ID = SYS_CONTEXT(''USERENV'', ''SESSION_USER'')';
    RETURN (condition);

  END;
/
-- Function created.

BEGIN
  DBMS_RLS.ADD_POLICY(
      object_schema     => 'APP_OWNER',
      object_name       => 'LOGONS',
      policy_name       => 'LOGONS_POLICY',
      policy_function   => 'LOGONS_PREDICATE',
      sec_relevant_cols => 'USER_ID',
      statement_types   => 'SELECT',
      ENABLE            => TRUE
  );
END;
/
-- PL/SQL procedure successfully completed.

-- test_1>
SELECT *
FROM APP_OWNER.LOGONS;
--
-- TIME
-- --------
-- USER_ID
-- --------------------------------------------------------------------------------
-- 28.05.18
-- TEST_1
--
-- 28.05.18
-- TEST_1


-- test_2>
SELECT *
FROM APP_OWNER.LOGONS;
-- TIME
-- --------
-- USER_ID
-- --------------------------------------------------------------------------------
-- 28.05.18
-- TEST_2
--
-- 28.05.18
-- TEST_2

-- При необходимости можем удалить политику:
BEGIN
  DBMS_RLS.DROP_POLICY('APP_OWNER', 'LOGONS', 'LOGONS_POLICY');
END;


--
--
--
--
--

-- 4. FGA на HR.SALARIES (FGA, fine-grained auditing) - Детальный аудит.
-- а) изменение зарплаты более чем на 5%
BEGIN
  DBMS_FGA.ADD_POLICY(
      object_schema   => 'HR',
      object_name     => 'EMPLOYEES',
      policy_name     => 'EMPLOYEES_POLICY_1',
      audit_condition => ':new.salary > :old.salary * 1.05',
      audit_column    => 'SALARY',
      statement_types => 'UPDATE'
  );
END;
/

-- б) запрос фамилии,зарплаты по сотрудникам deptno (На выбор любой).
BEGIN
  DBMS_FGA.ADD_POLICY(
      object_schema   => 'HR',
      object_name     => 'EMPLOYEES',
      policy_name     => 'EMPLOYEES_POLICY_2',
      audit_condition => 'DEPARTMENT_ID = 100',
      audit_column    => 'LAST_NAME,SALARY',
      statement_types => 'SELECT'
  );
END;
/

-- в) продеменострировать содержимое журнала аудита детального аудита.
SELECT *
FROM DBA_FGA_AUDIT_TRAIL;

-- 5. Отчет по всем операциям в журналах аудита по выбранному пользователю за период.
-- (sql запрос с параметром: дней истории от тек.даты)

-- Включаем вывод DBMS_OUTPUT:
SET SERVEROUTPUT ON;

CREATE OR REPLACE PROCEDURE GET_AUDIT_FOR_USER(USER IN VARCHAR2, DAYS_COUNT IN NUMBER) AS
  BEGIN
    FOR row IN (
    SELECT *
    FROM DBA_COMMON_AUDIT_TRAIL
    WHERE DB_USER = GET_AUDIT_FOR_USER.USER AND EXTENDED_TIMESTAMP > (
      SELECT (SYSDATE - GET_AUDIT_FOR_USER.DAYS_COUNT)
      FROM dual
    ))
    LOOP
      DBMS_OUTPUT.PUT_LINE('' || row.DB_USER || ' - ' || ROW.STATEMENT_TYPE || ' - ' || ROW.EXTENDED_TIMESTAMP);
    END LOOP;
  END GET_AUDIT_FOR_USER;
/

-- Procedure created.

EXECUTE GET_AUDIT_FOR_USER('SYS', 5);
-- SYS - LOGON - 28.05.18 17:28:16,854361 +03:00
-- SYS - LOGON - 28.05.18 17:28:14,260626 +03:00
-- SYS - LOGON - 28.05.18 17:28:11,604461 +03:00

EXECUTE GET_AUDIT_FOR_USER('TEST_1', 10);
-- TEST_1 - CREATE TABLE - 28.05.18 16:03:28,640820 +03:00
-- TEST_1 - LOGON - 28.05.18 19:09:07,878495 +03:00
-- TEST_1 - LOGON - 28.05.18 17:33:37,740360 +03:00
-- TEST_1 - LOGON - 28.05.18 16:06:58,990061 +03:00
-- TEST_1 - LOGOFF - 28.05.18 17:33:44,107691 +03:00
-- TEST_1 - LOGOFF - 28.05.18 16:06:28,832043 +03:00
-- TEST_1 - LOGOFF - 28.05.18 16:06:19,657691 +03:00
-- TEST_1 - LOGOFF - 28.05.18 16:04:51,582748 +03:00
-- TEST_1 - LOGON - 28.05.18 16:02:36,486187 +03:00
-- TEST_1 - LOGON - 28.05.18 16:02:33,916458 +03:00
-- TEST_1 - LOGON - 28.05.18 16:02:31,658817 +03:00
-- TEST_1 - SYSTEM GRANT - 28.05.18 16:03:13,057084 +03:00
-- TEST_1 - SYSTEM GRANT - 28.05.18 16:03:13,058737 +03:00
-- TEST_1 - SYSTEM GRANT - 28.05.18 16:03:13,057357 +03:00
-- TEST_1 - SYSTEM GRANT - 28.05.18 16:03:13,059004 +03:00
-- TEST_1 - SYSTEM GRANT - 28.05.18 16:03:13,057595 +03:00
-- ...