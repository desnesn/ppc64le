#!/bin/bash

VMS=40

USER="ubuntu"
PASS="passw0rd"

#############
# VMS SETUP #
#############

echo -n "Stopping ubuntu-vm0 ... "
virsh dumpxml ubuntu-vm0 > /root/vms/ubuntu-vm0.xml
virsh destroy ubuntu-vm0 &> /dev/null
sleep 1m
echo "done"
echo

# Start loop with Master VM id which is 0
for i in $(seq 0 $((VMS-1)));
do
	echo -n "Installing ubuntu-vm$((i+1)) ... "

	cp -f /root/disks/ubuntu-vm$i.qcow2 /root/disks/ubuntu-vm$((i+1)).qcow2
	cp -f /root/vms/ubuntu-vm0.xml /tmp/ubuntu-vm$((i+1)).xml

	sed -i "s/ubuntu-vm0/ubuntu-vm$((i+1))/g" /tmp/ubuntu-vm$((i+1)).xml
	sed -i "s/>8</>2</g" /tmp/ubuntu-vm$((i+1)).xml
	# sed -i "s/sockets='1'/sockets='1'/g" /tmp/ubuntu-vm$((i+1)).xml
	sed -i "s/cores='2'/cores='1'/g" /tmp/ubuntu-vm$((i+1)).xml
	sed -i "s/threads='4'/threads='2'/g" /tmp/ubuntu-vm$((i+1)).xml
	sed -i '/uuid/d' /tmp/ubuntu-vm$((i+1)).xml
	sed -i 's/33554432/10485760/g' /tmp/ubuntu-vm$((i+1)).xml
	sed -i '/mac address/d' /tmp/ubuntu-vm$((i+1)).xml

	virsh define /tmp/ubuntu-vm$((i+1)).xml &> /dev/null

	rm -f /tmp/ubuntu-vm$((i+1)).xml

	echo "done"
done
echo


###########
# NETWORK #
###########

IP=100

# virsh net-update default add ip-dhcp-host "<host mac='52:54:00:4a:d3:21' name='ubuntu-vm0' ip='192.168.122.100'/>" --live --config &> /dev/null
# virsh net-dumpxml default

cat /dev/null > /var/lib/libvirt/dnsmasq/virbr0.status
virsh net-destroy default &> /dev/null
virsh net-start default &> /dev/null

echo
for i in $(seq 0 $VMS);
do
	MAC=$(virsh dumpxml ubuntu-vm$i | grep 'mac address' | awk -F\' '{ print $2 }')

	echo -n "Setting virsh IP 192.168.122.$IP on ubuntu-vm$i with $MAC .. "

#	virsh net-update default add ip-dhcp-host "<host mac='$MAC' name='ubuntu-vm$i' ip='192.168.122.$IP'/>" --live --config &
	virsh net-update default add ip-dhcp-host "<host mac='$MAC' name='ubuntu-vm$i' ip='192.168.122.$IP'/>" --live --config &> /dev/null
	sleep 5

	# VM_IP=$(virsh net-dhcp-leases default | grep ubuntu-vm$i | awk '{ print $5 }' | awk -F'/' '{ print $1 }')
	echo "192.168.122.$IP ubuntu-vm$i" >> /etc/hosts

	echo "done"
	IP=$((IP+1))
done

#############
# START VMS #
#############

echo
for i in $(seq 0 $VMS);
do
	echo -n "Starting ubuntu-vm$i ... "
	virsh start ubuntu-vm$i &> /dev/null
	echo "done"
done
echo

# Sleep for 20 minutes
echo -n "Sleeping for 20 minutes to allow all $VMS KVMs to start ... "
sleep 20m
echo "done"
echo

####################
# CHANGE HOSTNAMES #
####################

for i in $(seq 1 $VMS);
do
	echo -n "Changing hostname of ubuntu-vm$i ... "

#	sshpass -p "$PASS" ssh -o StrictHostKeyChecking=no $USER@ubuntu-vm$i \
#	                        "sudo hostnamectl set-hostname ubuntu-vm$i" &
	sshpass -p "$PASS" ssh -o StrictHostKeyChecking=no $USER@ubuntu-vm$i \
	                        "sudo hostnamectl set-hostname ubuntu-vm$i" &> /dev/null
	sleep 5

	echo "done"
done
echo

#######################
# UPDATING HOSTS FILE #
#######################

for i in $(seq 0 $VMS);
do
	echo -n "Updating /etc/hosts of ubuntu-vm$i ... "

#	sshpass -p "$PASS" ssh -o StrictHostKeyChecking=no $USER@ubuntu-vm$i \
#		"sudo sed -i 's/127.0.1.1 ubuntu-vm0/127.0.1.1 ubuntu-vm$i/g' /etc/hosts" &
	sshpass -p "$PASS" ssh -o StrictHostKeyChecking=no $USER@ubuntu-vm$i \
		"sudo sed -i 's/127.0.1.1 ubuntu-vm0/127.0.1.1 ubuntu-vm$i/g' /etc/hosts" &> /dev/null
	sleep 5

	grep -i ubuntu /etc/hosts |
	while read line; do
		if [[ ! $line =~ "ubuntu-vm$i" ]];then
#			sshpass -p "$PASS" ssh -o StrictHostKeyChecking=no $USER@ubuntu-vm$i \
#				"sudo sed -i -e '\$a$line' /etc/hosts" &
			sshpass -p "$PASS" ssh -o StrictHostKeyChecking=no $USER@ubuntu-vm$i \
				"sudo sed -i -e '\$a$line' /etc/hosts" &> /dev/null
			sleep 5
		fi
	done

	echo "done"
done
echo

####################

exit 0
