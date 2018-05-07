SET VERIFY OFF
connect "SYS"/"&&sysPassword" as SYSDBA
set echo on
spool /home/oracle/app/oracle/admin/Lifintsev/scripts/xdb_protocol.log append
@/home/oracle/app/oracle/product/11.2.0/dbhome_1/rdbms/admin/catqm.sql change_on_install KIRI TEMP;
connect "SYS"/"&&sysPassword" as SYSDBA
@/home/oracle/app/oracle/product/11.2.0/dbhome_1/rdbms/admin/catxdbj.sql;
@/home/oracle/app/oracle/product/11.2.0/dbhome_1/rdbms/admin/catrul.sql;
spool off
