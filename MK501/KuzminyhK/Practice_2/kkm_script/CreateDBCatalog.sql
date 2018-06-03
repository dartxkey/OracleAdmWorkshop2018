SET VERIFY OFF
connect "SYS"/"&&sysPassword" as SYSDBA
set echo on
spool /home/oracle/kkm_script/CreateDBCatalog.log append
@/home/oracle/app/oracle/product/11.2.0/dbhome_1/rdbms/admin/catalog.sql;
@/home/oracle/app/oracle/product/11.2.0/dbhome_1/rdbms/admin/catblock.sql;
@/home/oracle/app/oracle/product/11.2.0/dbhome_1/rdbms/admin/catproc.sql;
@/home/oracle/app/oracle/product/11.2.0/dbhome_1/rdbms/admin/catoctk.sql;
@/home/oracle/app/oracle/product/11.2.0/dbhome_1/rdbms/admin/owminst.plb;
connect "SYSTEM"/"&&systemPassword"
@/home/oracle/app/oracle/product/11.2.0/dbhome_1/sqlplus/admin/pupbld.sql;
connect "SYSTEM"/"&&systemPassword"
set echo on
spool /home/oracle/kkm_script/sqlPlusHelp.log append
@/home/oracle/app/oracle/product/11.2.0/dbhome_1/sqlplus/admin/help/hlpbld.sql helpus.sql;
spool off
spool off
