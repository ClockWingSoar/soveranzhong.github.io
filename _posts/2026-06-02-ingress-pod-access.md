---
layout: post
title: "Ingress流量转发深度解析：从入口到Pod的完整链路"
date: 2026-06-02 10:00:00 +0800
categories: [SRE, Kubernetes, 网络]
tags: [Ingress, Kubernetes, MetalLB, kube-proxy, CNI, 流量转发]
---

# Ingress流量转发深度解析：从入口到Pod的完整链路

## 情境(Situation)

在Kubernetes集群中，如何让外部用户通过Ingress访问到背后的Pod，是SRE工程师必须掌握的核心技能。然而，这条流量路径涉及到多个关键组件的协同工作：

- Ingress Controller作为七层反向代理
- ClusterIP Service作为服务发现层
- kube-proxy作为四层负载均衡器
- CNI插件作为Pod网络路由层
- MetalLB在裸金属环境中提供LoadBalancer能力

理解这些组件如何协作，是构建高可用生产环境的基础。

## 冲突(Conflict)

在实际工作中，SRE工程师经常面临以下困惑：

- **环境差异**：云厂商环境和裸金属环境的流量路径有何不同？
- **组件定位**：Ingress Controller、kube-proxy、CNI插件各自承担什么职责？
- **MetalLB作用**：裸金属环境中MetalLB到底解决了什么问题？
- **性能瓶颈**：流量经过多次转发，如何优化性能？
- **故障排查**：当流量无法到达Pod时，如何快速定位问题？

## 问题(Question)

如何全面理解从Ingress到Pod的完整流量转发链路，掌握云厂商环境和裸金属环境的差异，为生产环境选择合适的网络架构？

## 答案(Answer)

