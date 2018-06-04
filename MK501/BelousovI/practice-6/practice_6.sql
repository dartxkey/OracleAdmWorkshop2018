-- 1. Создать отдельное табличное пространство UNDOTS_G (AUM)

CREATE UNDO TABLESPACE UNDOTS_G DATAFILE 'undots_g_aum.dbf' SIZE 10M AUTOEXTEND ON RETENTION GUARANTEE;
-- Tablespace created.

-- a) Установить гарантированный UNDO_RETENTION 15 минут.

ALTER SYSTEM SET UNDO_RETENTION = 900
SCOPE = BOTH;
-- System altered.

--
--
--
--
--

-- 2. используя таблицу HR.EMPLOYEES (или созданную вами)
-- - изменить + удалить запись, использую Flashback Versions показать историю изменений

CREATE TABLE ACTIONS (
  ID     NUMBER,
  ACTION VARCHAR2(100)
);

INSERT INTO ACTIONS (ID, ACTION) VALUES (1, 'New Year');
INSERT INTO ACTIONS (ID, ACTION) VALUES (2, 'Birthday');
INSERT INTO ACTIONS (ID, ACTION) VALUES (3, '8 march');
INSERT INTO ACTIONS (ID, ACTION) VALUES (4, '23 february');
DELETE FROM ACTIONS
WHERE ID = 2;

COMMIT;

SELECT
  to_char(versions_starttime, 'HH24:MI:SS DD.MM.YYYY') START_TIME,
  to_char(versions_endtime, 'HH24:MI:SS DD.MM.YYYY')   END_TIME,
  versions_operation                                   OPERATION,
  ID,
  ACTION
FROM ACTIONS VERSIONS BETWEEN TIMESTAMP MINVALUE AND MAXVALUE
ORDER BY versions_starttime;

-- START_TIME						  END_TIME						    OPE 	ID
-- ---------------------------------------------------------
-- ACTION
-- ----------------------------------------------------------
-- 20:32:09 01.06.2018												    I		 3
-- 8 march
--
-- 20:32:09 01.06.2018												    I		 4
-- 23 february
--
-- 20:32:09 01.06.2018												    I		 1
-- New Year
--
--
-- START_TIME						  END_TIME						    OPE 	ID
-- ---------------------------------------------------------
-- ACTION
-- -------------------------------------------------------------------------
-- 20:32:09 01.06.2018					  20:41:49 01.06.2018					    I		 2
-- Birthday
--
-- 20:41:49 01.06.2018												    D		 2

-- - восстановить запись через flasback query

SELECT *
FROM ACTIONS;

-- 	ID ACTION
-------- ---------------------------------------------------------------------
-- 	 1 New Year
-- 	 3 8 march
-- 	 4 23 february

SELECT *
FROM ACTIONS AS OF TIMESTAMP TO_TIMESTAMP('20:40:00 01.06.2018', 'HH24:MI:SS DD.MM.YYYY');

-- 	ID ACTION
-------- ---------------------------------------------------------------------
-- 	 1 New Year
-- 	 2 Birthday
-- 	 3 8 march
-- 	 4 23 february

-- - выполнить добавление записей в hr.departments

INSERT INTO ACTIONS (ID, ACTION) VALUES (22, 'New Year 2017');
INSERT INTO ACTIONS (ID, ACTION) VALUES (33, 'New Year 2018');

SELECT *
FROM ACTIONS;

-- 	ID ACTION
-- ---------- ---------------------------------------------------------------------
-- 	 1 New Year
-- 	 3 8 march
-- 	 4 23 february
-- 	22 New Year 2017
-- 	33 New Year 2018

-- - используя Flashback Table сделать выборку из таблицы до вставки

FLASHBACK TABLE ACTIONS TO TIMESTAMP TO_TIMESTAMP('20:55:00 01.06.2018', 'HH24:MI:SS DD.MM.YYYY');

-- 	ID ACTION
-- ---------- ---------------------------------------------------------------------
-- 	 1 New Year
-- 	 3 8 march
-- 	 4 23 february

-- - откатить последнюю вставку в hr.departments через Flashback Transaction Backout (понадобится Flashback Versions/Query для получения SCN)
ALTER DATABASE ADD SUPPLEMENTAL LOG DATA;

INSERT INTO ACTIONS VALUES (100, 'Happy New Year');
COMMIT;

