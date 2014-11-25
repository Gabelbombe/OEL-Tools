#!/bin/bash
# Oracle Linux 6 Vagrant Primer

# CPR : Jd Daniel :: Ehime-ken
# MOD : 2014-11-21 @ 11:44:00
# REF : //pyfunc.blogspot.com/2011/11/creating-base-box-from-scratch-for.html
# INP : wget http://goo.gl/DGs3Fv |bash


################
# Fix hostname #
################

#################
# Root Password #
#   g0tsh0t3    #
#################

# Basic Server


## Will most likely need to be done initially 
## from the box as there is NO CONNECTION

## Enable dynamic IP allocation
echo "==> Enabling VM networking"
sed -i -e 's/ONBOOT=no/ONBOOT=yes/' /etc/sysconfig/network-scripts/ifcfg-eth0
/etc/init.d/network restart

## ##
## ##

## Shut off useless services
declare -A services

services=(
  ['Discover Daemon']='avahi-daemon'
  ['Firewall Daemon']='iptables'
  ['Printer Daemon']='cups'
  ['Network Manager']='NetworkManager'
  ['IPv6 packet filtering']='ip6tables'
)

## If firewall chains exist... 
if ! hash ipchains 2>/dev/null; then
  services['Chains Daemon']='ipchains'
  service ipchains stop
fi

service iptables stop

for service in "${!services[@]}"; do
  echo "==> Disableing: $service"
  chkconfig "${services[$service]}" off
done

## Prime resolv.conf
echo "==> Priming resolve.conf"
echo -e "search unix.gsm1900.org gsm1900.org voicestream.com\nnameserver 10.130.32.52\nnameserver 10.14.6.85\nretry:1\nretrans:1" \
> /etc/resolv.conf

## Guest Editions VM ISO
echo "==> Attempting to add Virtualbox Guest Additions"
eject -T

read -p "Please mount 'VBoxGuestAddtions.iso', then press [Enter]" -n1 -s
mkdir -p /media/cdrom
mount -t iso9660 /dev/cdrom /media/cdrom


set -e

  if [ -f "/media/cdrom/VBoxLinuxAdditions.run" ]; then
    echo "==> Mounting Successful!"
    yum install -y kernel-uek-devel kernel-uek-headers kernel-uek-devel-$(uname -r) ## Kernel Headers needed by guest additions
    bash /media/cdrom/VBoxLinuxAdditions.run --nox11
  else
    echo 'Something borked?\nPlease try: $ mount -t iso9660 /dev/cdrom /media/cdrom\nafter inserting guest additions cd....'
    exit 1
  fi

set +e


## Installing Expect
yum install -y expect


## Create generic(s) for Vagrant
echo "==> Creating Vagrant user"
groupadd admin
useradd -G admin vagrant

PASSWD=$(expect -c '
  log_user 0
  proc abort {} {
    puts "User Vagrant has had password set..."
    exit 0
  }
  spawn passwd vagrant
  expect {
    password:        { send "vagrant\r"; exp_continue }
    default          end
    eof
  }
')


echo "==> $PASSWD" ## Outputs Expect
echo "==> Changing Vagrant users permissions"
cp /etc/sudoers /etc/sudoers.shtf ## Failsafe
echo -e '##Vagrant User\n%admin      ALL=(ALL)\tNOPASSWD: ALL\n\Defaults   env_keep += "SSH_AUTH_SOCK"' >> /etc/sudoers
sed -i -e 's/Defaults(.*)requiretty/# Defaults\1requiretty/g' \
       -e 's/Defaults(.*)!visible/# Defaults\1!visible/g' /etc/sudoers


echo '==> Changing Vagrant $PATH envvars'
su vagrant <<EOF
  echo 'export PATH="$PATH:/usr/sbin:/sbin"' >> ~/.bashrc
EOF

## RVM Requirements
echo '==> Installing RVM requirements'
yum install -y gcc-c++ patch readline zlib make bzip2 autoconf automake libtool bison \
               {readline,zlib,libyaml,libffi,openssl,iconv}-devel

echo '==> Installing RVM'
su vagrant <<EOF
  cd /tmp 
  echo 'source ~/.profile' >> ~/.bash_profile && touch ~/.profile
  command curl -sSL https://rvm.io/mpapis.asc |gpg2 --import -
  curl -sSL https://get.rvm.io |bash
EOF


## Puppet and SSH installation
echo '==> Installing SSH and Puppet'
yum install -y puppet openssh-{server,client}


## Add vagrant insecure public key 
## Readme : https://github.com/mitchellh/vagrant/tree/master/keys
## Master : //goo.gl/qhnKTR
## Public : //goo.gl/YVqtWw
echo '==> Adding SSH key for Puppet'
su vagrant <<EOF
  cd /tmp 
  mkdir -p .ssh && sudo chmod 0755 ~/.ssh 
  wget --no-check-certificate -O vagrant.pub http://goo.gl/x390M8
  cat vagrant.pub >> ~/.ssh/authorized_keys 
  sudo chmod 0644 ~/.ssh/authorized_keys
EOF


## Install YUM and EPEL repositories
su vagrant <<EOF
  cd /etc/yum.repos.d
  wget http://public-yum.oracle.com/public-yum-el5.repo
  sed -i -e 's/enabled=0/enabled=1/' public-yum-el5.repo
  sudo rpm -Uvh http://download.fedoraproject.org/pub/epel/5/x86_64/epel-release-5-4.noarch.rpm
  sudo yum -y update
EOF


## MAC Address prompt
## 08:00:27:1E:18:B2
read -p "Boxes MAC Address is: '$(ifconfig |grep eth0 |awk '{print$5}')' please write this down, then press [Enter]" -n1 -s


echo "==> Running cleanup"
yum clean -y headers packages dbcache expire-cache


echo "==> Provisions successful, rebooting box in..."
  
  for i in {5..1}; do echo -n "$i. " && sleep 1; done

shutdown -rq now

