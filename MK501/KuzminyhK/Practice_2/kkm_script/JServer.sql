SET VERIFY OFF
connect "SYS"/"&&sysPassword" as SYSDBA
set echo on
spool /home/oracle/kkm_script/JServer.log append
@/home/oracle/app/oracle/product/11.2.0/dbhome_1/javavm/install/initjvm.sql;
@/home/oracle/app/oracle/product/11.2.0/dbhome_1/xdk/admin/initxml.sql;
@/home/oracle/app/oracle/product/11.2.0/dbhome_1/xdk/admin/xmlja.sql;
@/home/oracle/app/oracle/product/11.2.0/dbhome_1/rdbms/admin/catjava.sql;
@/home/oracle/app/oracle/product/11.2.0/dbhome_1/rdbms/admin/catexf.sql;
spool off
