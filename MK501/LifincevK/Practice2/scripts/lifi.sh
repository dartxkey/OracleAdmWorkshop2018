#!/bin/sh

OLD_UMASK=`umask`
umask 0027
mkdir -p /home/oracle/app/oracle/admin/Lifintsev/adump
mkdir -p /home/oracle/app/oracle/admin/Lifintsev/dpdump
mkdir -p /home/oracle/app/oracle/admin/Lifintsev/pfile
mkdir -p /home/oracle/app/oracle/cfgtoollogs/dbca/Lifintsev
mkdir -p /home/oracle/app/oracle/flash_recovery_area
mkdir -p /home/oracle/app/oracle/flash_recovery_area/Lifintsev
mkdir -p /home/oracle/app/oracle/oradata/Lifintsev
mkdir -p /home/oracle/app/oracle/product/11.2.0/dbhome_1/dbs
umask ${OLD_UMASK}
ORACLE_SID=lifi; export ORACLE_SID
PATH=$ORACLE_HOME/bin:$PATH; export PATH
echo You should Add this entry in the /etc/oratab: lifi:/home/oracle/app/oracle/product/11.2.0/dbhome_1:Y
/home/oracle/app/oracle/product/11.2.0/dbhome_1/bin/sqlplus /nolog @/home/oracle/app/oracle/admin/Lifintsev/scripts/lifi.sql