SELECT *
FROM ACTIONS;
-- 	ID ACTION
-- ---------- ---------------------------------------------------------------------
-- 	 1 New Year
-- 	 3 8 march
-- 	 4 23 february
-- 	22 New Year 2017
-- 	33 New Year 2018
-- 100 Happy New Year

SELECT
  versions_xid XID,
  ID,
  ACTION
FROM ACTIONS VERSIONS BETWEEN TIMESTAMP MINVALUE AND MAXVALUE
ORDER BY versions_startscn;

-- XID		  START_SCN    END_SCN OP	   ID ACTION
-- ---------------- ---------- ---------- --- ---------- --------------------------
-- 13000F0019000000     937953	       D	    2 Birthday
-- 0B000C0015000000     938344	       I	   33 New Year 2018
-- 0B000C0015000000     938344	       I	   22 New Year 2017
-- 11001B0014000000     938588	       I	  100 Happy New Year
-- 						                                 4 23 february
-- 						                                 1 New Year
-- 				              937953		             2 Birthday
-- 						                                 3 8 march

-- SHOW parameter recovery_file_dest;

-- NAME				     TYPE			       VALUE
-- ------------------------------------ --------------------------------- ------------------------------
-- db_recovery_file_dest		     string			       /home/oracle/app/oracle/flash_recovery_area/belo
-- db_recovery_file_dest_size	     big integer		       512M

ALTER SYSTEM SWITCH LOGFILE;
ALTER DATABASE FLASHBACK ON;

DECLARE
  xid XID_ARRAY;
BEGIN
  xid := xid_array('11001B0014000000');
  DBMS_FLASHBACK.transaction_backout(1, xid, DBMS_FLASHBACK.nocascade);
END;
/

-- И у меня возникает ошибка, которую я не могу никак исправить:
--
-- ERROR at line 1:
-- ORA-55507: Encountered mining error during Flashback Transaction Backout. function:krvxglsr
-- ORA-06512: at "SYS.DBMS_FLASHBACK", line 37
-- ORA-06512: at "SYS.DBMS_FLASHBACK", line 70
-- ORA-06512: at line 5

--
--
--
--
--

-- 3. Удостоверится, что БД рабоатет в ARCHIVELOG
SELECT LOG_MODE
FROM SYS.V$DATABASE;

-- LOG_MODE
----------------------------------
-- ARCHIVELOG

--
--
--
--
--

-- 4. Мультиплексировать Control Files До 4 экземпляров в разных локациях.

-- Следует сохранять копии управляющих файлов на разных дисках для минимизации риска
-- утраты этих важных физических дисковых ресурсов. Oracle рекомендует перенести эти
-- управляющие файлы на разные дисковые ресурсы и задать параметр CONTROL_FILES, чтобы
-- Oracle знала, что существует несколько копий управляющего файла, которые требуется
-- сопровождать. Это называется мультиплексированием (multiplexing) или зеркальным
-- отображением (mirroring) управляющего файла. Мультиплексирование управляющего
-- файла снижает зависимость Oracle от доступности какого-либо из дисков на хост-машине.
-- В случае сбоя базу данных легче восстановить, так как поддерживалось несколько копий
-- управляющего файла. Ни в коем случае не следует использовать для базы данных Oracle
-- только один управляющий файл, поскольку в случае его утраты трудно восстановить базу данных.

-- ls /home/oracle/app/oracle/oradata/belo/

ALTER SYSTEM SET control_files = '/home/oracle/app/oracle/oradata/belo/control01.ctl',
'/home/oracle/Public/belo_control01_1.ctl',
'/home/oracle/Public/belo_control01_2.ctl',
'/home/oracle/Public/belo_control01_3.ctl'
SCOPE = SPFILE;
-- System altered.

SHUTDOWN;
-- Database closed.
-- Database dismounted.
-- ORACLE instance shut down.

-- cp /home/oracle/app/oracle/oradata/belo/control01.ctl /home/oracle/Public/belo_control01_1.ctl
-- cp /home/oracle/app/oracle/oradata/belo/control01.ctl /home/oracle/Public/belo_control01_2.ctl
-- cp /home/oracle/app/oracle/oradata/belo/control01.ctl /home/oracle/Public/belo_control01_3.ctl
STARTUP;
-- ORACLE instance started.