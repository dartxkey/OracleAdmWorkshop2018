SET VERIFY OFF
connect "SYS"/"&&sysPassword" as SYSDBA
set echo off
spool /home/oracle/kkm_script/emRepository.log append
@/home/oracle/app/oracle/product/11.2.0/dbhome_1/sysman/admin/emdrep/sql/emreposcre /home/oracle/app/oracle/product/11.2.0/dbhome_1 SYSMAN SYSMAN TEMP ON;
WHENEVER SQLERROR CONTINUE;
spool off
