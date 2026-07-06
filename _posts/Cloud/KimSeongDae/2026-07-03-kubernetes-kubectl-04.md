---
title: kubectl 기초 실습 정리
date: 2026-07-03
categories:
  - cloud
comments: true
tags:
  - kubernetes
---
# Kubernetes 설치 및 실습 정리

**환경**: Rocky Linux 9, VMware Workstation (Full Clone)
**노드 구성**
| 역할 | 호스트명 | IP |
|---|---|---|
| Control Plane | k8s-master | 10.0.0.11 |
| Worker 1 | k8s-worker1 | 10.0.0.12 |
| Worker 2 | k8s-worker2 | 10.0.0.13 |

**구성 요소**: kubeadm, containerd, Calico(CNI), MetalLB(LoadBalancer)
**Kubernetes 버전**: v1.35.6

---

## 1. 사전 준비 (전체 노드 공통)

### 1-1. 호스트명 설정
```bash
# 마스터
sudo hostnamectl set-hostname k8s-master
# 워커1
sudo hostnamectl set-hostname k8s-worker1
# 워커2
sudo hostnamectl set-hostname k8s-worker2
```

### 1-2. /etc/hosts 등록 (전 노드 동일)
```bash
sudo tee -a /etc/hosts <<EOF
10.0.0.11 k8s-master
10.0.0.12 k8s-worker1
10.0.0.13 k8s-worker2
EOF
```

### 1-3. swap 비활성화
```bash
sudo swapoff -a
sudo sed -i '/swap/d' /etc/fstab
```

### 1-4. SELinux permissive
```bash
sudo setenforce 0
sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
```

### 1-5. firewalld 비활성화 (테스트 환경 기준)
```bash
sudo systemctl disable --now firewalld
```

### 1-6. 커널 모듈 및 sysctl 설정
```bash
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
sudo modprobe overlay
sudo modprobe br_netfilter

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF
sudo sysctl --system
```

---

## 2. containerd 설치 (전체 노드 공통)

> ⚠️ Rocky Linux 9 기본 저장소에는 `containerd` 패키지가 없어 Docker CE 저장소가 필요함 (`No match for argument: containerd` 에러 발생했던 부분)

```bash
sudo dnf install -y dnf-plugins-core
sudo dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo dnf install -y containerd.io

sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
sudo systemctl restart containerd
sudo systemctl enable containerd
```

**확인**
```bash
grep SystemdCgroup /etc/containerd/config.toml   # true 여야 정상
systemctl status containerd --no-pager           # active (running)
```

---

## 3. kubeadm / kubelet / kubectl 설치 (전체 노드 공통)

```bash
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.35/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.35/rpm/repodata/repomd.xml.key
exclude=kubelet kubeadm kubectl cri-tools kubernetes-cni
EOF

sudo dnf install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
sudo systemctl enable --now kubelet
```

> 📝 이 시점에서 kubelet은 `activating (auto-restart)` 상태로 계속 재시작을 반복하는데, `kubeadm init`(마스터) / `kubeadm join`(워커) 전까지는 **정상적인 현상**임 (클러스터 설정 파일이 아직 없기 때문).

---

## 4. 마스터 노드 초기화

```bash
sudo kubeadm init --pod-network-cidr=192.168.0.0/16 --apiserver-advertise-address=10.0.0.11
```

> 노드 IP 대역(10.0.0.0/24)과 파드 네트워크 대역(192.168.0.0/16)이 겹치지 않으면 그대로 사용 가능. Calico 매니페스트 기본값과도 일치.

**kubectl 설정**
```bash
export KUBECONFIG=/etc/kubernetes/admin.conf
echo "export KUBECONFIG=/etc/kubernetes/admin.conf" >> ~/.bashrc   # 영구 적용
```

**join 명령 (출력 결과 저장 - 워커 조인 시 사용)**
```bash
kubeadm join 10.0.0.11:6443 --token <토큰> \
    --discovery-token-ca-cert-hash sha256:<해시>
```
> 토큰은 24시간 후 만료. 만료 시 마스터에서 재발급:
> ```bash
> kubeadm token create --print-join-command
> ```

---

## 5. CNI 설치 (Calico)

```bash
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.30.3/manifests/calico.yaml
```

**확인**
```bash
kubectl get pods -n kube-system
kubectl get nodes   # k8s-master가 Ready로 전환
```

---

## 6. 워커 노드 조인

워커 2대(9-2, 9-3)에서 **1~3단계(사전준비 + containerd + kubeadm 설치)**를 동일하게 진행한 뒤:

```bash
sudo kubeadm join 10.0.0.11:6443 --token <토큰> \
    --discovery-token-ca-cert-hash sha256:<해시>
```

