SET VERIFY OFF
connect "SYS"/"&&sysPassword" as SYSDBA
set echo on
spool /home/oracle/kkm_script/apex.log append
@/home/oracle/app/oracle/product/11.2.0/dbhome_1/apex/catapx.sql change_on_install SYSAUX SYSAUX TEMP /i/ NONE;
spool off
