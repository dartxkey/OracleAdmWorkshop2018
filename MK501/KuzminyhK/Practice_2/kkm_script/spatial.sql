SET VERIFY OFF
connect "SYS"/"&&sysPassword" as SYSDBA
set echo on
spool /home/oracle/kkm_script/spatial.log append
@/home/oracle/app/oracle/product/11.2.0/dbhome_1/md/admin/mdinst.sql;
spool off
