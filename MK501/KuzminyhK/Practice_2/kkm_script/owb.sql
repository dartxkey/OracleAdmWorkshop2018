SET VERIFY OFF
connect "SYS"/"&&sysPassword" as SYSDBA
set echo on
spool /home/oracle/kkm_script/owb.log append
@/home/oracle/app/oracle/product/11.2.0/dbhome_1/owb/UnifiedRepos/cat_owb.sql SYSAUX TEMP;
spool off
