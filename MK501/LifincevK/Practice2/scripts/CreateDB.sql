SET VERIFY OFF
connect "SYS"/"&&sysPassword" as SYSDBA
set echo on
spool /home/oracle/app/oracle/admin/Lifintsev/scripts/CreateDB.log append
startup nomount pfile="/home/oracle/app/oracle/admin/Lifintsev/scripts/init.ora";
CREATE DATABASE "Lifintse"
MAXINSTANCES 8
MAXLOGHISTORY 1
MAXLOGFILES 16
MAXLOGMEMBERS 3
MAXDATAFILES 100
DATAFILE '/home/oracle/app/oracle/oradata/Lifintsev/system01.dbf' SIZE 700M REUSE AUTOEXTEND ON NEXT  10240K MAXSIZE UNLIMITED
EXTENT MANAGEMENT LOCAL
SYSAUX DATAFILE '/home/oracle/app/oracle/oradata/Lifintsev/sysaux01.dbf' SIZE 600M REUSE AUTOEXTEND ON NEXT  10240K MAXSIZE UNLIMITED
SMALLFILE DEFAULT TEMPORARY TABLESPACE TEMP TEMPFILE '/home/oracle/app/oracle/oradata/Lifintsev/temp01.dbf' SIZE 20M REUSE AUTOEXTEND ON NEXT  640K MAXSIZE UNLIMITED
SMALLFILE UNDO TABLESPACE "UNDOTBS1" DATAFILE '/home/oracle/app/oracle/oradata/Lifintsev/undotbs01.dbf' SIZE 200M REUSE AUTOEXTEND ON NEXT  5120K MAXSIZE UNLIMITED
CHARACTER SET AL32UTF8
NATIONAL CHARACTER SET UTF8
LOGFILE GROUP 1 ('/home/oracle/app/oracle/oradata/Lifintsev/redo01.log') SIZE 51200K,
GROUP 2 ('/home/oracle/app/oracle/oradata/Lifintsev/redo02.log') SIZE 51200K,
GROUP 3 ('/home/oracle/app/oracle/oradata/Lifintsev/redo03.log') SIZE 51200K
USER SYS IDENTIFIED BY "&&sysPassword" USER SYSTEM IDENTIFIED BY "&&systemPassword";
spool off
