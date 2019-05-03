################################################################################################################################################
# Script Name: zabbix_xenial_bionic.sh
# Author: Eranachandran
# Date : 30-04-2019
# Description: The following script will install zabbix server
# In machine already mysql installed, usage: sudo bash zabbix_xenial_bionic.sh --host_password --mysql_db_user_name --mysql_db_password  --zabbix_database_new_password 
# In machine already mariadb installed, usage: sudo bash zabbix_xenial_bionic.sh --host_password --mariadb_db_user_name --maria_db_password  --zabbix_database_new_password 
# In machine already mariadb or not mysql installed usage:sudo bash zabbix_xenial_bionic.sh --host_password --database_new_root_password  --zabbix_database_new_password 
################################################################################################################################################
#! /bin/bash

ARGS=$(getopt -o a:b:c:d:e:f:g -l "host_password:,mysql_db_user_name:,mysql_db_password:,mariadb_db_user_name:,maria_db_password:,database_new_root_password:,zabbix_database_new_password:" -- "$@");

eval set -- "$ARGS";

while true; do
  case "$1" in
    -a|--host_password)
      shift;
      if [ -n "$1" ]; then
        host_password=$1;
        shift;
      fi
      ;;
    -b|--mysql_db_user_name)
      shift;
      if [ -n "$1" ]; then
        mysql_db_user_name=$1;
        shift;
      fi
      ;;
   -c|--mysql_db_password)
      shift;
      if [ -n "$1" ]; then
        mysql_db_password=$1;
        shift;
      fi
      ;;
   -d|--mariadb_db_user_name)
      shift;
      if [ -n "$1" ]; then
        mariadb_db_user_name=$1;
        shift;
      fi
      ;;
   -e|--maria_db_password)
      shift;
      if [ -n "$1" ]; then
        maria_db_password=$1;
        shift;
      fi
      ;;
   -f|--database_new_root_password)
      shift;
      if [ -n "$1" ]; then
        database_new_root_password=$1;
        shift;
      fi
      ;;
   -g|--zabbix_database_new_password)
      shift;
      if [ -n "$1" ]; then
        zabbix_database_new_password=$1;
        shift;
      fi
      ;;
    --)
      shift;
      break;
      ;;
  esac
done



echo "$host_password" | sudo -S sudo apt -y update

# install the PHP modules Zabbix needs
echo "$host_password" | sudo -S apt -y install php7.0-xml php7.0-bcmath php7.0-mbstring

#checking ubuntu Version 16.04 or 18.04 and  Install Zabbix repository
if [ $(cat /etc/os-release  | awk 'NR==2 {print $3}'| grep -i -o xenial) ==  "Xenial" ]; then
  echo "$host_password" | sudo -S wget https://repo.zabbix.com/zabbix/4.2/ubuntu/pool/main/z/zabbix-release/zabbix-release_4.2-1+xenial_all.deb
  echo "$host_password" | sudo -S dpkg -i zabbix-release_4.2-1+xenial_all.deb
elif [ $(cat /etc/os-release  | awk 'NR==2 {print $3}'| grep -i -o bionic) ==  "Bionic" ]; then
  echo "$host_password" | sudo -S wget https://repo.zabbix.com/zabbix/4.2/ubuntu/pool/main/z/zabbix-release/zabbix-release_4.2-1+bionic_all.deb
  echo "$host_password" | sudo -S dpkg -i zabbix-release_4.2-1+bionic_all.deb
fi

#updating packages
echo "$host_password" | sudo -S sudo apt -y update

# Checking Mysql Installed or not, if installed zabbix database created in mysql
mysql=$(dpkg -l | grep "mysql-server")

if [ "$?" ==  0 ]; then
#Install Zabbix server, frontend agent
echo "$host_password" | sudo -S apt -y install zabbix-server-mysql zabbix-frontend-php zabbix-agent
echo "create database zabbix character set utf8 collate utf8_bin;" | mysql -h localhost -u $mysql_db_user_name -p$mysql_db_password

#granting Preivileges for zabbix database, Here '%' is given, so all remote host will access zabbix database with password. So don't grant like this. try to allow whitelisted hosts only
echo  "grant all privileges on zabbix.* to zabbix@'%' identified by '$zabbix_database_new_password';"  | mysql -h localhost -u $mysql_db_user_name -p$mysql_db_password
echo "flush privileges;" | mysql -h localhost -u $mysql_db_user_name -p$mysql_db_password

#here bind-address is 0.0.0.0, so all remote host will access database server with password. So don't grant like this. try to allow whitelisted hosts only 
echo "$host_password" | sudo -S sed -i  "s/^\(bind-address\s*=\).*/\1 0.0.0.0/" /etc/mysql/mysql.conf.d/mysqld.cnf
echo "$host_password" | sudo -S service mysql restart

#Run the following command to set up the schema and import the data into the zabbix database
echo "$host_password" | sudo -S zcat /usr/share/doc/zabbix-server-mysql*/create.sql.gz | mysql -uzabbix -p zabbix -p$zabbix_database_new_password
echo "$host_password" | sudo -S sed -i  "s/^\(\s*#\s*DBPassword=\).*/\DBPassword=/"  /etc/zabbix/zabbix_server.conf
echo "$host_password" | sudo -S sed -i  "s/^\(DBPassword\s*=\).*/\1 ${zabbix_database_new_password}/" /etc/zabbix/zabbix_server.conf

