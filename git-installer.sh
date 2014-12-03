#!/bin/bash
# EPEL (Extra Package Library) Installer for RHEL based systems

# CPR : Jd Daniel :: Ehime-ken
# MOD : 2014-11-20 @ 14:00:34
# INP : ./git-installer.sh

## ROOT check
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as su" 1>&2 ; exit 1
fi

## Enable dynamic IP allocation
sed -i -e 's/ONBOOT=no/ONBOOT=yes/' /etc/sysconfig/networ-scripts/ifcfg-eth0
/etc/init.d/network restart


cd /tmp
wget http://download.fedoraproject.org/pub/epel/5/x86_64/epel-release-5-4.noarch.rpm
rpm -Uvh ./epel-release-5-4.noarch.rpm
yum install git

