SET VERIFY OFF
connect "SYS"/"&&sysPassword" as SYSDBA
set echo on
spool /home/oracle/kkm_script/context.log append
@/home/oracle/app/oracle/product/11.2.0/dbhome_1/ctx/admin/catctx change_on_install SYSAUX TEMP NOLOCK;
connect "CTXSYS"/"change_on_install"
@/home/oracle/app/oracle/product/11.2.0/dbhome_1/ctx/admin/defaults/dr0defin.sql "AMERICAN";
spool off
