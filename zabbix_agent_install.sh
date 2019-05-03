################################################################################################################################################
# Script Name: zabbix_agent_install.sh
# Author: Eranachandran
# Date : 30-04-2019
# Description: The following script will install zabbix agent
# usage: sudo bash zabbix_agent_install.sh --host_password  --zabbix_server_ip
################################################################################################################################################
#! /bin/bash

ARGS=$(getopt -o a:b -l "host_password:,zabbix_server_ip:" -- "$@");

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
    -b|--zabbix_server_ip)
      shift;
      if [ -n "$1" ]; then
        zabbix_server_ip=$1;
        shift;
      fi
      ;;
    --)
      shift;
      break;
      ;;
  esac
done


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

#install the Zabbix agent
echo "$host_password" | sudo -S apt-get -y install zabbix-agent

#adding zabbix server IP
echo "$host_password" | sudo -S sed -i  "s/^\(Server\s*=\).*/\1 ${zabbix_server_ip}/" /etc/zabbix/zabbix_agentd.conf


#starting Zabbix agent
echo "$host_password" | sudo -S systemctl start zabbix-agent
echo "$host_password" | sudo -S systemctl enable zabbix-agent

#check zabbix agent status
zabbix_agent_status=$(echo "$host_password" | sudo -S systemctl status zabbix-agent |  awk 'NR==3')
echo "$zabbix_agent_status"
