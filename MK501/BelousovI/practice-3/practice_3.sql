GRANT CONNECT, CREATE TABLE, CREATE PROCEDURE TO iksent;
GRANT UNLIMITED TABLESPACE TO iksent;
GRANT SELECT ON v_$session TO iksent;
GRANT SELECT ON v_$parameter TO iksent;
GRANT SELECT ON gv_$session TO iksent;
GRANT SELECT ON V_$UNDOSTAT TO iksent;
CONNECT iksent/iksent;
-- Connected.

SET SQLPROMPT "SESSION_1>"
SET SQLPROMPT "SESSION_2>"

--
--
--
--
--

-- Разрешение конфликтов блокировок с помощью SQL через V$SESSION
-- Разрешить блокировку 2 способами:
--
-- 1. зафиксировать/откатить удерживающую транзакцию

CREATE TABLE blocks_testing (
  name VARCHAR2(15) NOT NULL,
  numb NUMBER(3)    NOT NULL
)
TABLESPACE ilya
STORAGE (
INITIAL 50K
);
-- Table created.

SELECT *
FROM blocks_testing;
-- no rows selected

INSERT INTO blocks_testing VALUES ('first', 1);
INSERT INTO blocks_testing VALUES ('second', 2);
INSERT INTO blocks_testing VALUES ('third', 3);

SELECT *
FROM blocks_testing;
-- NAME						    NUMB
-- --------------------------------------------- ----------
-- first						       1
-- second						       2
-- third						       3

-- SESSION_1>
UPDATE blocks_testing
SET numb = 111
WHERE name = 'first';
-- 1 row updated.

SELECT *
FROM blocks_testing
WHERE name = 'first';

-- SESSION_2>
UPDATE blocks_testing
SET numb = 222
WHERE name = 'first';
-- Не происходит никакого вывода
-- Командная строка не появляется

-- SESSION_1>
COMMIT;
-- Commit complete.

-- SESSION_1>
SELECT *
FROM blocks_testing
WHERE name = 'first';
-- NAME						    NUMB
-- --------------------------------------------- ----------
-- first						     111

-- SESSION_2>
-- Появился вывод:
-- 1 row updated.

-- SESSION_2>
SELECT *
FROM blocks_testing
WHERE name = 'first';
-- NAME						    NUMB
------------------------------------------- ----------
-- first						     222

-- SESSION_2>
ROLLBACK;
-- Rollback complete.

-- SESSION_2>
SELECT *
FROM blocks_testing
WHERE name = 'first';
-- NAME						    NUMB
------------------------------------------- ----------
-- first						     111

--
--
--
--
--

-- 2. убить сессию (синтаксис смотрим самостоятельно)

-- SESSION_1>
SELECT
  SID,
  SERIAL#
FROM gv$session
WHERE SID = (
  SELECT DISTINCT SID
  FROM v$mystat
);
--        SID    SERIAL#
-------- ----------
-- 	27	   25

-- SESSION_1>
UPDATE blocks_testing
SET numb = 111
WHERE name = 'first';
-- 1 row updated.

-- SESSION_2>
UPDATE blocks_testing
SET numb = 222
WHERE name = 'first';
-- Не происходит никакого вывода
-- Командная строка не появляется

-- SESSION_3>
ALTER SYSTEM KILL SESSION '27,25';

-- SESSION_2>
-- 1 row updated.


--
--
--
--
--

-- Создать Deadlock на таблице
--
-- 1. создать таблицу произвольной структуры с одним PRIMARY KEY

-- SESSION_1>
CREATE TABLE deadlocks_testing (
  id   INT NOT NULL,
  name VARCHAR2(40),
  CONSTRAINT pk PRIMARY KEY (id)
);
-- Table created.

-- SESSION_1>
INSERT INTO deadlocks_testing VALUES (1, 'first');
INSERT INTO deadlocks_testing VALUES (2, 'second');
INSERT INTO deadlocks_testing VALUES (3, 'third');

-- SESSION_1>
COMMIT;
-- Commit complete.

-- SESSION_1>
SELECT *
FROM deadlocks_testing;
-- 	ID
--------
-- NAME
------------------------------------------------------------------------------
-- 	 1
-- first
--
-- 	 2
-- second
--
-- 	 3
-- third


-- SESSION_2>
SELECT *
FROM deadlocks_testing;
-- 	ID
--------
-- NAME
------------------------------------------------------------------------------
-- 	 1
-- first
--
-- 	 2
-- second
--
-- 	 3
-- third


--
--
--
--
--

-- 2. изменять данные в таблице из 2 параллельных сессий для получения deadlock

-- SESSION_1>
UPDATE deadlocks_testing
SET name = 'aaa'
WHERE id = 1;
-- 1 row updated.

-- SESSION_2>
UPDATE deadlocks_testing
SET name = 'bbb'
WHERE id = 2;
-- 1 row updated.

-- SESSION_1>
UPDATE deadlocks_testing
SET name = 'ccc'
WHERE id = 2;
-- Не происходит никакого вывода
-- Командная строка не появляется

-- SESSION_2>
UPDATE deadlocks_testing
SET name = 'ddd'
WHERE id = 1;
-- Не происходит никакого вывода
-- Командная строка не появляется

-- SESSION_1>
-- ORA-00060: deadlock detected while waiting for resource

--
--
--
--
--

-- 3. продемонстрировать разрешение deadlock для одной из сессий (transaction fail)
-- // TODO: Как это сделать?

--
--
--
--
--

-- 4. выдержку из alert.log вашей системы

-- ORA-00060: Deadlock detected. More info in file /home/oracle/app/oracle/diag/rdbms/belo/belo/trace/belo_ora_27059.trc.
-- Mon May 21 19:38:59 2018

