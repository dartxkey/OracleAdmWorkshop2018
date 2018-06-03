SET VERIFY OFF
connect "SYS"/"&&sysPassword" as SYSDBA
set echo on
spool /home/oracle/kkm_script/interMedia.log append
@/home/oracle/app/oracle/product/11.2.0/dbhome_1/ord/im/admin/iminst.sql;
spool off
