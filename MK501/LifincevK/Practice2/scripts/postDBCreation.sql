SET VERIFY OFF
connect "SYS"/"&&sysPassword" as SYSDBA
set echo on
spool /home/oracle/app/oracle/admin/Lifintsev/scripts/postDBCreation.log append
select 'utl_recomp_begin: ' || to_char(sysdate, 'HH:MI:SS') from dual;
execute utl_recomp.recomp_serial();
select 'utl_recomp_end: ' || to_char(sysdate, 'HH:MI:SS') from dual;
connect "SYS"/"&&sysPassword" as SYSDBA
set echo on
create spfile='/home/oracle/app/oracle/product/11.2.0/dbhome_1/dbs/spfilelifi.ora' FROM pfile='/home/oracle/app/oracle/admin/Lifintsev/scripts/init.ora';
shutdown immediate;
connect "SYS"/"&&sysPassword" as SYSDBA
startup ;
spool off
