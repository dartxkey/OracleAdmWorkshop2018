SET VERIFY OFF
set echo on
spool /home/oracle/kkm_script/cwmlite.log append
connect "SYS"/"&&sysPassword" as SYSDBA
@/home/oracle/app/oracle/product/11.2.0/dbhome_1/olap/admin/olap.sql SYSAUX TEMP;
spool off
