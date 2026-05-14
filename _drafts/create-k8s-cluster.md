# 创建k8s集群



具体参考文档F:\DevOps\马哥教育运维培训\2025-Linux云计算SRE-N98\N98架构班\1-10\马哥教育M66期20260128第9天-堡垒机JumpServer安装管理和Kubernetes架构安装\课件\Kubernetes架构和部署实验手册.pdf



```sh

  
  
  0 ✓ 09:45:04 root@k8s-master1-101,172.17.0.1:~ # systemctl status kubelet
● kubelet.service - kubelet: The Kubernetes Node Agent
     Loaded: loaded (/usr/lib/systemd/system/kubelet.service; enabled; preset: enabled)
    Drop-In: /usr/lib/systemd/system/kubelet.service.d
             └─10-kubeadm.conf
     Active: activating (auto-restart) (Result: exit-code) since Thu 2026-05-14 09:45:45 CST; 6s ago
       Docs: https://kubernetes.io/docs/
    Process: 74225 ExecStart=/usr/bin/kubelet $KUBELET_KUBECONFIG_ARGS $KUBELET_CONFIG_ARGS $KUBELET_KUBEADM_ARGS $KUBELET_EXTRA_ARGS (code=exited, status=1/FAILURE)
   Main PID: 74225 (code=exited, status=1/FAILURE)
        CPU: 67ms
  3 ✗ 09:45:52 root@k8s-master1-101,172.17.0.1:~ # tail /var/log/syslog
2026-05-14T01:46:06.237634+00:00 k8s-master-101 (kubelet)[74254]: kubelet.service: Referenced but unset environment variable evaluates to an empty string: KUBELET_KUBEADM_ARGS
2026-05-14T01:46:06.285239+00:00 k8s-master-101 kubelet[74254]: E0514 09:46:06.285057   74254 run.go:72] "command failed" err="failed to load kubelet config file, path: /var/lib/kubelet/config.yaml, error: failed to load Kubelet config file /var/lib/kubelet/config.yaml, error failed to read kubelet config file \"/var/lib/kubelet/config.yaml\", error: open /var/lib/kubelet/config.yaml: no such file or directory"
2026-05-14T01:46:06.287331+00:00 k8s-master-101 systemd[1]: kubelet.service: Main process exited, code=exited, status=1/FAILURE
2026-05-14T01:46:06.287641+00:00 k8s-master-101 systemd[1]: kubelet.service: Failed with result 'exit-code'.
2026-05-14T01:46:16.476423+00:00 k8s-master-101 systemd[1]: kubelet.service: Scheduled restart job, restart counter is at 264.
2026-05-14T01:46:16.482904+00:00 k8s-master-101 systemd[1]: Started kubelet.service - kubelet: The Kubernetes Node Agent.
2026-05-14T01:46:16.487766+00:00 k8s-master-101 (kubelet)[74261]: kubelet.service: Referenced but unset environment variable evaluates to an empty string: KUBELET_KUBEADM_ARGS
2026-05-14T01:46:16.536930+00:00 k8s-master-101 kubelet[74261]: E0514 09:46:16.536744   74261 run.go:72] "command failed" err="failed to load kubelet config file, path: /var/lib/kubelet/config.yaml, error: failed to load Kubelet config file /var/lib/kubelet/config.yaml, error failed to read kubelet config file \"/var/lib/kubelet/config.yaml\", error: open /var/lib/kubelet/config.yaml: no such file or directory"
2026-05-14T01:46:16.539867+00:00 k8s-master-101 systemd[1]: kubelet.service: Main process exited, code=exited, status=1/FAILURE
2026-05-14T01:46:16.540385+00:00 k8s-master-101 systemd[1]: kubelet.service: Failed with result 'exit-code'.
  0 ✓ 09:46:26 root@k8s-master1-101,172.17.0.1:~ # kubeadm 
certs       completion  config      help        init        join        kubeconfig  reset       token       upgrade     version     
  0 ✓ 09:46:26 root@k8s-master1-101,172.17.0.1:~ # kubeadm 
certs       completion  config      help        init        join        kubeconfig  reset       token       upgrade     version     
  0 ✓ 09:46:26 root@k8s-master1-101,172.17.0.1:~ # ^C
130 ✗ 09:47:06 root@k8s-master1-101,172.17.0.1:~ # echo $K8S_RELEASE_VERSION

  0 ✓ 09:47:22 root@k8s-master1-101,172.17.0.1:~ # kubectl --version
error: unknown flag: --version
See 'kubectl --help' for usage.
  1 ✗ 09:48:19 root@k8s-master1-101,172.17.0.1:~ # kubelet --version
Kubernetes v1.35.4
  0 ✓ 09:48:23 root@k8s-master1-101,172.17.0.1:~ # K8S_RELEASE_VERSION=1.35.4
  0 ✓ 09:48:43 root@k8s-master1-101,172.17.0.1:~ # kubeadm init --kubernetes-version=v${K8S_RELEASE_VERSION} --control-plane-endpoint kubeapi.zhong.org --pod-network-cidr 10.244.0.0/16 --service-cidr 10.96.0.0/12 --token-ttl=0 --image-repository registry.aliyuncs.com/google_containers --upload-certs --cri-socket=unix:///run/cri-dockerd.sock 
[init] Using Kubernetes version: v1.35.4
[preflight] Running pre-flight checks
[preflight] Some fatal errors occurred:
	[ERROR CRI]: could not connect to the container runtime: failed to create new CRI runtime service: validate service connection: validate CRI v1 runtime API for endpoint "unix:///run/cri-dockerd.sock": rpc error: code = Unavailable desc = connection error: desc = "transport: Error while dialing: dial unix /run/cri-dockerd.sock: connect: connection refused"
	[ERROR ContainerRuntimeVersion]: could not connect to the container runtime: failed to create new CRI runtime service: validate service connection: validate CRI v1 runtime API for endpoint "unix:///run/cri-dockerd.sock": rpc error: code = Unavailable desc = connection error: desc = "transport: Error while dialing: dial unix /run/cri-dockerd.sock: connect: connection refused"
[preflight] If you know what you are doing, you can make a check non-fatal with `--ignore-preflight-errors=...`
error: error execution phase preflight: preflight checks failed
To see the stack trace of this error execute with --v=5 or higher
  1 ✗ 09:52:03 root@k8s-master1-101,172.17.0.1:~ # systemctl status cri-dockerd
Unit cri-dockerd.service could not be found.
  4 ✗ 09:53:56 root@k8s-master1-101,172.17.0.1:~ # systemctl status cri-docker
● cri-docker.service - CRI Interface for Docker Application Container Engine
     Loaded: loaded (/usr/lib/systemd/system/cri-docker.service; enabled; preset: enabled)
     Active: active (running) since Fri 2026-04-24 13:18:14 CST; 2 weeks 5 days ago
TriggeredBy: ● cri-docker.socket
       Docs: https://docs.mirantis.com
   Main PID: 1634 (cri-dockerd)
      Tasks: 10
     Memory: 74.5M (peak: 78.5M)
        CPU: 56.060s
     CGroup: /system.slice/cri-docker.service
             └─1634 /usr/bin/cri-dockerd --container-runtime-endpoint fd:// --pod-infra-container-image registry.aliyuncs.com/google_containers/pause:3.10.1

5月 14 09:28:54 k8s-master-101 cri-dockerd[1634]: time="2026-05-14T01:28:54Z" level=error msg="error getting RW layer size for container ID '63f42ebff036d3d797e73e1c11>
5月 14 09:28:54 k8s-master-101 cri-dockerd[1634]: time="2026-05-14T01:28:54Z" level=error msg="Set backoffDuration to : 1m0s for container ID '63f42ebff036d3d797e73e1c>
5月 14 09:28:54 k8s-master-101 cri-dockerd[1634]: time="2026-05-14T01:28:54Z" level=error msg="error getting RW layer size for container ID 'b0a08e9cf5878d19093a13df77>
5月 14 09:28:54 k8s-master-101 cri-dockerd[1634]: time="2026-05-14T01:28:54Z" level=error msg="Set backoffDuration to : 1m0s for container ID 'b0a08e9cf5878d19093a13df>
5月 14 09:28:55 k8s-master-101 cri-dockerd[1634]: time="2026-05-14T01:28:55Z" level=error msg="error getting RW layer size for container ID '1e904d040fc6950c28603428ad>
5月 14 09:28:55 k8s-master-101 cri-dockerd[1634]: time="2026-05-14T01:28:55Z" level=error msg="Set backoffDuration to : 1m0s for container ID '1e904d040fc6950c28603428>
5月 14 09:28:55 k8s-master-101 cri-dockerd[1634]: time="2026-05-14T01:28:55Z" level=error msg="error getting RW layer size for container ID 'fc1d77e0eb66b53defead2211d>
5月 14 09:28:55 k8s-master-101 cri-dockerd[1634]: time="2026-05-14T01:28:55Z" level=error msg="Set backoffDuration to : 1m0s for container ID 'fc1d77e0eb66b53defead221>
5月 14 09:28:55 k8s-master-101 cri-dockerd[1634]: time="2026-05-14T01:28:55Z" level=error msg="error getting RW layer size for container ID '65e220613cdb14f118bed9999e>
5月 14 09:28:55 k8s-master-101 cri-dockerd[1634]: time="2026-05-14T01:28:55Z" level=error msg="Set backoffDuration to : 1m0s for container ID '65e220613cdb14f118bed999>
  0 ✓ 09:55:23 root@k8s-master1-101,172.17.0.1:~ # kubeadm init --kubernetes-version=v${K8S_RELEASE_VERSION} --control-plane-endpoint kubeapi.zhong.org --pod-network-cidr 10.244.0.0/16 --service-cidr 10.96.0.0/12 --token-ttl=0 --image-repository registry.aliyuncs.com/google_containers --upload-certs --cri-socket=unix:///run/cri-docker
.sock
[init] Using Kubernetes version: v1.35.4
[preflight] Running pre-flight checks
[preflight] Some fatal errors occurred:
	[ERROR CRI]: could not connect to the container runtime: failed to create new CRI runtime service: validate service connection: validate CRI v1 runtime API for endpoint "unix:///run/cri-docker.sock": rpc error: code = Unavailable desc = connection error: desc = "transport: Error while dialing: dial unix /run/cri-docker.sock: connect: no such file or directory"
	[ERROR ContainerRuntimeVersion]: could not connect to the container runtime: failed to create new CRI runtime service: validate service connection: validate CRI v1 runtime API for endpoint "unix:///run/cri-docker.sock": rpc error: code = Unavailable desc = connection error: desc = "transport: Error while dialing: dial unix /run/cri-docker.sock: connect: no such file or directory"
[preflight] If you know what you are doing, you can make a check non-fatal with `--ignore-preflight-errors=...`
error: error execution phase preflight: preflight checks failed
To see the stack trace of this error execute with --v=5 or higher
  1 ✗ 09:55:33 root@k8s-master1-101,172.17.0.1:~ # ls /var/run/cri-docker.sock
ls: 无法访问 '/var/run/cri-docker.sock': 没有那个文件或目录
  2 ✗ 09:56:57 root@k8s-master1-101,172.17.0.1:~ # ls /var/run/c
chrony/           cloud-init/       console-setup/    containerd/       credentials/      cri-dockerd.sock  crond.pid         crond.reboot      cryptsetup/
  2 ✗ 09:56:57 root@k8s-master1-101,172.17.0.1:~ # ls /var/run/c
chrony/           cloud-init/       console-setup/    containerd/       credentials/      cri-dockerd.sock  crond.pid         crond.reboot      cryptsetup/
  2 ✗ 09:56:57 root@k8s-master1-101,172.17.0.1:~ # ls /var/run/cri-dockerd.sock 
/var/run/cri-dockerd.sock
  0 ✓ 09:57:10 root@k8s-master1-101,172.17.0.1:~ # ll /var/run/cri-dockerd.sock
srwxr-xr-x 1 root root 0  5月 14 09:40 /var/run/cri-dockerd.sock=
  0 ✓ 09:57:21 root@k8s-master1-101,172.17.0.1:~ # 

```

