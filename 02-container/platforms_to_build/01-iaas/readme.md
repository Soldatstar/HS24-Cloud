# Installing Proxmox on Switch Engines

The aim is to install a simple proxmox cluster on Switch Engines. 

Proxmox is Debian based whereas it is feasible to use Debian 12 as starting point.

Evaluation takes place on points to be reached. All necessary components for the grading are denoted by a `MUST`. This is necessary as the evaluation takes place with scripts and automatisms.

The grade is based on the points using the following formular:

Grade = 1 + (Points Reached) * 5 / (Max Points)
Total Points reachable: 30

* All nodes MUST have a local user `eval` with the ssh-key stored in https://gitlab.fhnw.ch/cloud/cloud/platforms_to_build/-/blob/main/access/id_ed25519.pub . This user MUST have passwordless sudo-rights.
* For the debian/archlinux image, there MUST be users with user/pass: `user`/`pass`.

## Task 1, Single Setup

* Setup 3 virtual machines with the following specifications: 2 CPU, 4GB RAM, 50GB SSD. The names of these "cattle" MUST be: node01, node02, node03.
* Follow the instructions under https://pve.proxmox.com/wiki/Install_Proxmox_VE_on_Debian_12_Bookworm . Bear in mind that this tutorial is not strictly fire-and-forget: you might need to stumble over several problems. Note them down for your record and solve them with all tools necessary (Google, ChatGPT, whatever...).
* You need to set a root-password to access the Proxmox-Gui at the end. If you damage the network, you need the root-login for "local" access over the console as well. Set the password the sooner the better.

### Networking

Since our hosts receive their IP from DHCP, we operate the cluster in a ... let's call it operating mode which is not really mainstream: DHCP is normally not supported within Proxmox. As a consequence, we have to adapt the network when our machines are installed:

* Adapt the file `/etc/hosts` on each node in the following way:
  * replace the part with the `127.0.0.1	name.novaloca	name` with the local 10er-Ip (visible in the switch engine overview and only the nodename)
  * add all other nodes to the `/etc/host` as well
  The following example is given.

```
#to be removed
#127.0.0.1	node01.novalocal	node01

#to be inserted
10.0.0.21	node01
10.0.2.42	node02
10.0.1.53	node03
```

* Insert a bridge interface mit MASQUERATING (called NAT) to `/etc/network/interfaces` of all hosts

```
source /etc/network/interfaces.d/*

iface vmbr0 inet static
        address  10.10.10.1/24
        bridge-ports none
        bridge-stp off
        bridge-fd 0

        post-up   echo 1 > /proc/sys/net/ipv4/ip_forward
        post-up   iptables -t nat -A POSTROUTING -s '10.10.10.0/24' -o ens3 -j MASQUERADE
        post-down iptables -t nat -D POSTROUTING -s '10.10.10.0/24' -o ens3 -j MASQUERADE
```

The IP-range (`10.10.10.1/24`) should be different on each host. 

### Tips

* Switch Engines works with Cloud Init, adapting the `/etc/hosts`-file within each reboot. Shut off the override. You find information under https://forum.proxmox.com/threads/cloud-init-and-hosts-files.67372/ .
* Proxmox works entirely with the help of the Linux stack including host-based configuration files for network, etc. Any action in Proxmox leads to an adaption of the linux files.
* For example: Network adaption from within proxmox (including the installation) results always in an adaption of the `/etc/network/interface`-file: Proxmox is made to work with normally static IPs, however we have DHCP on Switch. Luckily, the changes are applied not directly but in a file called `/etc/network/interface.new`. This file becomes productive upon reboot. Reflect this path and the file with its content over there. Be sure that not an invalid configuration cancels your network upon reboot.
* Do not forget to adapt security groups for enabling access to proxmox from the outside.
* If you have problems with packages like `ifupdown2`, restarting services or reboots might help you out. Be aware that with an invalid network configuration, you might lock your yourself out and the only way to recover is via root-user and web-console on the switch engines. Be sure to have it set.
* If you damage your network, you need to login via Engines Project -> Compute -> Instances -> INSTANCE -> Console with `root` and your Password. Then you need to fix it (and the web console is not really user friendly).

