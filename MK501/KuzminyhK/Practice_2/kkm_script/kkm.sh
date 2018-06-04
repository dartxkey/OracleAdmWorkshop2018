#!/bin/sh

OLD_UMASK=`umask`
umask 0027
mkdir -p /home/oracle/app/oracle/admin/kkm/adump
mkdir -p /home/oracle/app/oracle/admin/kkm/dpdump
mkdir -p /home/oracle/app/oracle/admin/kkm/pfile
mkdir -p /home/oracle/app/oracle/cfgtoollogs/dbca/kkm
mkdir -p /home/oracle/app/oracle/oradata/kkm
mkdir -p /home/oracle/app/oracle/product/11.2.0/dbhome_1/dbs
umask ${OLD_UMASK}
ORACLE_SID=kkm; export ORACLE_SID
PATH=$ORACLE_HOME/bin:$PATH; export PATH
echo You should Add this entry in the /etc/oratab: kkm:/home/oracle/app/oracle/product/11.2.0/dbhome_1:Y
/home/oracle/app/oracle/product/11.2.0/dbhome_1/bin/sqlplus /nolog @/home/oracle/kkm_script/kkm.sql
