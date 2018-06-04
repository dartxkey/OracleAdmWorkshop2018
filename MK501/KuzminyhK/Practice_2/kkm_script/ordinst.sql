SET VERIFY OFF
connect "SYS"/"&&sysPassword" as SYSDBA
set echo on
spool /home/oracle/kkm_script/ordinst.log append
@/home/oracle/app/oracle/product/11.2.0/dbhome_1/ord/admin/ordinst.sql SYSAUX SYSAUX;
spool off
