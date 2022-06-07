#!/bin/bash

VMS=40
USER="ubuntu"
PASS="passw0rd"

for i in $(seq 1 $VMS);
do
	echo "=> ubuntu-vm$i"

#	sshpass -p "$PASS" ssh -o StrictHostKeyChecking=no $USER@ubuntu-vm$i \
#		"touch /tmp/test_file" &
	sshpass -p "$PASS" ssh -o StrictHostKeyChecking=no $USER@ubuntu-vm$i \
		"touch /tmp/test_file"
	sleep 5

	echo "done"
	echo
done

exit 0