**마스터에서 최종 확인**
```bash
kubectl get nodes
```
```
NAME          STATUS   ROLES           AGE   VERSION
k8s-master    Ready    control-plane   ...   v1.35.6
k8s-worker1   Ready    <none>          ...   v1.35.6
k8s-worker2   Ready    <none>          ...   v1.35.6
```

세 노드 모두 `Ready` → **3노드 클러스터 구축 완료**

> ⚠️ 트러블슈팅: worker1에서 calico-node 파드가 `Init:0/3`에서 수 분간 멈췄던 적 있음 (이미지 pull 지연). 결국 자동으로 해소되어 Running으로 전환됨. 원인 미상 시 확인 명령:
> ```bash
> kubectl describe pod <calico-node-pod> -n kube-system
> sudo crictl pull docker.io/calico/cni:v3.30.3   # 해당 노드에서
> ```

---

## 7. httpd Deployment 실습

### httpd-deployment.yaml
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: httpd-deploy
  labels:
    app: httpd
spec:
  replicas: 5
  selector:
    matchLabels:
      app: httpd
  template:
    metadata:
      labels:
        app: httpd
    spec:
      containers:
      - name: h1
        image: httpd:latest
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: httpd-service
spec:
  type: NodePort
  selector:
    app: httpd
  ports:
    - port: 80
      targetPort: 80
      nodePort: 30080
```

```bash
kubectl apply -f httpd-deployment.yaml
kubectl get pod,rs,deploy -o wide
```

**접속 테스트**: `http://10.0.0.11:30080` → Apache 기본 페이지("It works!") 확인

---

## 8. MySQL Deployment 실습

### mysql-deployment.yaml
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: dep-mysql
  labels:
    app: mysql
    env: prod
spec:
  replicas: 1
  selector:
    matchLabels:
      tem: mysql
  template:
    metadata:
      labels:
        tem: mysql
    spec:
      containers:
      - name: m1
        image: mysql:8.0
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 3306
        env:
        - name: MYSQL_ROOT_PASSWORD
          value: 'It12345!'
        - name: MYSQL_DATABASE
          value: 'word'
        - name: MYSQL_USER
          value: 'jhjang'
        - name: MYSQL_PASSWORD
          value: 'It12345!'
---
apiVersion: v1
kind: Service
metadata:
  name: mysql-service
spec:
  type: NodePort
  selector:
    tem: mysql
  ports:
    - port: 3306
      targetPort: 3306
      nodePort: 30036
```

```bash
kubectl apply -f mysql-deployment.yaml
kubectl logs -l tem=mysql   # "ready for connections" 확인
```

---

## 9. WordPress Deployment 실습

### wordpress-deployment.yaml
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: dep-word
  labels:
    app: wordpress
    env: prod
spec:
  replicas: 3
  selector:
    matchLabels:
      tem: word
  template:
    metadata:
      labels:
        tem: word
    spec:
      containers:
      - name: w1
        image: wordpress
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 80
        env:
        - name: WORDPRESS_DB_HOST
          value: mysql-service:3306
        - name: WORDPRESS_DB_NAME
          value: 'word'
        - name: WORDPRESS_DB_USER
          value: 'jhjang'
        - name: WORDPRESS_DB_PASSWORD
          value: 'It12345!'
---
apiVersion: v1
kind: Service
metadata:
  name: wordpress-service
spec:
  type: NodePort
  selector:
    tem: word
  ports:
    - port: 80
      targetPort: 80
      nodePort: 30880
```

```bash
kubectl apply -f wordpress-deployment.yaml
```

**접속**: `http://10.0.0.11:30880`

### 트러블슈팅 기록
1. **Service selector 불일치**: Deployment 라벨은 `tem=word`, Service selector가 `tem=wordpress`로 달라서 트래픽 라우팅 안 됨 → selector를 `tem: word`로 일치시켜 해결
2. **DB 연결 실패 (`Error establishing a database connection`)**:
   - 원인: `WORDPRESS_DB_HOST`에 파드 IP를 직접 넣었던 실수 → 파드 IP는 재시작마다 바뀌므로 반드시 **Service 이름**(`mysql-service:3306`)으로 지정해야 함
   - 확인 명령:
     ```bash
     kubectl logs -l tem=mysql --tail=50
     kubectl exec -it <wordpress-pod> -- bash
     mysql -h mysql-service -u jhjang -p word
     ```
   - `ERROR 2005 (HY000): Unknown server host 'mysql-service'` 발생 시 → DNS(CoreDNS) 또는 Service/Endpoints 문제
     ```bash
     kubectl get endpoints mysql-service   # 비어있으면 selector 불일치
     kubectl get pods -n kube-system -l k8s-app=kube-dns
     nslookup kubernetes.default   # 파드 내부에서 DNS 자체 동작 확인
     ```

---

## 10. 단일 Pod 실습 (nginx)