### Points:

* Nodes MUST be up and Proxmox MUST be running. The nodes can run independently: 3p (one per node)
* All nodes MUST have correct name resolution between each other. The nodes can ping each other by their short hostname : 3p (one per node)
* All nodes MUST have local networks. A VM can be started on a node with a local ip adress: 3p (one per node)

## Task 2, Create a cluster

Based on the three nodes, we want to build a cluster. 
Refer to https://pve.proxmox.com/pve-docs/chapter-pvecm.html#pvecm_cluster_create_via_cli to create a cluster and join the nodes.
The name of your cluster MUST be match the following naming in switch: `cloud-hs24-YOUR_GROUP_NUMBER` (e.g. `cloud-hs24-16`).

### Tips

Because of wrong access rights of the web application and resulting errors, please refer to CLI-based setup.
Web-based might look like it is more convinient, but trust me: CLI is easier.

### Points:

* Cluster MUST be existing and green (functional): 3p per Green Node, 9p max.

## Task 3, Start a VM

Now that we have our cluster, it is time to start machines.

### Subtask 1: ISO-based installation

You can install a linux from installation media. Refer to a full netinstall debian-iso for easy install: https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/

* Upload the iso into Proxmox. Note that you need to upload to this iso to that machine, where you want to install your VM.
* Create a VM with the following specifications: 1 CPU, 4GB Disk (qcow2-format), 512m RAM-2048m Ram (Balooning), add the ISO as installation media
* Follow the installation without network, partitioning the entire disk and a User/Password: user/pass


### Subtask 2: qcow2-format

You can also install a linux from an existing image. Refer to https://wiki.archlinux.org/title/Arch_Linux_on_a_VPS#Official_Arch_Linux_cloud_image -> Proxmox for reference.
The image can be download via https://geo.mirror.pkgbuild.com/images/ -> newest timestamp -> Arch-Linux-x86_64-cloudimg.qcow2 

* Create a new machine manually without disk as described with the following specifications: 1 CPU, 4GB Disk (qcow2-format), 512m RAM-2048m Ram (Balooning),
* Copy the qcow2-image to the node where you want to instantiate the machine. You need to do this via CLI on the node.
* Import the disk as described and do not forget to create a cloud init-device for accessing.

### Tips:

* You do not need network: skip it at this time.
* Unmount disks / iso as it may hamper you when doing migration.
* Name the images suitable to the instance

### Points:

* Iso-based installation / Debian MUST be running and log in MUST be possible: 5P
* Image-based installation / Archlinux MUST be running and log in MUST be possible: 5P


## Task 4, Migrate 

Now that our cluster is running, we want to migrate / HA-enable the images:

* Clone one of your both running instances on the machine.
* Migrate the clone to the new machine and be sure it runs.

### Points:

* Cloned machine MUST be able to run on every node: 2p (one per new node)

# Write a summary

This repository MUST be cloned on the machine `node01` under the path `/home/debian/platforms_to_build`.
The following URL contains a token to clone this repository:
```
git clone https://clone-token:glpat-Hw4JUcuCPssqM-BZ_88U@gitlab.fhnw.ch/cloud/cloud/platforms_to_build.git
```
. 

A report in `/home/debian/platforms_to_build/01-iaas/own_report.md` MUST be written according to the given structure.


# Debug commands

Cluster status
`systemctl status -l pve-cluster`

Webserver status
`systemctl status pveproxy.service`

Logs:
`journalctl -u corosync -u pve-cluster -b`

Resetting Cluster on node
```
systemctl stop pve-cluster corosync
pmxcfs -l
rm -r /etc/corosync/*
rm /etc/pve/corosync.conf
killall pmxcfs
systemctl start pve-cluster
```
