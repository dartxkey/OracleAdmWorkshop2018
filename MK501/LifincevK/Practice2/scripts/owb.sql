SET VERIFY OFF
connect "SYS"/"&&sysPassword" as SYSDBA
set echo on
spool /home/oracle/app/oracle/admin/Lifintsev/scripts/owb.log append
@/home/oracle/app/oracle/product/11.2.0/dbhome_1/owb/UnifiedRepos/cat_owb.sql KIRI TEMP;
spool off
