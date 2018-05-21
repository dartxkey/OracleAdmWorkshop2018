-- 1. создать базу данных с использованием DBCA
-- a. SID базы данных = первые 4 буквы ФИО: belo
-- b. размер блока данных: 8K
-- c. пользовательское табличное пространство (First Name%4): ilya
-- Type: Auto
-- Sizing: auto

CREATE USER iksent IDENTIFIED BY iksent;
-- User created.
SELECT 'IKSENT'
FROM dba_users;

GRANT CREATE SESSION TO IKSENT;
-- Grant succeeded.

CREATE TABLESPACE ilya DATAFILE '/home/oracle/app/oracle/oradata/belo/ilya.dbf' SIZE 500M;

SELECT
  tablespace_name,
  extent_management,
  allocation_type,
  segment_space_management
FROM dba_tablespaces;

-- TABLESPACE_NAME
-- --------------------------------------------------------------------------------
-- EXTENT_MANAGEMENT	       ALLOCATION_TYPE		   SEGMENT_SPACE_MANA
-- ------------------------------ --------------------------- ------------------
-- TEMP
-- LOCAL			       UNIFORM			   MANUAL
--
-- ILYA
-- LOCAL			       SYSTEM			   AUTO
--
-- USERS
-- LOCAL			       SYSTEM			   AUTO


--
--
--
--
--

-- 2. сгенерировать скрипты создания БД с использованием DBCA, сохранить конфигурацию БД как HTML
-- Скрипты: scripts.zip
-- Конфигурация БД: config.html

--
--
--
--
--

-- 3. создать шаблон базы данных на основе созданной и запущенной БД. Имя произвольное.

--
--
--
--
--

-- 4. доказать работу экземпляра: вывод из представления словаря данных V$

-- Подключаемся к Базе Данных:
-- [oracle@localhost ~]$ sqlplus sys@belo as sysdba

-- Возникает ошибка Listener'а. Включаем его:
-- [oracle@localhost ~]$ set ORACLE_HOME= cd %ORACLE_HOME%/bin lsnrctl start LISTENER

-- Подключаемся к Базе Данных. Возникает ошибка:
-- ERROR:
-- ORA-12514: TNS:listener does not currently know of service requested in connect descriptor

-- Решение:
-- export ORACLE_HOME=/home/oracle/app/oracle/product/11.2.0/dbhome_1
-- export ORACLE_SID=belo
-- export LD_LIBRARY_PATH=$ORACLE_HOME/lib

-- Подключаемся к Базе Данных. Успешно:
-- [oracle@localhost ~]$ sqlplus sys as sysdba
-- Connected to:
-- Oracle Database 11g Enterprise Edition Release 11.2.0.1.0 - 64bit

SELECT
  INSTANCE_NAME,
  STATUS,
  SHUTDOWN_PENDING,
  ACTIVE_STATE
FROM V$INSTANCE;

-- INSTANCE_NAME					 STATUS 			      SHUTDOWN_PENDING ACTIVE_STATE
-- ------------------------------------------------ ------------------------------------
-- belo						 OPEN				      NO	NORMAL


SELECT
  NAME,
  LOG_MODE,
  FLASHBACK_ON
FROM V$DATABASE;

-- NAME			    LOG_MODE				 FLASHBACK_ON
------------------------- ------------------------------------
-- BELO			    NOARCHIVELOG			 NO

--
--
--
--
--

-- 5. создать SPFILE для экземпляра

CREATE SPFILE = 's_params.ora'
FROM PFILE = '/home/oracle/app/oracle/admin/belo/scripts/init.ora';

--
--
--
--
--

-- 6. изменить любой параметр системы только для текущего экземпляра. Доказать выводов V$ и cat файла инициализации

-- Смотрим, какие значения есть в файле инициализации:
-- cat '/home/oracle/app/oracle/admin/belo/scripts/init.ora';

-- Смотрим, какие значения мы можем менять:
SELECT NAME
FROM V$PARAMETER
WHERE ISSYS_MODIFIABLE = 'IMMEDIATE';

-- Меняем значение:
ALTER SYSTEM SET OPEN_CURSORS = 123
SCOPE = MEMORY;
-- System altered.

SELECT
  NAME,
  VALUE
FROM V$PARAMETER
WHERE NAME = 'open_cursors';
-- NAME
-- ------------------------------
-- VALUE
-- ------------------------------
-- open_cursors
-- 123

