# Container-Tutorial

This tutorial guides you in the usage of containers.
And before working with docker, podman and docker swarm, we first need to know lxc.

All tutorials can be installed on Debian 12.

Evaluation takes place on points to be reached. All necessary components for the grading are denoted by a `MUST`. This is necessary as the evaluation takes place with scripts and automatisms.
The grade is based on the points using the following formular:

Grade = 1 + (Points Reached) * 5 / (Max Points)

Total Points reachable: 27

* All nodes MUST have a local user `eval` with the ssh-key stored in https://gitlab.fhnw.ch/cloud/cloud/platforms_to_build/-/blob/main/access/id_ed25519.pub . This user MUST have passwordless sudo-rights. Adding via Group `sudo` might not work since this group is not able to act passwordless by default.
* Your machine names MUST match the names given (e.g. `container-lxc-host` or `docker-mgr-01`).

## LXC

LXC is the root of most modern container technologies.
Even though many container runtimes are not using lxc anymore, the concepts stays valid plus its modularity enables us to understand containers.

As a consequence, we want to know lxc and docker better and see how they work.

### Installing LXC

* Create a new debian machine called `container-lxc-host`. The machine should be something like 2 CPUs, 4GB RAM, 50GB Storage (typical m1.medium instance).
* You MUST add an eval-user with the corresponding ssh-key stored in `../access/id_ed25519.pub`. The eval-user MUST have sudo-rights as described.
* Install lxc. A tutorial can be found under https://learning.oreilly.com/library/view/practical-lxc-and/9781484230244/A441185_1_En_2_Chapter.html
  * It states it works with ubuntu, but it works with debian (nearly) as well
  * You need to additionally install `apparmor` besides the packages denoted in the tutorial

#### Points:

* lxc MUST be installed with all necessary packages and lxc-commands executable: 2 Points

### Setting up container

* Install a linux. Use download as template when creating the container. The container MUST be named : `cloud-test`
  * Test with rockylinux:9:amd64 was successful, however choose whatever you want. You just have to have the ability to install the load-generator `stress-ng`.

#### Points:

* Container with name `cloud-test` MUST exits, MUST be runnable, and MUST be attached to a valid network to generate egress-traffic: 3 Points

#### Tips

* For networking: use a bridge or libvirt. Anyhow, give the contains a different IP-range than your host has.
* Note that the container fails if network, packages, etc. are missing. You have to configure this. Follow the instructions in the tutorial.


## Docker.io

Docker represents nowadays a well established way to handle containerized workloads.
However, under the hood, most if not all features from lxc apply.

### Installing and setting up docker including monitoring

We want to install and handle docker, and see how where the differences lie between lxc and docker.

* Install docker. A comprehensive guide is available under https://docs.docker.com/engine/install/debian/#install-using-the-repository
  * The commands `docker` as well as `docker compose` MUST be installed
  * Get the predefined monitoring-stack from https://tutorial:glpat-H1DGVgsv7Sp4W-E-kQYA@gitlab.fhnw.ch/cloud/cloud/monitoringstack.git
    * Start the monitoring stack and make sure it runs

#### Points:

* Monitoring stack MUST be running, MUST be started automatically upon machine restart and MUST collect metrics: 3 Points

#### Tips:

* Note that the exporters are accessible from the outside regarding the docker-compose. Although we actually do not want to do this in production, it helps debugging the systems.
* When you access cadvisor directly (not via grafana), you should see the running lxc-container.
* To see the exporters directly in your client, do not forget to adapt the Security Groups in your Switch Engines.

## Knowing cGroups

Now we want to know cGroups better. So we play around a little bit:

* Got to the running lxc-container and install the stress tool `stress-ng` to generate load

#### Points:

* Full load MUST be generated within lxc-container and monitoring MUST collect its metrics for at least 5 minutes constantly: 3 Points

### CPU-Load, throttling workloads

In a fresh installed environment, we have no limits in the cgroups specified

