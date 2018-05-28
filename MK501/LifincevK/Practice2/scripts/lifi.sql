set verify off
ACCEPT sysPassword CHAR PROMPT 'Enter new password for SYS: ' HIDE
ACCEPT systemPassword CHAR PROMPT 'Enter new password for SYSTEM: ' HIDE
host /home/oracle/app/oracle/product/11.2.0/dbhome_1/bin/orapwd file=/home/oracle/app/oracle/product/11.2.0/dbhome_1/dbs/orapwlifi force=y
@/home/oracle/app/oracle/admin/Lifintsev/scripts/CreateDB.sql
@/home/oracle/app/oracle/admin/Lifintsev/scripts/CreateDBFiles.sql
@/home/oracle/app/oracle/admin/Lifintsev/scripts/CreateDBCatalog.sql
@/home/oracle/app/oracle/admin/Lifintsev/scripts/JServer.sql
@/home/oracle/app/oracle/admin/Lifintsev/scripts/context.sql
@/home/oracle/app/oracle/admin/Lifintsev/scripts/xdb_protocol.sql
@/home/oracle/app/oracle/admin/Lifintsev/scripts/ordinst.sql
@/home/oracle/app/oracle/admin/Lifintsev/scripts/interMedia.sql
@/home/oracle/app/oracle/admin/Lifintsev/scripts/cwmlite.sql
@/home/oracle/app/oracle/admin/Lifintsev/scripts/spatial.sql
@/home/oracle/app/oracle/admin/Lifintsev/scripts/emRepository.sql
@/home/oracle/app/oracle/admin/Lifintsev/scripts/apex.sql
@/home/oracle/app/oracle/admin/Lifintsev/scripts/owb.sql
@/home/oracle/app/oracle/admin/Lifintsev/scripts/lockAccount.sql
@/home/oracle/app/oracle/admin/Lifintsev/scripts/postDBCreation.sql
