# Handling Container Workload

## Building up the platform together

On which steps above did you have technical problems? What was the problem? How did you solved it? Make subparagraphs for each point. 
Make this summary together in your group.

### 0. Automating Everything
We opted to approach this assignment—and all future ones—with a focus on automation using tools and scripts.
For Assignment 02-Container, we selected Terraform to set up the SwitchEngines infrastructure and Ansible playbooks to execute tasks within the instances.
Additionally, we wrote a comprehensive bash script that integrated these functionalities, providing a seamless one-(or two)-click experience.
The Repository can be found here: https://github.com/Soldatstar/HS24-Cloud

### 1. Configuring Network Connection for LXC Containers
* Step: Link containers to virtual bridge
* What: While editing the file `/etc/lxc/default.conf`, I needed to adjust the network settings. Initially, my Ansible script was set up to delete the entire file, which caused all important AppArmor entries to be lost.
* Solved via: The solution was to modify the Ansible script so that it recognized the relevant lines using regex and only overwrote those, rather than deleting the entire file.

### 2. Understanding Security Groups in the Switch Engine
* Step: Adding security groups
* What: I manually entered the security groups in the Switch Engine but took a long time to realize that these also needed to be added in addition to the instances for them to function correctly.
* Solved via: After several attempts and inquiries, I finally recognized the relationships and adjusted the configuration accordingly.

### 3. Adjusting cgroup for Memory Limits
* Step: Setting memory limits for cgroup
* What: I struggled to execute the command `lxc-cgroup -n cloud-test memory.limit_in_bytes 512M`. It did not work as expected.
* Solved via: After checking under `/sys/fs/cgroup/lxc.payload.cloud-test`, I discovered the file `memory.max`. I was then able to resolve the issue using the command `lxc-cgroup -n cloud-test memory.max 512M`.

### 4. Adjusting docker Compose for Swarm Syntax
* Step: Running the monitoring stack in Docker Swarm.
* What: Encountered difficulties while rewriting the Docker Compose syntax, resulting in multiple deployment errors.
* Solved via: Studied the Docker Swarm documentation and gained knowledge on key concepts such as constraints, replicas, and networking configurations within a Swarm environment.


## Personal reflection

Now that you used Proxmox and Containers: Reflect personally (each person for him/herself), when would you choose containers and when would you use VMs.
Each person should give at least 3 examples with workloads and should argue about the decision. Use the technical differences of both platforms for your argumentation. Become as technical as possible. 

### Damjan

* Workload-1: Running a web application with varying traffic patterns; I would choose containers. The use of cgroups allows me to control resource allocation effectively; for instance, if a container consumes excessive memory, the cgroup limits will ensure that the container process is killed, preventing system overload.


* Workload-2: Hosting an application that requires a specific operating system and configuration; in this case, I would opt for VMs. When using Proxmox as an IaaS solution, VMs allow for better security boundaries due to the separation of namespaces.


* Workload-3: Hosting the SBB Webticket shop, where ticket requests vary significantly at different times; I would choose containers, as they offer faster startup times than VMs. By running multiple containers from a single image, I can quickly adapt to higher demand.

### Viktor

* Workload-1: CI/CD Pipeline: I would choose containers for this workload because they are lightweight and can be deployed quickly. If a build or test fails, containers can be easily stopped or removed without using a lot of resources, making them perfect for this type of environment. Containers can be started and destroyed quickly, which is important in a CI/CD pipeline.


* Workload-2: Dev or Test Environments: Again, I would go with containers. The main reason is that containers allow for fast deployment, easy rollback, and consistent environments for testing, without worrying about different OS versions. They ensure that the environment remains the same, making it easier to build and test applications reliably.


* Workload-3: Running Specific OS/Tools: For this workload, I would use VMs. For example, TrueNAS Scale is a storage-focused operating system that has built-in features like app hosting, container management, and NAS support. These types of specialized tools need a full operating system with specific settings, which is best done with a VM. VMs provide full isolation, ensuring the system works as expected without affecting other processes.