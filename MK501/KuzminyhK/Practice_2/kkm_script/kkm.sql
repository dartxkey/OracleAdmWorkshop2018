set verify off
ACCEPT sysPassword CHAR PROMPT 'Enter new password for SYS: ' HIDE
ACCEPT systemPassword CHAR PROMPT 'Enter new password for SYSTEM: ' HIDE
host /home/oracle/app/oracle/product/11.2.0/dbhome_1/bin/orapwd file=/home/oracle/app/oracle/product/11.2.0/dbhome_1/dbs/orapwkkm force=y
@/home/oracle/kkm_script/CreateDB.sql
@/home/oracle/kkm_script/CreateDBFiles.sql
@/home/oracle/kkm_script/CreateDBCatalog.sql
@/home/oracle/kkm_script/JServer.sql
@/home/oracle/kkm_script/context.sql
@/home/oracle/kkm_script/xdb_protocol.sql
@/home/oracle/kkm_script/ordinst.sql
@/home/oracle/kkm_script/interMedia.sql
@/home/oracle/kkm_script/cwmlite.sql
@/home/oracle/kkm_script/spatial.sql
@/home/oracle/kkm_script/emRepository.sql
@/home/oracle/kkm_script/apex.sql
@/home/oracle/kkm_script/owb.sql
@/home/oracle/kkm_script/lockAccount.sql
@/home/oracle/kkm_script/postDBCreation.sql