It looks like you're caught in a "chicken and egg" problem with the `kubelet` and a minor typo in your socket path. Your logs show the `kubelet` is failing because it can't find its config file (which `kubeadm init` hasn't created yet), and `kubeadm init` is failing because it can't talk to your container runtime.

Here is the breakdown of how to fix this:

### 1. Fix the Socket Path Typo

In your last attempt, you used `--cri-socket=unix:///run/cri-docker.sock`.

However, your `ls` command confirms the socket is actually named `cri-dockerd.sock` (with a **d**).

### 2. The Kubelet "Failure" is Normal

Don't worry about `systemctl status kubelet` showing an error right now. The `kubelet` cannot start until `kubeadm init` generates the configuration file at `/var/lib/kubelet/config.yaml`. Once the `init` command succeeds, the kubelet will stabilize automatically.

------

### Step-by-Step Recovery

**Step 1: Clean up any partial state**

Before retrying, ensure you have a clean slate so the pre-flight checks don't complain about existing files.

Bash

```
kubeadm reset --cri-socket=unix:///var/run/cri-dockerd.sock -f
```

**Step 2: Run the correct Init command**

Use the verified socket path: `/var/run/cri-dockerd.sock`.

Bash

```
kubeadm init \
  --kubernetes-version=v1.35.4 \
  --control-plane-endpoint kubeapi.zhong.org \
  --pod-network-cidr 10.244.0.0/16 \
  --service-cidr 10.96.0.0/12 \
  --token-ttl=0 \
  --image-repository registry.aliyuncs.com/google_containers \
  --upload-certs \
  --cri-socket=unix:///var/run/cri-dockerd.sock
```

### Why it failed earlier:

| **Attempt**   | **Path Used**                  | **Reality**  | **Result**                                                   |
| ------------- | ------------------------------ | ------------ | ------------------------------------------------------------ |
| **Attempt 1** | `unix:///run/cri-dockerd.sock` | Refused      | The service might have been restarting or the socket wasn't ready. |
| **Attempt 2** | `unix:///run/cri-docker.sock`  | No such file | **Typo:** Missing the 'd' at the end of `cri-dockerd`.       |

### Troubleshooting if it still fails:

If the "Connection Refused" error persists even with the correct path:

1. **Restart the CRI service:**

   Bash

   ```
   systemctl restart cri-docker.socket cri-docker.service
   ```

2. **Check Docker status:** Ensure the underlying Docker engine is actually running, as `cri-dockerd` is just a shim for it.

   Bash

   ```
   systemctl status docker
   ```

Once `kubeadm init` finishes, remember to copy the `admin.conf` to your home directory as instructed by the output so that `kubectl` starts working!




```sh

1 ✗ 10:00:14 root@k8s-master1-101,172.17.0.1:~ # ll /var/run/cri-dockerd.sock 
srwxr-xr-x 1 root root 0  5月 14 09:40 /var/run/cri-dockerd.sock=
  0 ✓ 10:00:26 root@k8s-master1-101,172.17.0.1:~ # kubeadm reset --cri-socket=unix:///var/run/cri-dockerd.sock -f
[preflight] Running pre-flight checks
W0514 10:01:26.149456   75198 removeetcdmember.go:105] [reset] No kubeadm config, using etcd pod spec to get data directory
[reset] Deleted contents of the etcd data directory: /var/lib/etcd
[reset] Stopping the kubelet service
W0514 10:01:26.160082   75198 cleanupnode.go:86] [reset] Skipping unmount of directories in "/var/lib/kubelet": lstat /var/lib/kubelet: no such file or directory
W0514 10:01:26.161055   75198 cleanupnode.go:104] [reset] Failed to remove containers: failed to create new CRI runtime service: validate service connection: validate CRI v1 runtime API for endpoint "unix:///var/run/cri-dockerd.sock": rpc error: code = Unavailable desc = connection error: desc = "transport: Error while dialing: dial unix /var/run/cri-dockerd.sock: connect: connection refused"
[reset] Deleting contents of directories: [/etc/kubernetes/manifests /etc/kubernetes/pki]
[reset] Deleting files: [/etc/kubernetes/admin.conf /etc/kubernetes/super-admin.conf /etc/kubernetes/kubelet.conf /etc/kubernetes/bootstrap-kubelet.conf /etc/kubernetes/controller-manager.conf /etc/kubernetes/scheduler.conf]

The reset process does not perform cleanup of CNI plugin configuration,
network filtering rules and kubeconfig files.

For information on how to perform this cleanup manually, please see:
    https://k8s.io/docs/reference/setup-tools/kubeadm/kubeadm-reset/

  0 ✓ 10:01:26 root@k8s-master1-101,172.17.0.1:~ # kubeadm init \
  --kubernetes-version=v1.35.4 \
  --control-plane-endpoint kubeapi.zhong.org \
  --pod-network-cidr 10.244.0.0/16 \
  --service-cidr 10.96.0.0/12 \
  --token-ttl=0 \
  --image-repository registry.aliyuncs.com/google_containers \
  --upload-certs \
  --cri-socket=unix:///var/run/cri-dockerd.sock
[init] Using Kubernetes version: v1.35.4
[preflight] Running pre-flight checks
[preflight] Some fatal errors occurred:
	[ERROR CRI]: could not connect to the container runtime: failed to create new CRI runtime service: validate service connection: validate CRI v1 runtime API for endpoint "unix:///var/run/cri-dockerd.sock": rpc error: code = Unavailable desc = connection error: desc = "transport: Error while dialing: dial unix /var/run/cri-dockerd.sock: connect: connection refused"
	[ERROR ContainerRuntimeVersion]: could not connect to the container runtime: failed to create new CRI runtime service: validate service connection: validate CRI v1 runtime API for endpoint "unix:///var/run/cri-dockerd.sock": rpc error: code = Unavailable desc = connection error: desc = "transport: Error while dialing: dial unix /var/run/cri-dockerd.sock: connect: connection refused"
[preflight] If you know what you are doing, you can make a check non-fatal with `--ignore-preflight-errors=...`
error: error execution phase preflight: preflight checks failed
To see the stack trace of this error execute with --v=5 or higher
  1 ✗ 10:01:39 root@k8s-master1-101,172.17.0.1:~ # 
```



The issue is now clear: although the file `/var/run/cri-dockerd.sock` exists, the service is not actually listening on it (**Connection Refused**). In systems using `cri-dockerd`, this usually means the systemd **socket** is active, but the **service** (the actual logic) has crashed or failed to initialize properly.

Since Kubernetes 1.24+, Docker requires this shim to function. If the shim isn't healthy, `kubeadm` can't talk to Docker.

------

### 1. Identify the Culprit

Check the status of both the socket and the service. Often the socket is "Active" but the service is "Failed."

Bash

```
systemctl status cri-docker.socket
systemctl status cri-docker.service
```

### 2. The Fix: Restart and Re-enable

Run these commands in order to reset the connection state:

Bash

```
# Reload configurations
systemctl daemon-reload

# Restart the shim components
systemctl restart cri-docker.socket cri-docker.service

# Verify they are running
systemctl is-active cri-docker.service
```

### 3. Verify the Socket is Listening

Before running `kubeadm` again, test the socket manually. If this command returns a version string, the socket is healthy:

Bash

```
crictl --runtime-endpoint unix:///var/run/cri-dockerd.sock version
```

> **Note:** If `crictl` is not configured, you might get an error. You can also try:
>
> `nc -vz -U /var/run/cri-dockerd.sock` (Checks if the Unix socket is actually open).

------

### 4. Why is it refusing connection?

If the restart doesn't fix it, check the logs for the shim:

Bash

```
journalctl -u cri-docker.service -n 50
```

**Common reasons for "Connection Refused" here:**

- **Docker is down:** `cri-dockerd` depends on the Docker engine. If `systemctl status docker` shows it's down, start Docker first.
- **CRI Version Mismatch:** Your logs mention `validate CRI v1`. Ensure your version of `cri-dockerd` is compatible with Kubernetes v1.35. (You are using a very bleeding-edge version of K8s; ensure `cri-dockerd` is updated to the latest release from the Mirantis GitHub).
- **Permissions:** Rarely, the socket permissions get messed up. The `ll` output you showed (`srwxr-xr-x`) looks correct for root.

### 5. Final Attempt

Once the service is verified as `active (running)`, try your init command again:

Bash

```
kubeadm init \
  --kubernetes-version=v1.35.4 \
  --control-plane-endpoint kubeapi.zhong.org \
  --pod-network-cidr 10.244.0.0/16 \
  --service-cidr 10.96.0.0/12 \
  --token-ttl=0 \
  --image-repository registry.aliyuncs.com/google_containers \
  --upload-certs \
  --cri-socket=unix:///var/run/cri-dockerd.sock
```

**Does `systemctl status cri-docker.service` show "active (running)" now, or does it flip back to "failed"?**

```sh
  1 ✗ 10:01:39 root@k8s-master1-101,172.17.0.1:~ # systemctl status cri-docker
● cri-docker.service - CRI Interface for Docker Application Container Engine
     Loaded: loaded (/usr/lib/systemd/system/cri-docker.service; enabled; preset: enabled)
     Active: active (running) since Fri 2026-04-24 13:18:14 CST; 2 weeks 5 days ago
TriggeredBy: ● cri-docker.socket
       Docs: https://docs.mirantis.com
   Main PID: 1634 (cri-dockerd)
      Tasks: 10
     Memory: 74.7M (peak: 78.5M)
        CPU: 56.520s
     CGroup: /system.slice/cri-docker.service
             └─1634 /usr/bin/cri-dockerd --container-runtime-endpoint fd:// --pod-infra-container-image registry.aliyuncs.com/google_containers/pause:3.10.1

5月 14 09:28:54 k8s-master-101 cri-dockerd[1634]: time="2026-05-14T01:28:54Z" level=error msg="error getting RW layer size for container ID '63f42ebff036d3d797e73e1c11>
5月 14 09:28:54 k8s-master-101 cri-dockerd[1634]: time="2026-05-14T01:28:54Z" level=error msg="Set backoffDuration to : 1m0s for container ID '63f42ebff036d3d797e73e1c>
5月 14 09:28:54 k8s-master-101 cri-dockerd[1634]: time="2026-05-14T01:28:54Z" level=error msg="error getting RW layer size for container ID 'b0a08e9cf5878d19093a13df77>
5月 14 09:28:54 k8s-master-101 cri-dockerd[1634]: time="2026-05-14T01:28:54Z" level=error msg="Set backoffDuration to : 1m0s for container ID 'b0a08e9cf5878d19093a13df>
5月 14 09:28:55 k8s-master-101 cri-dockerd[1634]: time="2026-05-14T01:28:55Z" level=error msg="error getting RW layer size for container ID '1e904d040fc6950c28603428ad>
5月 14 09:28:55 k8s-master-101 cri-dockerd[1634]: time="2026-05-14T01:28:55Z" level=error msg="Set backoffDuration to : 1m0s for container ID '1e904d040fc6950c28603428>
5月 14 09:28:55 k8s-master-101 cri-dockerd[1634]: time="2026-05-14T01:28:55Z" level=error msg="error getting RW layer size for container ID 'fc1d77e0eb66b53defead2211d>
5月 14 09:28:55 k8s-master-101 cri-dockerd[1634]: time="2026-05-14T01:28:55Z" level=error msg="Set backoffDuration to : 1m0s for container ID 'fc1d77e0eb66b53defead221>
5月 14 09:28:55 k8s-master-101 cri-dockerd[1634]: time="2026-05-14T01:28:55Z" level=error msg="error getting RW layer size for container ID '65e220613cdb14f118bed9999e>
5月 14 09:28:55 k8s-master-101 cri-dockerd[1634]: time="2026-05-14T01:28:55Z" level=error msg="Set backoffDuration to : 1m0s for container ID '65e220613cdb14f118bed999>
  0 ✓ 10:03:06 root@k8s-master1-101,172.17.0.1:~ # systemctl status cri-docker.socket
● cri-docker.socket - CRI Docker Socket for the API
     Loaded: loaded (/usr/lib/systemd/system/cri-docker.socket; enabled; preset: enabled)
     Active: active (running) since Fri 2026-04-24 13:18:12 CST; 2 weeks 5 days ago
   Triggers: ● cri-docker.service
     Listen: /run/cri-dockerd.sock (Stream)
      Tasks: 0 (limit: 4540)
     Memory: 0B (peak: 256.0K)
        CPU: 441us
     CGroup: /system.slice/cri-docker.socket

4月 24 13:18:12 k8s-master-101 systemd[1]: Starting cri-docker.socket - CRI Docker Socket for the API...
4月 24 13:18:12 k8s-master-101 systemd[1]: Listening on cri-docker.socket - CRI Docker Socket for the API.
  0 ✓ 10:03:17 root@k8s-master1-101,172.17.0.1:~ # 
```



This is a classic "stale socket" situation. Even though `systemctl` says the service is active, it has been running for over two weeks and is clearly failing to respond to new connections (likely due to the "error getting RW layer size" spamming your logs).

When a service is "TriggeredBy" a socket, sometimes the handoff between the `.socket` and the `.service` gets stuck.

### The Fix: Full Reset of the CRI Shim

Execute these commands to clear the stuck process and the socket file:

Bash

```
# 1. Stop both components entirely
systemctl stop cri-docker.service cri-docker.socket

# 2. Force remove the physical socket file if it still exists
rm -f /var/run/cri-dockerd.sock

# 3. Start them back up (Socket first, then Service)
systemctl start cri-docker.socket
systemctl start cri-docker.service

# 4. Verify health with crictl (this MUST work before you proceed)
crictl --runtime-endpoint unix:///var/run/cri-dockerd.sock info
```

------

### Why this is happening

The logs show `cri-dockerd` is struggling with Docker's storage layer (`error getting RW layer size`). This usually happens if:

1. **Docker was restarted** but the shim didn't reconnect properly.
2. **Disk space/Inodes** are exhausted on the partition where `/var/lib/docker` resides.
3. **Zombie Containers:** The shim is trying to track containers that Docker no longer acknowledges.

**Quick Check:** Run `df -h` and `df -i` to ensure your disk isn't 100% full.

------

### Re-running Kubeadm

Once `crictl info` (from step 4 above) returns a valid JSON response without a connection error, you can safely run your init:

Bash

```
kubeadm init \
  --kubernetes-version=v1.35.4 \
  --control-plane-endpoint kubeapi.zhong.org \
  --pod-network-cidr 10.244.0.0/16 \
  --service-cidr 10.96.0.0/12 \
  --token-ttl=0 \
  --image-repository registry.aliyuncs.com/google_containers \
  --upload-certs \
  --cri-socket=unix:///var/run/cri-dockerd.sock
```

**If `crictl info` still says "connection refused" after the restart:**

Check `systemctl status docker`. If Docker itself is unhealthy, the shim cannot function. You might need to `systemctl restart docker` as well.







## final cmd

```sh
338  timedatectl set-timezone Asia/Shanghai
  339  cat /etc/chrony/chrony.conf
  340  apt update && apt install -y chrony -y
  341  vim /etc/chrony/chrony.conf
  342  systemctl enable chrony
  343  systemctl restart chrony
  344  chronyc sources
  345  ufw status
  346  systemctl status firewalld
  347  cat /etc/fstab
  348  swapoff -a
  349  sed -i '/swap/s/^/#/' /etc/fstab
  350  cat /etc/fstab
  351  modprobe overlay
  352  modprobe br_netfilter
  353  lsmod | grep -E 'overlay|br_netfilter'
  354  ll /etc/modules-load.d/k8s.conf 
  355  cat /etc/modules-load.d/k8s.conf
  356  cat /etc/sysctl.d/k8s.conf 
  357  docker version
  358  systemctl start docker
  359  docker version
  360  cat /etc/docker/daemon.json 
  361  systemctl restart docker
  362  docker ps
  363  docker image
  364  docker images
  365  cri-dockerd
  366  whereis cri-dockerd
  367  cri-dockerd --help
  368  cri-dockerd --version
  369  cat /lib/systemd/system/cri-dockerd.service
  370  cat /lib/systemd/system/cri-docker.service
  371  apt-cache madison kubeadm
  372  apt-mark hold kubelet kubeadm kubectl docker.io
  373  systemctl status kubelet
  374  tail /var/log/syslog
  375  echo $K8S_RELEASE_VERSION
  376  kubectl --version
  377  kubelet --version
  378  K8S_RELEASE_VERSION=1.35.4
  379  kubeadm init --kubernetes-version=v${K8S_RELEASE_VERSION} --control-plane-endpoint kubeapi.zhong.org --pod-network-cidr 10.244.0.0/16 --service-cidr 10.96.0.0/12 --token-ttl=0 --image-repository registry.aliyuncs.com/google_containers --upload-certs --cri-socket=unix:///run/cri-dockerd.sock 
  380  systemctl status cri-dockerd
  381  systemctl status cri-docker
  382  kubeadm init --kubernetes-version=v${K8S_RELEASE_VERSION} --control-plane-endpoint kubeapi.zhong.org --pod-network-cidr 10.244.0.0/16 --service-cidr 10.96.0.0/12 --token-ttl=0 --image-repository registry.aliyuncs.com/google_containers --upload-certs --cri-socket=unix:///run/cri-docker.sock
  383  ls /var/run/cri-docker.sock
  384  ls /var/run/cri-dockerd.sock 
  385  ll /var/run/cri-dockerd.sock
  386  kubeadm init --kubernetes-version=v${K8S_RELEASE_VERSION} --control-plane-endpoint kubeapi.zhong.org --pod-network-cidr 10.244.0.0/16 --service-cidr 10.96.0.0/12 --token-ttl=0 --image-repository registry.aliyuncs.com/google_containers --upload-certs --cri-socket=unix:///var/run/cri-dockerd.sock
  387  ll /var/run/cri-dockerd.sock 
  388  kubeadm reset --cri-socket=unix:///var/run/cri-dockerd.sock -f
  389  kubeadm init   --kubernetes-version=v1.35.4   --control-plane-endpoint kubeapi.zhong.org   --pod-network-cidr 10.244.0.0/16   --service-cidr 10.96.0.0/12   --token-ttl=0   --image-repository registry.aliyuncs.com/google_containers   --upload-certs   --cri-socket=unix:///var/run/cri-dockerd.sock
  390  systemctl status cri-docker
  391  systemctl status cri-docker.socket
  392  systemctl stop cri-docker.service cri-docker.socket
  393  rm -f /var/run/cri-dockerd.sock
  394  systemctl start cri-docker.socket
  395  systemctl start cri-docker.service
  396  crictl --runtime-endpoint unix:///var/run/cri-dockerd.sock info
  397  kubeadm init   --kubernetes-version=v1.35.4   --control-plane-endpoint kubeapi.zhong.org   --pod-network-cidr 10.244.0.0/16   --service-cidr 10.96.0.0/12   --token-ttl=0   --image-repository registry.aliyuncs.com/google_containers   --upload-certs   --cri-socket=unix:///var/run/cri-dockerd.sock
  
```





## k8s init log

```sh
  0 ✓ 10:04:30 root@k8s-master1-101,172.17.0.1:~ # kubeadm init \
  --kubernetes-version=v1.35.4 \
  --control-plane-endpoint kubeapi.zhong.org \
  --pod-network-cidr 10.244.0.0/16 \
  --service-cidr 10.96.0.0/12 \
  --token-ttl=0 \
  --image-repository registry.aliyuncs.com/google_containers \
  --upload-certs \
  --cri-socket=unix:///var/run/cri-dockerd.sock
[init] Using Kubernetes version: v1.35.4
[preflight] Running pre-flight checks
[preflight] Pulling images required for setting up a Kubernetes cluster
[preflight] This might take a minute or two, depending on the speed of your internet connection
[preflight] You can also perform this action beforehand using 'kubeadm config images pull'
[certs] Using certificateDir folder "/etc/kubernetes/pki"
[certs] Generating "ca" certificate and key
[certs] Generating "apiserver" certificate and key
[certs] apiserver serving cert is signed for DNS names [k8s-master-101 kubeapi.zhong.org kubernetes kubernetes.default kubernetes.default.svc kubernetes.default.svc.cluster.local] and IPs [10.96.0.1 10.0.0.101]
[certs] Generating "apiserver-kubelet-client" certificate and key
[certs] Generating "front-proxy-ca" certificate and key
[certs] Generating "front-proxy-client" certificate and key
[certs] Generating "etcd/ca" certificate and key
[certs] Generating "etcd/server" certificate and key
[certs] etcd/server serving cert is signed for DNS names [k8s-master-101 localhost] and IPs [10.0.0.101 127.0.0.1 ::1]
[certs] Generating "etcd/peer" certificate and key
[certs] etcd/peer serving cert is signed for DNS names [k8s-master-101 localhost] and IPs [10.0.0.101 127.0.0.1 ::1]
[certs] Generating "etcd/healthcheck-client" certificate and key
[certs] Generating "apiserver-etcd-client" certificate and key
[certs] Generating "sa" key and public key
[kubeconfig] Using kubeconfig folder "/etc/kubernetes"
[kubeconfig] Writing "admin.conf" kubeconfig file
[kubeconfig] Writing "super-admin.conf" kubeconfig file
[kubeconfig] Writing "kubelet.conf" kubeconfig file
[kubeconfig] Writing "controller-manager.conf" kubeconfig file
[kubeconfig] Writing "scheduler.conf" kubeconfig file
[etcd] Creating static Pod manifest for local etcd in "/etc/kubernetes/manifests"
[control-plane] Using manifest folder "/etc/kubernetes/manifests"
[control-plane] Creating static Pod manifest for "kube-apiserver"
[control-plane] Creating static Pod manifest for "kube-controller-manager"
[control-plane] Creating static Pod manifest for "kube-scheduler"
[kubelet-start] Writing kubelet environment file with flags to file "/var/lib/kubelet/kubeadm-flags.env"
[kubelet-start] Writing kubelet configuration to file "/var/lib/kubelet/instance-config.yaml"
[patches] Applied patch of type "application/strategic-merge-patch+json" to target "kubeletconfiguration"
[kubelet-start] Writing kubelet configuration to file "/var/lib/kubelet/config.yaml"
[kubelet-start] Starting the kubelet
[wait-control-plane] Waiting for the kubelet to boot up the control plane as static Pods from directory "/etc/kubernetes/manifests"
[kubelet-check] Waiting for a healthy kubelet at http://127.0.0.1:10248/healthz. This can take up to 4m0s
[kubelet-check] The kubelet is healthy after 506.460737ms
[control-plane-check] Waiting for healthy control plane components. This can take up to 4m0s
[control-plane-check] Checking kube-apiserver at https://10.0.0.101:6443/livez
[control-plane-check] Checking kube-controller-manager at https://127.0.0.1:10257/healthz
[control-plane-check] Checking kube-scheduler at https://127.0.0.1:10259/livez
[control-plane-check] kube-controller-manager is healthy after 6.007399374s
[control-plane-check] kube-scheduler is healthy after 6.535431199s
[control-plane-check] kube-apiserver is healthy after 9.018145186s
[upload-config] Storing the configuration used in ConfigMap "kubeadm-config" in the "kube-system" Namespace
[kubelet] Creating a ConfigMap "kubelet-config" in namespace kube-system with the configuration for the kubelets in the cluster
[upload-certs] Storing the certificates in Secret "kubeadm-certs" in the "kube-system" Namespace
[upload-certs] Using certificate key:
0fd23879932514c7453c2a6a2b2d82743dfc960bff4acae6400ca41d33c86354
[mark-control-plane] Marking the node k8s-master-101 as control-plane by adding the labels: [node-role.kubernetes.io/control-plane node.kubernetes.io/exclude-from-external-load-balancers]
[mark-control-plane] Marking the node k8s-master-101 as control-plane by adding the taints [node-role.kubernetes.io/control-plane:NoSchedule]
[bootstrap-token] Using token: tv2yhk.9k9usqc5mfywy6cb
[bootstrap-token] Configuring bootstrap tokens, cluster-info ConfigMap, RBAC Roles
[bootstrap-token] Configured RBAC rules to allow Node Bootstrap tokens to get nodes
[bootstrap-token] Configured RBAC rules to allow Node Bootstrap tokens to post CSRs in order for nodes to get long term certificate credentials
[bootstrap-token] Configured RBAC rules to allow the csrapprover controller automatically approve CSRs from a Node Bootstrap Token
[bootstrap-token] Configured RBAC rules to allow certificate rotation for all node client certificates in the cluster
[bootstrap-token] Creating the "cluster-info" ConfigMap in the "kube-public" namespace
[kubelet-finalize] Updating "/etc/kubernetes/kubelet.conf" to point to a rotatable kubelet client certificate and key
[addons] Applied essential addon: CoreDNS
[addons] Applied essential addon: kube-proxy

Your Kubernetes control-plane has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

Alternatively, if you are the root user, you can run:

  export KUBECONFIG=/etc/kubernetes/admin.conf

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/

You can now join any number of control-plane nodes running the following command on each as root:

  kubeadm join kubeapi.zhong.org:6443 --token tv2yhk.9k9usqc5mfywy6cb \
	--discovery-token-ca-cert-hash sha256:1d8b7d7f82c64fd0e93d9624d195e8ccee22c4a598623aeeaf0fb5c360adbeb7 \
	--control-plane --certificate-key 0fd23879932514c7453c2a6a2b2d82743dfc960bff4acae6400ca41d33c86354 \
	--cri-socket=unix:///run/cri-dockerd.sock

Please note that the certificate-key gives access to cluster sensitive data, keep it secret!
As a safeguard, uploaded-certs will be deleted in two hours; If necessary, you can use
"kubeadm init phase upload-certs --upload-certs" to reload certs afterward.

Then you can join any number of worker nodes by running the following on each as root:

kubeadm join kubeapi.zhong.org:6443 --token tv2yhk.9k9usqc5mfywy6cb \
	--discovery-token-ca-cert-hash sha256:1d8b7d7f82c64fd0e93d9624d195e8ccee22c4a598623aeeaf0fb5c360adbeb7 \ --cri-socket=unix:///run/cri-dockerd.sock
```



## 提前拉kubeadm镜像

```sh
 kubeadm config images pull --image-repository registry.aliyuncs.com/google_containers --cri-socket=unix:///run/cri-dockerd.sock

```