-- Смотрим на значение этого параметра в файле инициализации:
-- cat '/home/oracle/app/oracle/admin/belo/scripts/init.ora';
-- ...
-- ###########################################
-- # Cursors and Library Cache
-- ###########################################
-- open_cursors=300
-- ...

--
--
--
--
--

-- 7.варианты монтирования и остановки БД
-- a. перевести БД в режим READ ONLY

SELECT OPEN_MODE
FROM V$DATABASE;
-- OPEN_MODE
----------------------------------------------------------
-- READ WRITE

SHUTDOWN IMMEDIATE;
-- Database closed.
-- Database dismounted.
-- ORACLE instance shut down.

STARTUP MOUNT;
-- ORACLE instance started.
-- Total System Global Area  680607744 bytes
-- Fixed Size		    2216464 bytes
-- Variable Size		  440405488 bytes
-- Database Buffers	  230686720 bytes
-- Redo Buffers		    7299072 bytes
-- Database mounted.

ALTER DATABASE OPEN READ ONLY;
-- Database altered.

SELECT OPEN_MODE
FROM V$DATABASE;
-- OPEN_MODE
-- ------------------------------------------------------------
-- READ ONLY

-- Возвращаем, как было:
SHUTDOWN IMMEDIATE;
STARTUP MOUNT;
ALTER DATABASE OPEN READ WRITE;
-- Database altered.

-- b. перевести БД в режим RESTRICT и перевод в открытую (ALTER SYSTEM DISABLE RESTRICTED SESSION;)
ALTER SYSTEM ENABLE RESTRICTED SESSION;
-- System altered.

CREATE USER testuser IDENTIFIED BY test;
GRANT CONNECT, RESOURCE, DBA TO testuser;
GRANT CREATE SESSION TO testuser WITH ADMIN OPTION;
GRANT UNLIMITED TABLESPACE TO testuser;

-- [oracle@localhost ~]$ sqlplus testuser/test@belo

-- ERROR:
-- ORA-12526: TNS:listener: all appropriate instances are in restricted mode

ALTER SYSTEM DISABLE RESTRICTED SESSION;

-- [oracle@localhost ~]$ sqlplus testuser/test@belo

-- Connected to:
-- Oracle Database 11g Enterprise Edition Release 11.2.0.1.0 - 64bit Production
-- With the Partitioning, OLAP, Data Mining and Real Application Testing options

-- c. SHUTDOWN (NORMAL/TRANSACTIONAL/IMMEDIATE/ABORT)
-- i. выполнить эксперимент с живой транзакцией IMMEDIATE - получить сообщение о принудительном завершении транзакции
-- ii. для ABORT RECOVER DATABASE

SHUTDOWN NORMAL;
-- Ничего не происходит, пока testuser имеет коннект с БД. После дисконнекта:
-- Database closed.
-- Database dismounted.
-- ORACLE instance shut down.

SHUTDOWN TRANSACTIONAL;
-- Ничего не происходит, пока testuser не напишет COMMIT. После COMMIT:
-- Database closed.
-- Database dismounted.
-- ORACLE instance shut down.

SHUTDOWN IMMEDIATE;
-- testuser: невозможно выполнить COMMIT
-- Database closed.
-- Database dismounted.
-- ORACLE instance shut down.

SHUTDOWN ABORT;
-- ORACLE instance shut down.

STARTUP MOUNT;
-- ORACLE instance started.

RECOVER DATABASE;
-- Media recovery complete.

--
--
--
--
--

-- 8. Перевести базу в SUSPEND/вывести из SUSPEND (RESUME), проверка по V$INSTANCE
SELECT DATABASE_STATUS
FROM V$INSTANCE;
-- DATABASE_STATUS
-------------------------------------------------
-- ACTIVE

ALTER SYSTEM SUSPEND;
-- System altered.

SELECT DATABASE_STATUS
FROM V$INSTANCE;
-- DATABASE_STATUS
-------------------------------------------------
-- SUSPENDED

ALTER SYSTEM RESUME;
-- System altered.

SELECT DATABASE_STATUS
FROM V$INSTANCE;
-- DATABASE_STATUS
-------------------------------------------------
-- ACTIVE

--
--
--
--
--

-- 9.
ALTER SYSTEM SET OPTIMIZER_MODE = RULE
SCOPE = SPFILE;

