# Swarm on Mesos scalability tests

## Environment tested

All tests are performed in a cluster of 10 or 20 nodes of SoftLayer virtual machines.

Hosts:
```
SoftLayer Public CCIs
1 master: 8 CPU / 16 GB RAM
10/20 slaves: 8 CPU / 16 GB RAM
Ubuntu 14.04 LTS 64 bits
Kernel: Linux 3.19.0-31-generic #36~14.04.1-Ubuntu SMP Thu Oct 8 10:21:08 UTC 2015 x86_64 x86_64 x86_64 GNU/Linux
```
Docker version:
```
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
```
Mesos:
```
version 0.25.0
```
Swarm:
```
version 1.0.0 (official image from Docker Hub - https://hub.docker.com/_/Swarm/ )
```
For non-Marathon managed Swarm, we start Swarm with:
```
docker run -e Swarm_MESOS_USER=root -d -p 4375:2375 -p 3376:3375 --name Swarm Swarm manage -c mesos-experimental --cluster-opt mesos.address=0.0.0.0 --cluster-opt mesos.port=3376 --cluster-opt mesos.tasktimeout=10m --cluster-opt mesos.offertimeout=1m 1<Master-IP>:5050
```
We tested with mesos.offertimeout=1m and mesos.offertimeout=10000m (so that offers never expire)

## Benchmark
[Baseline scalability test](../scripts/scaletest-swarm.sh)
The test executes sequentially the following steps:

1. Start container on Swarm with busybox image, default docker networking with docker bridge and icc = true, and the default httpd server

2. Capture the time it takes for docker run to return - 'Container Launched'

3. Use inspect on launched container to find out when it goes to 'Running' state - 'Container Running'

4. Use inspect to get IP address and host for the container and measure time to TCP connectivity.
Note that we wait for completion of each step before starting the next one.

## Results
We have tested Swarm with the following setups:

1. Swarm standalone (without mesos)

2. Swarm on mesos, with Swarm manager as marathon managed app

3. Swarm on mesos, with Swarm manager non managed by marathon

### Swarm standalone, 10 nodes
The swarm standalone tests are used to provide a baseline for the swarm mesos tests. We found that swarm standalone scales quite well, and the linear growth in time for each new container started closely mirrors the performances of the docker engine running on a single node.

![alt text](test-10000-d1.9-k3.19-swarm1.0-10nodes.png "Swarm 1.0, Docker 1.9, 10 Nodes Cluster")

### Swarm on mesos, with Swarm manager as marathon managed app, 10 Nodes
We saw a significant latency and variance increase in this test with the number of deployed containers. We plan to investigate more on the root cause, however we suspect that one key issue is that we have been deploying Swarm manager in one of the nodes managed by swarm. It is possible that this is affecting the performances of Swarm manager.

![alt text](https://github.com/Open-I-Beam/containers-os/blob/master/swarm-mesos/151201-paolo-swarm-on-mesos/test-3700-d1.9-k3.19-swarm1.0marathon-mesos0.25-10nodes.png "Swarm 1.0 on Mesos, managed by Marathon, Docker 1.9, 10 Nodes Cluster")

### Swarm on mesos, with Swarm manager deployed on the Mesos Master VM, 10 Nodes, offertimeout=1m
We observed improved latency and variance with this setup.

![alt text](https://github.com/Open-I-Beam/containers-os/blob/master/swarm-mesos/151201-paolo-swarm-on-mesos/test-5600-d1.9-k3.19-swarm1.0-mesos0.25-10nodes.png "Swarm 1.0 on Mesos, not managed by Marathon, Docker 1.9, 10 Nodes Cluster, offertimeout=1m")

### Swarm on mesos, with Swarm manager deployed on the Mesos Master VM, 20 Nodes, offertimeout=10000m
We observed a further improvement in latency and variance with this setup.

![alt text](https://github.com/Open-I-Beam/containers-os/blob/master/swarm-mesos/151201-paolo-swarm-on-mesos/test-5000-d1.9-k3.19-swarm1.0-mesos0.25-20nodes-big-offer-timeout.png "Swarm 1.0 on Mesos, not managed by Marathon, Docker 1.9, 20 Nodes Cluster, offertimeout=10000m")

### Comparison
Here is a comparison of the baseline tests on Swarm standalone with Swarm on Mesos in the different configurations described above.

![alt text](https://github.com/Open-I-Beam/containers-os/blob/master/swarm-mesos/151201-paolo-swarm-on-mesos/Swarm and swarm on mesos comparisons.png "Swarm and Swarm on Mesos scalability tests comparisons")

Since our initial tests on Swarm were performed on a 10 nodes cluster, we repeated the Swarm scalability test on the same 20 node cluster we used for the tests on Swarm on Mesos, and we compared the best results we obtained for Swarm on Mesos with stanadlone Swarm:

![alt text](https://github.com/Open-I-Beam/containers-os/blob/master/swarm-mesos/151201-paolo-swarm-on-mesos/Swarm on mesos vs swarm 20 nodes.png "Swarm and Swarm on Mesos scalability tests comparisons, 20 nodes cluster")
