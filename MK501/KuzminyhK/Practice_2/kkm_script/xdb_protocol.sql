SET VERIFY OFF
connect "SYS"/"&&sysPassword" as SYSDBA
set echo on
spool /home/oracle/kkm_script/xdb_protocol.log append
@/home/oracle/app/oracle/product/11.2.0/dbhome_1/rdbms/admin/catqm.sql change_on_install SYSAUX TEMP;
connect "SYS"/"&&sysPassword" as SYSDBA
@/home/oracle/app/oracle/product/11.2.0/dbhome_1/rdbms/admin/catxdbj.sql;
@/home/oracle/app/oracle/product/11.2.0/dbhome_1/rdbms/admin/catrul.sql;
spool off
