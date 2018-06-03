-- 1. Вывести текущие настройки RMAN

-- В консоли вводим:
-- [oracle@ip-192-168-121-135 ~]$ rman

-- RMAN> CONNECT target sys/1
-- connected to target database: BELO (DBID=3000137320)

-- RMAN> SHOW ALL;

-- using target database control file instead of recovery catalog
-- RMAN configuration parameters for database with db_unique_name BELO are:
-- CONFIGURE RETENTION POLICY TO REDUNDANCY 1; # default
-- CONFIGURE BACKUP OPTIMIZATION OFF; # default
-- CONFIGURE DEFAULT DEVICE TYPE TO DISK; # default
-- CONFIGURE CONTROLFILE AUTOBACKUP OFF; # default
-- CONFIGURE CONTROLFILE AUTOBACKUP FORMAT FOR DEVICE TYPE DISK TO '%F'; # default
-- CONFIGURE DEVICE TYPE DISK PARALLELISM 1 BACKUP TYPE TO BACKUPSET; # default
-- CONFIGURE DATAFILE BACKUP COPIES FOR DEVICE TYPE DISK TO 1; # default
-- CONFIGURE ARCHIVELOG BACKUP COPIES FOR DEVICE TYPE DISK TO 1; # default
-- CONFIGURE MAXSETSIZE TO UNLIMITED; # default
-- CONFIGURE ENCRYPTION FOR DATABASE OFF; # default
-- CONFIGURE ENCRYPTION ALGORITHM 'AES128'; # default
-- CONFIGURE COMPRESSION ALGORITHM 'BASIC' AS OF RELEASE 'DEFAULT' OPTIMIZE FOR LOAD TRUE ; # default
-- CONFIGURE ARCHIVELOG DELETION POLICY TO NONE; # default
-- CONFIGURE SNAPSHOT CONTROLFILE NAME TO '/home/oracle/app/oracle/product/11.2.0/dbhome_1/dbs/snapcf_belo.f'; # default


--
--
--
--
--

-- 2. Создать схему каталог восстановления

-- Создаём табличное пространство:
CREATE TABLESPACE rcat_ts
DATAFILE 'rcat_df' SIZE 100M AUTOEXTEND OFF
EXTENT MANAGEMENT LOCAL
SEGMENT SPACE MANAGEMENT AUTO;
-- Tablespace created.

-- В SQL Создаём владельца каталога восстановления.
CREATE USER rcat_owner IDENTIFIED BY '1'
  TEMPORARY TABLESPACE temp
  DEFAULT TABLESPACE rcat_ts
  QUOTA UNLIMITED ON rcat_ts;
-- User created.

-- Роль RECOVERY_CATALOG_OWNER предоставляет привилегии для владельца каталога восстановления.
GRANT CONNECT, RESOURCE, RECOVERY_CATALOG_OWNER TO rcat_owner;
-- Grant succeeded.

-- Создание Каталога Восстановления
-- Соединяемся с базой данных каталога восстановления как владелец каталога:

-- RMAN> CONNECT CATALOG rcat_owner/1;
-- connected to target database: BELO (DBID=3000137320)
-- connected to recovery catalog database

-- RMAN> CREATE CATALOG;
-- recovery catalog created

-- RMAN> REGISTER DATABASE;
-- database registered in recovery catalog
-- starting full resync of recovery catalog
-- full resync complete

--
--
--
--
--

-- 3. Выполнить полный бэкап базы как сжатый backupset вместе с архивлогами на тип DISK
-- connect target sys/1@belo
-- RMAN> BACKUP DEVICE TYPE DISK AS COMPRESSED BACKUPSET DATABASE PLUS ARCHIVELOG;

--
--
--
--
--

-- 4. Сделать backup control файла и spfile в каталог /bck/
-- RMAN> BACKUP CURRENT CONTROLFILE FORMAT '/bck/%U';
-- RMAN> BACKUP SPFILE FORMAT '/bck/%U';