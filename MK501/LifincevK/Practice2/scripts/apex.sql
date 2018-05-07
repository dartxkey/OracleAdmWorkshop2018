SET VERIFY OFF
connect "SYS"/"&&sysPassword" as SYSDBA
set echo on
spool /home/oracle/app/oracle/admin/Lifintsev/scripts/apex.log append
@/home/oracle/app/oracle/product/11.2.0/dbhome_1/apex/catapx.sql change_on_install KIRI KIRI TEMP /i/ NONE;
spool off
