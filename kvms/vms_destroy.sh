#!/bin/bash

VMS=40

###############
# DESTROY VMS #
###############

echo
# Don't detroy Master VM id which is 0
for i in $(seq 1 $VMS);
do
	echo -n "Destroying ubuntu-vm$i ... "
	virsh destroy ubuntu-vm$i &> /dev/null
	echo "done"
done

################
# UNDEFINE VMS #
################

echo
# Don't undefine Master VM id which is 0
for i in $(seq 1 $VMS);
do
	echo -n "Undefining ubuntu-vm$i ... "
	virsh undefine ubuntu-vm$i &> /dev/null
	echo "done"
done

##############
# HOSTS FILE #
##############

echo
echo -n "Clearing /etc/hosts ... "
sed -i '/vm/d' /etc/hosts
sed -i '/KVMs/d' /etc/hosts
echo "done"

#################
# VIRSH NETWORK #
################

echo
# cat /dev/null > /var/lib/libvirt/dnsmasq/virbr0.status
for i in $(seq 0 $VMS);
do
	MAC=$(virsh net-dumpxml default | grep ubuntu-vm$i | awk -F\' '{ print $2 }')
	IP=$(virsh net-dumpxml default | grep ubuntu-vm$i | awk -F\' '{ print $6 }')

	echo -n "Releasing virsh IP $IP of ubuntu-vm$i with $MAC... "
	virsh net-update default delete ip-dhcp-host "<host mac=\"$MAC\" ip=\"$IP\"/>" --live --config --parent-index 0 &> /dev/null
	echo "done"
done

echo
echo -n "Restarting virsh network ... "
cat /dev/null > /var/lib/libvirt/dnsmasq/virbr0.status
virsh net-destroy default &> /dev/null
virsh net-start default &> /dev/null
echo "done"

##############

echo
exit 0