#Edit file /etc/zabbix/apache.conf, uncomment and set the right timezone for you.
echo "$host_password" | sudo -S  sed -i  "s/^\(\s*#\s*php_value date.timezone Europe\/Riga\).*/\\tphp_value date.timezone Asia\/Kolkata/" /etc/zabbix/apache.conf
fi

# Checking MariaDB Installed or not, if installed zabbix database created in mariadb
mariadb=$(dpkg -l | grep mariadb-server)
if [ "$?" ==  0 ]; then
#Install Zabbix server, frontend agent
echo "$host_password" | sudo -S apt -y install zabbix-server-mysql zabbix-frontend-php zabbix-agent
echo "create database zabbix character set utf8 collate utf8_bin;" | mysql -h localhost -u $mariadb_db_user_name -p$maria_db_password

#granting Preivileges for zabbix database, Here '%' is given, so all remote host will access zabbix database with password. So don't grant like this. try to allow whitelisted hosts only
echo  "grant all privileges on zabbix.* to zabbix@'%' identified by '$zabbix_database_new_password';"  | mysql -h localhost -u $mariadb_db_user_name -p$maria_db_password
echo "flush privileges;" | mysql -h localhost -u $mariadb_db_user_name -p$maria_db_password

#here bind-address is 0.0.0.0, so all remote host will access database server with password. So don't grant like this. try to allow whitelisted hosts only 
echo "$host_password" | sudo -S sed -i  "s/^\(bind-address\s*=\).*/\1 0.0.0.0/" /etc/mysql/mariadb.conf.d/50-server.cnf
echo "$host_password" | sudo -S service mysql restart

#Run the following command to set up the schema and import the data into the zabbix database
echo "$host_password" | sudo -S zcat /usr/share/doc/zabbix-server-mysql*/create.sql.gz | mysql -uzabbix -p zabbix -p$zabbix_database_new_password
echo "$host_password" | sudo -S sed -i  "s/^\(\s*#\s*DBPassword=\).*/\DBPassword=/"  /etc/zabbix/zabbix_server.conf
echo "$host_password" | sudo -S sed -i  "s/^\(DBPassword\s*=\).*/\1 ${zabbix_database_new_password}/" /etc/zabbix/zabbix_server.conf

#Edit file /etc/zabbix/apache.conf, uncomment and set the right timezone for you.
echo "$host_password" | sudo -S  sed -i  "s/^\(\s*#\s*php_value date.timezone Europe\/Riga\).*/\\tphp_value date.timezone Asia\/Kolkata/" /etc/zabbix/apache.conf
fi

#if mysql or mariadb not installed mariadb will be installed and zabbix database created in mariadb 
db_install_check=$(dpkg -l | grep mariadb-server || dpkg -l | grep mysql-server)

if [ "$?" !=  0 ]; then
#Install Zabbix server, frontend agent
echo "$host_password" | sudo -S debconf-set-selections <<< 'mysql-server mysql-server/root_password password $database_new_root_password'
echo "$host_password" | sudo -S debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password  $database_new_root_password'
echo "$host_password" | sudo -S apt -y install zabbix-server-mysql zabbix-frontend-php zabbix-agent
echo "create database zabbix character set utf8 collate utf8_bin;" | mysql -h localhost -u root -p$database_new_root_password

#granting Preivileges for zabbix database, Here '%' is given, so all remote host will access zabbix database with password. So don't grant like this. try to allow whitelisted hosts only 
echo  "grant all privileges on zabbix.* to zabbix@'%' identified by '$zabbix_database_new_password';"  | mysql -h localhost -u root -p$database_new_root_password
echo "flush privileges;" | mysql -h localhost -u root -p$database_new_root_password

#here bind-address is 0.0.0.0, so all remote host will access database server with password. So don't grant like this. try to allow whitelisted hosts only 
echo "$host_password" | sudo -S sed -i  "s/^\(bind-address\s*=\).*/\1 0.0.0.0/"  /etc/mysql/mariadb.conf.d/50-server.cnf
echo "$host_password" | sudo -S service mysql restart

#Run the following command to set up the schema and import the data into the zabbix database
echo "$host_password" | sudo -S zcat /usr/share/doc/zabbix-server-mysql*/create.sql.gz | mysql -uzabbix -p zabbix -p$zabbix_database_new_password
echo "$host_password" | sudo -S sed -i  "s/^\(\s*#\s*DBPassword=\).*/\DBPassword=/"  /etc/zabbix/zabbix_server.conf
echo "$host_password" | sudo -S sed -i  "s/^\(DBPassword\s*=\).*/\1 ${zabbix_database_new_password}/" /etc/zabbix/zabbix_server.conf

#Edit file /etc/zabbix/apache.conf, uncomment and set the right timezone for you.
echo "$host_password" | sudo -S echo "$host_password" | sudo -S  sed -i  "s/^\(\s*#\s*php_value date.timezone Europe\/Riga\).*/\\tphp_value date.timezone Asia\/Kolkata/" /etc/zabbix/apache.conf
fi

#Zabbix server and agent processes
echo "$host_password" | sudo -S systemctl restart zabbix-server zabbix-agent apache2
echo "$host_password" | sudo -S systemctl enable zabbix-server zabbix-agent apache2

#Check zabbix status
zabbix_status=$(echo "$host_password" | sudo -S systemctl status zabbix-server |  awk 'NR==3')
echo "$zabbix_status"