本文将从SRE视角详细解析Kubernetes流量转发链路，涵盖完整流量路径、核心组件职责、云厂商与裸金属环境对比、MetalLB工作原理以及生产环境最佳实践。核心方法论基于 [SRE面试题解析：通过Ingress访问背后的Pod是怎么实现的？]({% post_url 2026-04-15-sre-interview-questions %}#86-通过ingress访问背后的pod是怎么实现的有metallb和没有是两种情况)。

---

## 一、完整流量路径解析

### 1.1 三种环境的流量路径对比

**云厂商环境（有LoadBalancer）**

```
用户请求 → 云负载均衡器（CLB/ALB/NLB） → Ingress Controller → ClusterIP Service → kube-proxy → Pod
```

**裸金属环境（无MetalLB，只能用NodePort）**

```
用户请求 → 节点IP:NodePort → Ingress Controller → ClusterIP Service → kube-proxy → Pod
```

**裸金属环境（有MetalLB）**

```
用户请求 → MetalLB分配VIP → Ingress Controller（LoadBalancer Service暴露） → ClusterIP Service → kube-proxy → Pod
```

### 1.2 流量路径深度剖析

**阶段1：外部请求到Ingress Controller**

- **云厂商环境**：云负载均衡器接收用户请求，转发到Ingress Controller的NodePort或直接通过Pod网络
- **裸金属NodePort模式**：用户通过节点IP:NodePort访问，流量到达节点后由kube-proxy处理
- **裸金属MetalLB模式**：MetalLB分配VIP，通过ARP/BGP将VIP绑定到节点，流量直接到达Ingress Controller

**阶段2：Ingress Controller到ClusterIP Service**

Ingress Controller本质是一个反向代理（通常是Nginx或Envoy）：

```yaml
# Ingress资源定义
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app-ingress
spec:
  ingressClassName: nginx
  rules:
  - host: app.example.com
    http:
      paths:
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: api-service
            port:
              number: 80
```

Ingress Controller监听Ingress资源变化，动态生成路由配置：

```nginx
# Nginx Ingress生成的配置片段
server {
    server_name app.example.com;
    location /api {
        proxy_pass http://api-service.default.svc.cluster.local:80;
    }
}
```

**阶段3：ClusterIP Service到Pod（kube-proxy）**

kube-proxy在每个节点上运行，维护网络通信规则：

```bash
# 查看kube-proxy模式
kubectl get configmap kube-proxy -n kube-system -o yaml | grep mode

# iptables模式示例
iptables -t nat -L KUBE-SVC-XXX -v

# IPVS模式示例
ipvsadm -L -n | grep SERVICE
```

关键转换：Service VIP → Pod IP的DNAT操作

```bash
# iptables NAT规则示意
# PREROUTING → KUBE-SVC-XXX → KUBE-SEP-XXX (DNAT to Pod IP)
# POSTROUTING → MASQUERADE (Pod IP → Node IP)
```

**阶段4：Pod IP路由（CNI插件）**

CNI插件负责节点间的Pod网络通信：

```bash
# 同一节点：通过网桥/veth pair直接转发
ip link show cni0

# 跨节点：根据路由表或隧道封装
# 直接路由模式（Calico BGP）
ip route show

# 隧道模式（VXLAN）
ip link show vxlan0
```

---

## 二、核心组件职责详解

### 2.1 Ingress Controller

**核心职责**：七层反向代理，监听Ingress资源，生成路由配置

**工作流程**：

1. 监听Kubernetes API的Ingress资源变化
2. 根据Ingress规则生成反向代理配置
3. 接收外部HTTP/HTTPS请求
4. 根据域名+路径匹配规则转发到对应Service

**主流实现**：

| 实现 | 特点 | 适用场景 |
|:------|:------|:------|
| **NGINX Ingress** | 功能丰富，社区活跃 | 通用场景 |
| **Envoy** | 高性能，xDS协议 | 服务网格集成 |
| **Traefik** | 自动配置，支持CRD | 动态服务发现 |
| **Cilium Ingress** | eBPF驱动 | 高性能需求 |

### 2.2 kube-proxy

**核心职责**：四层负载均衡，维护Service到Pod的连接

**工作模式**：

**iptables模式**（默认）

```bash
# 查看iptables规则链
iptables -t nat -L -n | grep KUBE

# 规则示例
-KUBE-SVC-XXX -> KUBE-SEP-XXX (DNAT)
-KUBE-MARK-MASQ (MASQUERADE)
```

**IPVS模式**（推荐生产使用）

```bash
# 启用IPVS模式
kubectl edit configmap kube-proxy -n kube-system
# 设置 mode: "ipvs"

# 查看IPVS虚拟服务器
ipvsadm -L -n

# 示例输出
TCP  10.0.0.100:80 rr
  -> 10.244.1.10:80         Weight=1
  -> 10.244.1.11:80         Weight=1
```

**IPVS支持多种负载均衡算法**：

| 算法 | 说明 | 适用场景 |
|:------|:------|:------|
| **rr** | 轮询 | 默认，均匀分布 |
| **wrr** | 加权轮询 | 异构集群 |
| **lc** | 最少连接 | 长连接场景 |
| **sh** | 源哈希 | 会话保持 |

### 2.3 CNI插件

**核心职责**：配置节点网络路由，实现Pod间通信

**直接路由模式**（Calico BGP、Cilium）

```bash
# 节点路由表示例
# 目标Pod网段 10.244.1.0/24 通过 192.168.1.10 转发
10.244.1.0/24 via 192.168.1.10 dev eth0
```

**隧道模式**（Flannel VXLAN、Calico IPIP）

```bash
# VXLAN隧道接口
ip link show vxlan0

# FDB表项
bridge fdb show | grep vxlan
```

### 2.4 MetalLB

**核心职责**：在裸金属环境提供LoadBalancer能力

**解决的问题**：

- 云厂商环境：LoadBalancer由云平台自动提供
- 裸金属环境：Kubernetes原生不支持LoadBalancer，需要MetalLB补充

**工作流程**：

1. 监听LoadBalancer类型Service的创建
2. 从预分配的IP池中分配External IP
3. 将IP绑定到节点（Layer2模式）或宣告到路由器（BGP模式）
4. Service的status.loadBalancer.ingress字段更新为分配的IP

---

## 三、云厂商 vs 裸金属环境对比

### 3.1 架构对比

| 维度 | 云厂商环境 | 裸金属无MetalLB | 裸金属有MetalLB |
|:------|:------|:------|:------|
| **LoadBalancer** | 云平台自动提供 | 不可用 | MetalLB提供 |
| **访问入口** | 云负载均衡器VIP | 节点IP:NodePort | 固定VIP |
| **IP稳定性** | 高（由云平台管理） | 低（依赖节点IP） | 高（VIP固定） |
| **端口限制** | 无 | 30000-32767 | 无 |
| **负载均衡** | 云平台级别 | 基础DNS轮询 | 可配置策略 |
| **高可用** | 云平台保障 | 节点故障需改DNS | VIP漂移保障 |

### 3.2 成本对比

**云厂商环境**

- 云负载均衡器费用（按流量或实例计费）
- EKS/AKS/GKE等托管服务费用
- 高可用自动保障

**裸金属无MetalLB**

- 最低成本，仅NodePort
- 但运维复杂，故障切换慢
- 不适合生产环境

**裸金属有MetalLB**

- 开源免费，无额外软件费用
- 需要自行保障硬件高可用
- 适合预算有限的团队

---

## 四、MetalLB深度解析

### 4.1 Layer2模式原理

**工作原理**：

1. MetalLB为Service分配IP后，将该IP绑定到某个节点
2. Speaker组件通过ARP（IPv4）或NDP（IPv6）响应ARP请求
3. 外部客户端发送ARP请求获取VIP对应的MAC地址
4. 交换机将流量路由到响应节点的MAC地址
5. 节点上的Ingress Controller接收流量

**配置示例**：

```yaml
# 安装MetalLB
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.5/config/manifests/metallb-native.yaml

# 创建IP池
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: default-pool
  namespace: metallb-system
spec:
  addresses:
  - 192.168.1.240-192.168.1.250
  - 192.168.1.10/32
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: l2advertisement
  namespace: metallb-system
spec:
  ipAddressPools:
  - default-pool
```

**优缺点**：

| 优点 | 缺点 |
|:------|:------|
| 配置简单 | VIP绑定到单一节点 |
| 无需网络设备配合 | 节点故障时VIP需要漂移 |
| 广泛兼容 | 带宽受单节点限制 |

### 4.2 BGP模式原理

**工作原理**：

1. 各节点与路由器建立BGP会话
2. MetalLB Speaker组件在节点间分发路由
3. 路由器收到VIP流量后，根据BGP路由表分发到各节点
4. 实现真正的多节点负载均衡

**配置示例**：

```yaml
# 创建BGP Peer
apiVersion: metallb.io/v1beta1
kind: BGPPeer
metadata:
  name: bgp-peer
  namespace: metallb-system
spec:
  peerAddress: 192.168.1.1        # 路由器IP
  peerASN: 65001                   # 路由器AS号
  routerID: 192.168.1.10          # 本节点IP
---
# 更新IP池配置
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: bgp-pool
  namespace: metallb-system
spec:
  addresses:
  - 192.168.1.100-192.168.1.150
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: bgp-advertisement
  namespace: metallb-system
spec:
  ipAddressPools:
  - bgp-pool
  aggregationLength: 32
  communities:
  - 65535:1
```

**路由器配置（Cisco示例）**：

```router
router bgp 65001
 neighbor 192.168.1.10 remote-as 65002
 neighbor 192.168.1.11 remote-as 65002
 !
 address-family ipv4
  network 192.168.1.100/28
  neighbor 192.168.1.10 activate
  neighbor 192.168.1.11 activate
```

**优缺点**：

| 优点 | 缺点 |
|:------|:------|
| 多节点真正负载均衡 | 需要BGP路由器支持 |
| 无单点瓶颈 | 配置复杂 |
| 带宽利用率高 | 需要网络团队配合 |

### 4.3 Layer2 vs BGP模式对比

| 维度 | Layer2模式 | BGP模式 |
|:------|:------|:------|
| **配置复杂度** | 低 | 高 |
| **负载均衡** | 单节点 | 多节点 |
| **网络要求** | 二层网络互通 | 支持BGP的路由器 |
| **故障恢复** | 秒级VIP漂移 | 毫秒级BGP收敛 |
| **适用场景** | 小规模集群 | 大规模生产环境 |

---

## 五、生产环境Ingress高可用部署

### 5.1 Ingress Controller高可用架构

```yaml
# Nginx Ingress高可用部署
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-ingress-controller
  namespace: ingress-nginx
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx-ingress
  template:
    metadata:
      labels:
        app: nginx-ingress
    spec:
      serviceAccountName: nginx-ingress-serviceaccount
      containers:
      - name: nginx-ingress-controller
        image: registry.k8s.io/ingress-nginx/controller:v1.11.0
        args:
          - /nginx-ingress-controller
          - --election-id=ingress-controller-leader
          - --controller-class=k8s.io/ingress-nginx
          - --ingress-class=nginx
        env:
          - name: POD_NAME
            valueFrom:
              fieldRef:
                fieldPath: metadata.name
          - name: POD_NAMESPACE
            valueFrom:
              fieldRef:
                fieldPath: metadata.namespace
        resources:
          requests:
            cpu: 100m
            memory: 90Mi
          limits:
            cpu: 1000m
            memory: 1Gi
```

### 5.2 MetalLB+Ingress Controller组合

```yaml
# Ingress Controller使用LoadBalancer类型Service暴露
apiVersion: v1
kind: Service
metadata:
  name: ingress-nginx-controller
  namespace: ingress-nginx
spec:
  type: LoadBalancer
  selector:
    app: nginx-ingress
  ports:
  - name: http
    port: 80
    targetPort: 80
    protocol: TCP
  - name: https
    port: 443
    targetPort: 443
    protocol: TCP
```

---

## 六、最佳实践总结

### 6.1 架构选型建议

**小型团队/开发测试环境**

- 使用NodePort模式
- 配合DNS轮询实现简单负载均衡
- 降低成本，快速起步

**中型团队/准生产环境**

- 使用MetalLB Layer2模式
- Ingress Controller多副本部署
- 配置健康检查和自动故障转移

**大型团队/生产环境**

- 使用MetalLB BGP模式
- 配合云厂商提供的高可用网络
- 启用Ingress Controller全功能特性

### 6.2 性能优化建议

**kube-proxy优化**

```bash
# 切换到IPVS模式
kubectl edit configmap kube-proxy -n kube-system

# 配置示例
apiVersion: v1
kind: ConfigMap
metadata:
  name: kube-proxy
  namespace: kube-system
data:
  config.conf: |
    mode: "ipvs"
    ipvs:
      scheduler: "wrr"
      excludeCIDRs: ["10.0.0.0/8"]
```

**CNI插件优化**

| 插件 | 推荐模式 | 原因 |
|:------|:------|:------|
| **Calico** | BGP直接路由 | 性能最高，无隧道开销 |
| **Cilium** | eBPF直接路由 | 内核级加速 |
| **Flannel** | host-gw直接路由 | 性能优于VXLAN |

**Ingress Controller优化**

```yaml
# Nginx Ingress性能配置
apiVersion: networking.k8s.io/v1
kind: IngressClass
metadata:
  name: nginx
spec:
  controller: k8s.io/ingress-nginx
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: ingress-nginx-controller
  namespace: ingress-nginx
data:
  use-forwarded-headers: "true"
  compute-full-forwarded-for: "true"
  proxy-body-size: "50m"
  keep-alive: "75"
  upstream-keepalive-connections: "1000"
```

### 6.3 监控告警配置

**关键监控指标**

| 指标 | 说明 | 告警阈值 |
|:------|:------|:------|
| **Ingress Controller可用性** | Pod是否Running | 副本数小于预期 |
| **后端服务可用性** | Endpoint数量 | 小于预期50% |
| **请求延迟P99** | 请求耗时 | 大于500ms |
| **5xx错误率** | 错误比例 | 大于1% |
| **MetalLB VIP状态** | IP分配状态 | pending超过5分钟 |

**Prometheus监控配置**

```yaml
# Ingress Controller指标暴露
apiVersion: v1
kind: Service
metadata:
  name: ingress-nginx-controller-metrics
  namespace: ingress-nginx
spec:
  ports:
  - name: metrics
    port: 10254
    targetPort: metrics
---
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: ingress-nginx
  namespace: monitoring
spec:
  selector:
    matchLabels:
      app: nginx-ingress
  endpoints:
  - port: metrics
    path: /metrics
```

### 6.4 故障排查指南

**流量无法到达Pod的排查步骤**

```bash
# 1. 检查Ingress资源状态
kubectl get ingress -A
kubectl describe ingress app-ingress

# 2. 检查Ingress Controller状态
kubectl get pods -n ingress-nginx -l app=nginx-ingress
kubectl logs -n ingress-nginx -l app=nginx-ingress --tail=100

# 3. 检查Service和Endpoints
kubectl get svc -A | grep app
kubectl get endpoints app-service

# 4. 检查Pod状态
kubectl get pods -l app=app
kubectl describe pod app-pod

# 5. 检查kube-proxy状态
kubectl get pods -n kube-system -l k8s-app=kube-proxy
kubectl logs -n kube-system -l k8s-app=kube-proxy --tail=100

# 6. 检查MetalLB状态（裸金属环境）
kubectl get pods -n metallb-system
kubectl logs -n metallb-system -l component=speaker --tail=100
kubectl get ipaddresspool -A
kubectl get l2advertisement -A

# 7. 检查CNI插件状态
ip link show cni0
ip route show
bridge fdb show
```

**常见问题与解决方案**

| 问题 | 原因 | 解决方案 |
|:------|:------|:------|
| **Ingress Controller所有Pod为Pending** | MetalLB未安装或IP池配置错误 | 安装MetalLB并配置IP池 |
| **流量无法到达后端Pod** | Service标签不匹配 | 检查selector配置 |
| **部分请求超时** | Pod健康检查失败 | 检查 readiness/liveness probe |
| **VIP无法ping通** | Layer2宣告失败 | 检查网络配置和交换机设置 |
| **跨节点通信失败** | CNI路由问题 | 检查节点路由表和CNI配置 |

---

## 七、安全配置建议

### 7.1 网络策略配置

```yaml
# 限制Ingress Controller访问后端Pod
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: ingress-to-app
  namespace: default
spec:
  podSelector:
    matchLabels:
      app: app
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: ingress-nginx
    ports:
    - protocol: TCP
      port: 8080
```

### 7.2 TLS配置

```yaml
# 使用cert-manager自动管理证书
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: admin@example.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app-ingress-tls
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - app.example.com
    secretName: app-tls
  rules:
  - host: app.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: app-service
            port:
              number: 80
```

---

## 总结

Ingress访问Pod的完整链路涉及多个核心组件的协同工作：

**核心要点总结**：

1. **流量路径**：外部请求 → Ingress Controller → ClusterIP Service → kube-proxy → CNI → Pod
2. **组件职责**：Ingress Controller（七层路由）、kube-proxy（四层负载均衡）、CNI（Pod网络路由）、MetalLB（LoadBalancer实现）
3. **环境差异**：云厂商环境自动提供LoadBalancer，裸金属环境需要MetalLB
4. **MetalLB两种模式**：Layer2（ARP/NDP，单节点）和BGP（多节点真正负载均衡）
5. **生产环境推荐**：MetalLB BGP模式 + Ingress Controller高可用 + Cilium/Calico BGP模式

理解这条流量链路，是SRE工程师掌握Kubernetes网络的关键。建议在实际环境中多实践故障排查，积累经验。

> **延伸学习**：更多面试相关的Ingress流量转发知识，请参考 [SRE面试题解析：通过Ingress访问背后的Pod是怎么实现的？]({% post_url 2026-04-15-sre-interview-questions %}#86-通过ingress访问背后的pod是怎么实现的有metallb和没有是两种情况)。

---

## 参考资料

- [Kubernetes Ingress官方文档](https://kubernetes.io/zh-cn/docs/concepts/services-networking/ingress/)
- [MetalLB官方文档](https://metallb.io/)
- [kube-proxy文档](https://kubernetes.io/zh-cn/docs/reference/command-line-tools-reference/kube-proxy/)
- [CNI插件文档](https://www.cni.dev/)
- [NGINX Ingress Controller文档](https://kubernetes.github.io/ingress-nginx/)
- [Envoy代理文档](https://www.envoyproxy.io/)
- [Calico网络文档](https://docs.tigera.io/calico/latest/)
- [Cilium文档](https://docs.cilium.io/)
- [IPVS负载均衡](https://kubernetes.io/zh-cn/docs/reference/networking/virtual-ips/)
- [Kubernetes网络策略](https://kubernetes.io/zh-cn/docs/concepts/services-networking/network-policies/)
