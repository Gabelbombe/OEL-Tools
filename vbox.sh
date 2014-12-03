#!/bin/bash
# Virtualbox Provisioner

# CPR : Jd Daniel :: Ehime-ken
# MOD : 2014-11-21 @ 11:44:00
# REF : http://www.perkin.org.uk/posts/create-virtualbox-vm-from-the-command-line.html
# INP : 08:00:27:63:5C:4F

declare -A boxDesc
declare -A boxIds

inc=0
opt=0
VBoxManage list ostypes |grep -E '(^ID|Description)' |awk '{$1="";print}' |while read line; do
	[ $((inc%2)) -eq 0 ] && {
		boxDesc+=("$line")
		echo "${opt}: $line"
		((opt++))
	} || {
		boxIds+=("$line")
	}

	((inc++))
done

echo ${boxDesc[4]}



vagrantFile="${vboxName}-devel"

vagrant package --base "${vboxName}"
mv 'package.box' "${vagrant.box}"

vagrant box add "${vagrantFile}" "${vagrantFile}.box"
mkdir -p "/tmp/${vagrantFile}" && cd $_

## Test
vagrant init "${vagrantFile}"
vagrant up
vagrant ssh


## Must add Vagrant to IdentityFile
ssh-add ~/.vagrant.d/insecure_private_key
vagrant ssh "$boxname" -- -A