-- System altered.

SELECT VALUE
FROM V$PARAMETER
WHERE NAME = 'optimizer_mode'
UNION ALL
SELECT VALUE
FROM V$SPPARAMETER
WHERE NAME = 'optimizer_mode';

-- VALUE
------------------------------------------------------
-- ALL_ROWS
-- RULE
--

--
--
--
--
--

-- 10.создать двух пользователей:
-- a. владелец приложения: без квоты на создание объектов, без ограничений по времени сессии, количеству сессий, роли для просмотра словаря данных и динамических представлений
CREATE PROFILE APP_OWNER_PROFILE LIMIT SESSIONS_PER_USER UNLIMITED CONNECT_TIME UNLIMITED;
-- Profile created.
CREATE USER APP_OWNER IDENTIFIED BY APP_OWNER;
-- User created.
ALTER USER APP_OWNER PROFILE APP_OWNER_PROFILE;
-- User altered.
GRANT UNLIMITED TABLESPACE TO APP_OWNER;
-- Grant succeeded.
GRANT SELECT_CATALOG_ROLE TO APP_OWNER;
-- Grant succeeded.

-- b. ограниченный: квота 50М, 15 мин простоя сессии, макс 2 сессии, без доступа к словарю данных
-- для обоих пользователей: минимальная длина пароля: 6 символов + сложность по желанию.
CREATE PROFILE APP_LIMITED_PROFILE LIMIT IDLE_TIME 900 SESSIONS_PER_USER 2;
-- Profile created.
CREATE USER APP_LIMITED IDENTIFIED BY APP_LIMITED;
-- User created.
ALTER USER APP_LIMITED PROFILE APP_LIMITED_PROFILE;
-- User altered.
ALTER USER APP_LIMITED QUOTA 50M ON USERS;
-- User altered.

--
--
--
--
--

-- 11. продемонстрировать пользователя в dba_users, выборка параметров профиля для пользователя.
SELECT
  USERNAME,
  DEFAULT_TABLESPACE,
  PROFILE,
  ACCOUNT_STATUS
FROM dba_users
WHERE USERNAME = 'APP_OWNER' OR USERNAME = 'APP_LIMITED';
-- USERNAME
-- --------------------------------------------------------------------------------
-- DEFAULT_TABLESPACE
-- --------------------------------------------------------------------------------
-- PROFILE
-- --------------------------------------------------------------------------------
-- ACCOUNT_STATUS
-- --------------------------------------------------------------------------------
-- APP_LIMITED
-- USERS
-- APP_LIMITED_PROFILE
-- OPEN
--
--
-- USERNAME
-- --------------------------------------------------------------------------------
-- DEFAULT_TABLESPACE
-- --------------------------------------------------------------------------------
-- PROFILE
-- --------------------------------------------------------------------------------
-- ACCOUNT_STATUS
-- --------------------------------------------------------------------------------
-- APP_OWNER
-- USERS
-- APP_OWNER_PROFILE
-- OPEN


--
--
--
--
--

-- 12. Создать пользователей, применить созданные профили к ним.
-- Сделано ранее

--
--
--
--
--

-- 13.Установить профиль b) как значение По-умолчанию для всех вновь создаваемых пользователей,
-- продемонстрировать вывод select для пользователя, продемонстрировать параметры профиля пользователя.
SELECT PROFILE
FROM dba_users
WHERE USERNAME = 'IKSENT';

-- PROFILE
-- --------------------------------------------------------------------------------
-- DEFAULT

ALTER PROFILE DEFAULT LIMIT SESSIONS_PER_USER 2 IDLE_TIME 900;
-- Profile altered.

-- Продемонстрировать параметры профиля пользователя.
SELECT *
FROM DBA_PROFILES
WHERE PROFILE = (
  SELECT PROFILE
  FROM dba_users
  WHERE USERNAME = 'IKSENT'
);


--
-- ...
--
-- PROFILE
-- --------------------------------------------------------------------------------
-- RESOURCE_NAME
-- --------------------------------------------------------------------------------
-- RESOURCE_TYPE
-- ------------------------
-- LIMIT
-- --------------------------------------------------------------------------------
-- DEFAULT
-- PASSWORD_GRACE_TIME
-- PASSWORD
-- 7
--
-- ...
--

-- 16 rows selected.

