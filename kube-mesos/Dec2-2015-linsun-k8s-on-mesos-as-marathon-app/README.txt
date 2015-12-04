Environment tested

All tests are performed in a cluster of 2 nodes of SoftLayer machines.

Hosts
SoftLayer Public CCIs
1 master: 8 CPU / 16 GB RAM
2 slaves: 8 CPU / 16 GB RAM
Ubuntu 14.04 LTS 64 bits
Kernel: Linux 3.19.0-31-generic #36~14.04.1-Ubuntu SMP Thu Oct 8 10:21:08 UTC 2015 x86_64 x86_64 x86_64 GNU/Linux

Docker version:
Client:
 Version:      1.9.0
 API version:  1.21
 Go version:   go1.4.2
 Git commit:   76d6bc9
 Built:        Tue Nov  3 17:43:42 UTC 2015
 OS/Arch:      linux/amd64

Server:
 Version:      1.9.0
 API version:  1.21
 Go version:   go1.4.2
 Git commit:   76d6bc9
 Built:        Tue Nov  3 17:43:42 UTC 2015
 OS/Arch:      linux/amd64

Mesos:
version 0.25.0

Kubernetes:
1.1 branch with additional tuning from Hai: https://github.com/huang195/kubernetes, packed as a docker image (linsun/km)

git clone https://github.com/huang195/kubernetes.git
git checkout release-1.1-k8sm-tuning

For Marathon-Managed Kubernetes, we deployed Kubernetes and etcd as two Marathon Applications.


Benchmark:
Baseline scalability test:
The test executes sequentially the steps below - we wait for completion of each step before starting the next one.
1. Start container on swarm with busybox image, default docker networking with docker bridge and icc = true, and the default httpd server
2. Capture the time it takes for docker run to return - 'Container Launched'
3. Use inspect on launched container to find out when it goes to 'Running' state - 'Container Running' 
4. Use inspect to get IP address and host for the container and measure time to TCP connectivity.