* Restrict in the cgroup for CPU the number of usable cores to 1. The adaption can be made e.g. via `lxc-cgroup`.
* Generate full load in the container again. Be sure the monitoring tracks the load.

#### Points:

* cGroup MUST be adapted regarding CPU cores to `1`.
* Partial load with adapted cgroup for CPU MUST be generated within lxc-container and monitoring MUST collect it for at least 5 minutes constantly: 3 Points

### Memory Consumption, throttling workloads

We have also no limits in the cgroups specified. Be sure the container has again the ability to use all cores.
Now we focus on memory.

* Restrict in the cgroup the memory to 512m. The adaption can be made e.g. via `lxc-cgroup` again.
* Generate full load in the container again. Be sure the monitoring tracks the load.

#### Points:

* cGroup MUST be adapted regarding memory to `512m`.
* Partial load with adapted cgroup for memory MUST be generated within lxc-container and monitoring MUST collect it for at least 5 minutes constantly: 3 Points

#### Tips for generating load:
 * Full load as mentioned above means that you really should stress the machine e.g.g by using all cores and all memory. You need to adapt the parameters for `stress-ng`. The standard example call is not utilizing the entire memory and is therefore unsuitable.


## Docker, Podman and Docker Swarm

So far, you experience lxc and docker. We will not focus how to build images in this tutorial, but how to handle them.

### Create a Docker Swarm Cluster

* Create 3 machines with the same specifications as the `container-lxc-host`: The machine should be something like 2 CPUs, 4GB RAM, 50GB Storage (typical m1.medium instance).
  * One machine MUST be named `docker-mgr-01`.
  * Two machines MUST be named `docker-wrk-[01|02]`.
* Create a docker swarm cluster, the manager MUST run on `docker-mgr-01`. Information how to do it can be found under https://learning.oreilly.com/library/view/docker-deep-dive/9781800565135/chap12.xhtml#leanpub-auto-docker-swarm---the-deep-dive


#### Points:

* Docker Swarm MUST run correctly with three nodes: 3 Points

### Monitoring should be running

As we will not focus on own images but on the platform, we take the monitoring-stack as application to be deployed.

* Deploy the monitoring stack under https://tutorial:glpat-H1DGVgsv7Sp4W-E-kQYA@gitlab.fhnw.ch/cloud/cloud/monitoringstack on the Swarm Cluster given the following conditions:
 * Node-Exporter and cAdvisor MUST run on all nodes
 * Grafana, Prometheus MUST only run on one node
 * Grafana, Prometheus MUST be accessible from public
 * no unsupported options MUST be kept in the docker-compose
 
#### Tips

* You need to adapt the docker compose:
 * Network `bridge` is not working. Refer to the documentation/lecture for an alternative
 * you need a flag so the containers are spawn on all nodes
 * you need to set a dedicated hostname to cadvisor and nodeexporter
 * The hostname needs afterwards be inserted in the `prometheus/prometheus.yml`-file: No need to understand this file in detail, just replace the one target under 
   ```
   static_configs:
     - targets:
       - cadvisor:8080
   ```
   with a list of targets consisting of the hostname you set.

 
#### Points

* Monitoring MUST run correctly and MUST cover all three nodes regarding node exporter and cadvisor: 5 Points

### Podman as one alternative

Using our docker swarm cluster, we want to get in touch with podman and just know this server a bit better.

* Install podman on `container-lxc-host`.
* Run and start the official nginx image. The nginx MUST be accessible via port `8624`.
  * Do not forget the security groups.

#### Points

* Nginx MUST run in podman and MUST be externally accessible via port `8624` : 2 Points

# Write a summary

This repository MUST be cloned on the machine `container-lxc-host` under the path `/home/debian/platforms_to_build`.
The following URL contains a token to clone this repository:
```
git clone https://clone-token:glpat-Hw4JUcuCPssqM-BZ_88U@gitlab.fhnw.ch/cloud/cloud/platforms_to_build.git
```
. 

A report in `/home/debian/platforms_to_build/02-container/own_report.md` MUST be written according to the given structure.