### nginx-pod.yaml
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx
  labels:
    app: nginx
    env: test
spec:
  containers:
  - name: n1
    image: nginx
    imagePullPolicy: IfNotPresent
    ports:
    - containerPort: 80
```

```bash
kubectl apply -f nginx-pod.yaml
kubectl get pod nginx -o wide
```

> 💡 `--dry-run=server` 옵션은 실제 생성 없이 문법/서버 검증만 수행 (`created (server dry run)` 메시지 → 실제 생성 아님). 실제 적용은 옵션 없이 `kubectl apply -f` 실행.

---

## 11. MetalLB로 LoadBalancer 구성

### 11-1. MetalLB 설치
```bash
kubectl apply -f metallb-frr-k8s.yaml
kubectl get pods -n metallb-system
```

### 11-2. IPAddressPool (ippool.yml)
```yaml
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: jhjang-pool
  namespace: metallb-system
spec:
  addresses:
  - 10.0.0.51-10.0.0.60
```
```bash
kubectl apply -f ippool.yml
kubectl get ipaddresspool -n metallb-system
```

### 11-3. L2Advertisement (adv.yml)
```yaml
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: jhjang-l2
  namespace: metallb-system
spec:
  ipAddressPools:
  - jhjang-pool
```
```bash
kubectl apply -f adv.yml
kubectl get l2advertisement -n metallb-system
```

### 11-4. nginx Deployment (LoadBalancer 대상)
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: dep-nginx
  labels:
    app: nginx
spec:
  replicas: 2
  selector:
    matchLabels:
      tem: nginx
  template:
    metadata:
      labels:
        tem: nginx
    spec:
      containers:
      - name: n1
        image: nginx:latest
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 80
```

### 11-5. LoadBalancer Service (lb.yml)
```yaml
apiVersion: v1
kind: Service
metadata:
  name: svc-lbng
spec:
  type: LoadBalancer
  selector:
    tem: nginx
  ports:
    - port: 80
      targetPort: 80
```

```bash
kubectl apply -f ngdep.yml
kubectl apply -f lb.yml
kubectl get svc svc-lbng
```

**결과 예시**
```
NAME        TYPE           CLUSTER-IP       EXTERNAL-IP   PORT(S)
svc-lbng    LoadBalancer   10.101.148.226   10.0.0.51     80:30135/TCP
```

**테스트**
```bash
kubectl get endpoints svc-lbng   # 파드 IP:포트 매핑 확인
curl http://10.0.0.51
```

---

## 12. 자주 겪은 문제 & 원인 정리 (요약)

| 증상 | 원인 | 해결 |
|---|---|---|
| `No match for argument: containerd` | Rocky 9 기본 저장소에 containerd 없음 | Docker CE 저장소 추가 후 `containerd.io` 설치 |
| kubelet `activating (auto-restart)` | `kubeadm init`/`join` 전이라 설정파일 없음 | init/join 완료하면 자동 해결 (정상 현상) |
| `dial tcp [::1]:8080: connection refused` | `KUBECONFIG` 미설정 (워커에서 kubectl 실행 or 세션 초기화) | `export KUBECONFIG=/etc/kubernetes/admin.conf`, `.bashrc` 등록 + 반드시 마스터에서 실행 |
| `error validating data: apiVersion not set` | YAML 파일 손상/누락, vi 자동 들여쓰기 꼬임 | 파일 전체 삭제 후 재작성 (`gg`→`dG`), `:set paste` 사용 |
| `unknown field "spec.selector.template"` 등 필드 오류 | YAML 들여쓰기 오류 (template이 selector 하위로 잘못 들어감) | `template`을 `spec` 바로 아래, `selector`와 동일 레벨로 위치 |
| Service 트래픽 라우팅 안 됨 | Deployment 라벨과 Service selector 불일치 | 양쪽 라벨 값을 동일하게 통일 |
| WordPress DB 연결 실패 | `WORDPRESS_DB_HOST`에 파드 IP 직접 사용 | Service 이름(`mysql-service:3306`)으로 변경 |
| `kubectl apply --dry-run=server` 후 리소스가 안 보임 | dry-run은 실제 생성 안 함(검증만) | dry-run 옵션 없이 재실행 |

---

## 13. 스냅샷 관리 참고

- Full Clone 후 스냅샷을 과도하게(9개 이상) 쌓아두면 Revert 시 디스크 잠금(`.lck`) 및 체인 손상 문제 발생 가능
- 의미 있는 지점(예: "클러스터 구성 완료", "앱 배포 완료")마다만 스냅샷을 최소한으로 유지 권장
- 3노드 클러스터는 마스터/워커 상태가 서로 연결되어 있으므로, **스냅샷은 반드시 전체 노드에 동시에** 찍을 것

---

*작성일: 2026-07-03*