--
--
--
--
--

-- Управление сегментами отмены
-- Просмотр активности системы
--
-- 1. совершить длительную транзакцию (10000 Записей и более) и проанализировать статистику отмены (V$UNDOSTAT):
-- количество использованных блоков сегментов Undo, максимальная длительность запросов.
-- (структуру и описание представления взять из документации Oracle)
CREATE TABLE undo_testing (
  id   INT        NOT NULL,
  numb NUMBER(10) NOT NULL,
  CONSTRAINT undo_pk PRIMARY KEY (id)
);
-- Table created.

DECLARE
  rand_str VARCHAR(20);
BEGIN
  FOR i IN 1..100000 LOOP
    INSERT INTO undo_testing VALUES (i, i);
  END LOOP;
  COMMIT;
END;
/
-- PL/SQL procedure successfully completed.

COMMIT;
-- Commit complete.

SELECT
  TO_CHAR(BEGIN_TIME, 'HH24:MI:SS DD.MM.YYYY') "BEGIN_TIME",
  MAXQUERYLEN,
  UNDOBLKS
FROM V$UNDOSTAT
ORDER BY begin_time;
-- BEGIN_TIME						  MAXQUERYLEN	UNDOBLKS
-- ---------------------------------------------------------
-- 15:43:09 21.05.2018						  285	       5
-- 15:53:09 21.05.2018						  885	      62
-- 16:03:09 21.05.2018						  280	       1
-- 16:13:09 21.05.2018						  881	       0
-- 16:23:09 21.05.2018						  278	       2
-- 16:33:09 21.05.2018						  880	       3
-- 16:43:09 21.05.2018						  276	       5
-- 16:53:09 21.05.2018						  876	     401
-- 17:03:09 21.05.2018						  272	       2
-- 17:13:09 21.05.2018						  873	       1
-- 17:23:09 21.05.2018						  269	       0
--
-- BEGIN_TIME						  MAXQUERYLEN	UNDOBLKS
-- ---------------------------------------------------------
-- 17:33:09 21.05.2018						    0	       0
-- 17:43:09 21.05.2018						    0	       0
-- 19:13:09 21.05.2018						    0	      66
-- 19:23:09 21.05.2018						  623	       2
-- 19:33:09 21.05.2018						 1226	       2
-- 19:43:09 21.05.2018						  623	       0
-- 19:53:09 21.05.2018						 1223	      71
-- 20:03:09 21.05.2018						  318	    2281 <<<--------

--
--
--
--
--

-- 2. с использованием 1) вычислить размер табличного пространства отмены
-- для поддержки 1-часового undo retention interval

SELECT
  d.undo_size / (1024 * 1024)                                        "ACTUAL UNDO SIZE [MByte]",
  SUBSTR(e.value, 1, 25)                                             "UNDO RETENTION [Sec]",
  ROUND((d.undo_size / (to_number(f.value) * g.undo_block_per_sec))) "OPTIMAL UNDO RETENTION [Sec]"
FROM (
       SELECT SUM(a.bytes) undo_size
       FROM
         v$datafile a,
         v$tablespace b,
         dba_tablespaces c
       WHERE c.contents = 'UNDO'
             AND c.status = 'ONLINE'
             AND b.name = c.tablespace_name
             AND a.ts# = b.ts#
     ) d,
  v$parameter e,
  v$parameter f,
  (
    SELECT MAX(undoblks / ((end_time - begin_time) * 3600 * 24))
      undo_block_per_sec
    FROM v$undostat
  ) g
WHERE e.name = 'undo_retention'
      AND f.name = 'db_block_size'
/

-- ACTUAL UNDO SIZE [MByte]
-- 660
-- ------------------------
-- UNDO RETENTION [Sec]
-- 900
-- ------------------------
-- OPTIMAL UNDO RETENTION [Sec]
-- 22202
-- ------------------------

-- Для часового undo retention interval:
-- 660 * (60 * 60 / 900) = 660 * 4 = 2640 Mbyte

--
--
--
--
--

-- 3. продемонстрировать настроечные параметры для UNDO, атрибуты табличного пространства для UNDO,
--  установленные по-умолчанию для вашей системы
SHOW PARAMETERS UNDO;
-- NAME				     TYPE			       VALUE
-- ------------------------------------ ---------------------------------
-- undo_management 		     string			       AUTO
-- undo_retention			     integer			       900
-- undo_tablespace 		     string			       UNDOTBS1

SELECT *
FROM v$tablespace
WHERE name = 'UNDOTBS1';
--        TS# NAME 										      INCLUDED_ BIGFILE   FLASHBACK ENCRYPT_I
-------- ------------------------------------------------------------------------------------------
-- 	 2 UNDOTBS1										      YES	NO	  YES


--
--
--
--
--

-- 4. Измененить настройки табличного пространства отмены для поддержки 1-часового гарантированного интервала хранения
CREATE UNDO TABLESPACE UNDOTBS2
DATAFILE '/home/oracle/app/oracle/oradata/belo/ilya_new.dbf'
SIZE 500M AUTOEXTEND ON NEXT 5M;
-- Tablespace created.

ALTER SYSTEM SET UNDO_TABLESPACE = UNDOTBS2
SCOPE = BOTH;
-- System altered.

ALTER SYSTEM SET UNDO_RETENTION = 3600
SCOPE = BOTH;
-- System altered.

SHOW PARAMETERS UNDO;
-- NAME				     TYPE			       VALUE
---------------------------------- --------------------------------- ------------------------------
-- undo_management 		     string			       AUTO
-- undo_retention			     integer			       3600
-- undo_tablespace 		     string			       UNDOTBS2