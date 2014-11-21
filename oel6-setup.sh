#!/bin/bash
# Oracle Linux 6 Vagrant Primer

# CPR : Jd Daniel :: Ehime-ken
# MOD : 2014-11-21 @ 11:44:00
# REF : 
# INP : ./oel6-setup.sh

# eval $(which bash) oel6-setup.sh

## Enable dynamic IP allocation
echo "==> Enabling VM networking"
sed -i -e 's/ONBOOT=no/ONBOOT=yes/' /etc/sysconfig/networ-scripts/ifcfg-eth0
/etc/init.d/network restart

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
  chkonfig "${services[$service]}" off
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
    eval $(which bash) /media/cdrom/VBoxLinuxAdditions.run --nox11
  else
    echo 'Something borked?\nPlease try: $ mount -t iso9660 /dev/cdrom /media/cdrom\nafter inserting guest additions cd....'
    exit 1
  fi

set +e

## Pop repo
echo "==> Oikology..."
rm -fr /etc/yum.repos.d/pubic-yum-olo6.repo
yum clean all
yum -y update


## Installing Expect
yum install -y expect

## Create generic(s) for Vagrant
echo "==> Creating Vagrant user"
groupadd admin
useradd -G admin vagrant
/usr/bin/expect -cd 'expect { 
  eval spawn passwd vagrant 
  set prompt ":|#|\\\$"                       ## use correct prompt
  interact -o -nobuffer -re $prompt return    ## must be done twice due to week passwd
  send "vagrant\r"
  interact -o -nobuffer -re $prompt return
  send "vagrant\r"
  interact
}'


echo "Changing Vagrant users permissions"

cp /etc/sudoers /etc/sudoers.shtf ## Failsafe
echo -e '%admin      ALL=(ALL)     NOPASSWD: ALL\nDefaults    env_keep = .. SSH_AUTH_SOCK PATH' >> /etc/sudoers
sed -i -e 's/Defaults(.*)requiretty/# Defaults\1requiretty/g' \
       -e 's/Defaults(.*)!visible/# Defaults\1!visible/g' /etc/sudoers

echo "==> Provisions successful, rebooting in..."
  
  for i in {5..1}; do echo -n "$i. " && sleep 1; done

shutdown -rq now

