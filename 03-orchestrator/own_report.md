# Building K8s


## Building up the platform together

Describe all steps building the cluster with commands. 
On which steps above did you have technical problems? What was the problem? How did you solved it? If you proceed to Part 3, how did you implement the load balancing?
Make subparagraphs for each point. 
Make this summary together in your group.

### [Example] Lorem Ipsum....
* Step: [Example] Initializing wrong parameter
* What: [Example] Container Runtime was not working
* Solved via: [Example] adaption of config



### Setting up HAProxy as loadbalancer
* Step: When Setting up the loadbalancer, i defined *:6444 as the bind adress.
* What: the kubeadm command always failed: "sudo kubeadm init --control-plane-endpoint "10.0.4.5:6443" --upload-certs"
* Solved via: setting the actual IP 10.0.4.5:6444 as bind adress fixed this issue.

## Personal reflection

Now that you build up the cluster: What did you learn personally regarding setting up a K8s-cluster. Get as technical as possible. Make this part for yourself.

### [Example] Sebastian

* [Example] Workload-1: Generating a load balancer with quite hard....

