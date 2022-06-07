# 40 VMs example

Scripts that set up and use a manual 40 KVMs ppc64le environment described hereafter:

~~~
=======
= VM0 =
=======
8   CPUs
32  GiB
200 GB
=======

==============
= VM1 - VM40 =
==============
40 KVMs

2 cpu     = 80 CPUs
10 G ram  = 400 GiB
30G       = 1200 G
==============
~~~

The host has been installed with RHEL-8.6.
The 40 VMS are installed with Ubuntu 20.04.4 LTS and will have fixed IPs on the virbr0 bridge.
VM0 is the master VM.

## HOST SETUP
~~~
yum -y update

yum -y install sshpass

yum -y install @virt
yum -y install virt-top libguestfs-tools
yum -y install virt-install virt-viewer

cp -f /etc/libvirt/qemu.conf /etc/libvirt/qemu.conf.orig
sed -i 's/#user = \"root\"/user = \"root\"/' /etc/libvirt/qemu.conf
sed -i 's/#group = \"root\"/group = \"root\"/' /etc/libvirt/qemu.conf

systemctl enable --now libvirtd
~~~

## VM0 SETUP

First, VM0 was installed manually with virt-install:

~~~
mkdir -p /root/isos && cd /root/isos
wget https://cdimage.ubuntu.com/releases/20.04.4/release/ubuntu-20.04.4-live-server-ppc64el.iso

mkdir -p /root/disks
qemu-img create -f qcow2 /root/disks/ubuntu-vm0.qcow2 200G

cat /dev/null > /var/lib/libvirt/dnsmasq/virbr0.status

virt-install \
	--name=ubuntu-vm0 \
	--memory=32768 \
	--vcpus=8,sockets=1,cores=2,threads=4 \
	--graphics none \
	--network bridge=virbr0,model=virtio \
	--disk path=/root/disks/ubuntu-vm0.qcow2,format=qcow2,bus=virtio \
	--controller type=scsi,model=virtio-scsi \
	--cdrom=/root/isos/ubuntu-20.04.4-live-server-ppc64el.iso \
	--os-type=linux --os-variant=ubuntu20.04 \
	--qemu-commandline="-machine cap-cfpc=broken,cap-sbbc=workaround,cap-ibs=workaround,cap-ccf-assist=off"
~~~

Afertwards, ssh to ubuntu-vm0 and enable sudo to the ubuntu user. This is also a good time to copy your id_rsa public key into the VM:
~~~
VM0_IP=$(virsh net-dhcp-leases default | grep ubuntu-vm0 | awk '{ print $5 }' | awk -F'/' '{ print $1 }')

# Create a key pair if you don't have one:
# ssh-keygen -t rsa -b 4096

ssh-copy-id -i ~/.ssh/id_rsa.pub ubuntu@$VM0_IP

ssh ubuntu@$VM0_IP
sudo echo "$USER ALL=(ALL:ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/$USER
~~~

## VM1 - VM40 SETUP
Edit the script variables in the begining and run the **./vms_setup.sh** script.

This script clones the manuall installed vm0 configuration to create and customize the installation of VM1-VM40.

Afterwards, the MACs of each VM is fixed on the DHCP of the virsh network and the IPs and hostnames are copied into the host /etc/hosts file.

Latter on, each VM will have their /etc/hosts file changed as well.

Thus, each VM will be easily accessible and indexed to each other.
