# Building Ceph


## Building up the platform together

Install cepthadm on all nodes.

```bash
sudo apt update 
sudo apt install -y cephadm
```

Install docker on all nodes.

```bash
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

Running bootstrap command on monitor01.

```bash
sudo cephadm bootstrap --mon-ip <monitor01-private-ip>
```

Copy public key from monitor01 to osd[01-03].

```bash
cat /etc/ceph/ceph.pub
echo <ceph.pub> > /root/.ssh/authorized_keys
```

Adding osd[01-03] to the cluster on machine monitor01

```bash
sudo cephadm shell -- ceph orch host add <osd[01-03]> <osd[01-03]-private-ip>
```

Create new OSDs.

```bash
sudo cephadm shell -- ceph orch apply osd --all-available-devices
```

Create RBD block storage, client and image. 

```bash
sudo cephadm shell -- ceph osd pool create 01-rbd-cloudfhnw
sudo cephadm shell -- rbd pool init 01-rbd-cloudfhnw
sudo cephadm shell -- ceph auth get-or-create client.01-cloudfhnw-rbd mon 'profile rbd' osd 'profile rbd pool=01-rbd-cloudfhnw' mgr 'profile rbd pool=01-rbd-cloudfhnw'
sudo cephadm shell -- rbd create --size 2048 01-rbd-cloudfhnw/01-cloudfhnw-cloud-image
```

Create CephFS filesystem and client.

```bash
sudo cephadm shell -- ceph fs volume create cephfs-cloudfhnw
sudo cephadm shell -- ceph fs authorize cephfs-cloudfhnw client.02-cloudfhnw-cephfs / rw
```

## Technical challenges

### SSH Access to OSD Hosts  
* Step: Trying to execute the command `ssh-copy-id -f -i /etc/ceph/ceph.pub root@host2` on the monitor01 host  
* What: I had trouble accessing the OSD hosts via SSH because the `ssh-copy-id` command didn’t work.  
* Solved via: Manual key transfer – I retrieved the public key from `/etc/ceph/ceph.pub` and manually added it to the `/root/.ssh/authorized_keys` file on the OSD hosts to enable SSH access.

## Personal reflection

### Damjan

* Workload 1 (Block Storage): Use Ceph as a distributed block device for VMs or applications, providing scalable storage that can be attached to clients and formatted for use.

* Workload 2 (File Storage with CephFS): Use CephFS to provide a distributed file system for shared access by multiple clients. Clients can mount the file system on their systems.

* Workload 3 (Object Storage): Use Ceph to host and serve object-based data, such as HTML pages, through an S3-compatible API.