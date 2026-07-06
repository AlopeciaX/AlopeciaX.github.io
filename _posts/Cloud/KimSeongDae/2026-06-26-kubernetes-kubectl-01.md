---
title: kubectl 기초 실습 정리
date: 2026-06-26
categories:
  - cloud
comments: true
tags:
  - kubernetes
---
---
## 개요

kubectl은 Kubernetes 클러스터를 제어하는 CLI 도구다. 이 글은 노드/파드/서비스/네임스페이스 기본 조작과 YAML로 리소스를 생성하는 실습 내용을 정리한다.

---

## 서버 구성

- **rocky9-1**: Kubernetes Master
- **rocky9-2**: Worker Node1
- **rocky9-3**: Worker Node2
- **rocky9-docker**: Docker 전용 서버 (이미지 수집 및 전송)

---

## 주요 개념

- **kubectl**: Kubernetes object를 실행·관리하는 CLI. [kubectl cheat sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/) 참고
- **Calico**: 파드 간 네트워크를 구성하는 CNI 플러그인
- **Namespace**: 하나의 클러스터 안에서 리소스 그룹을 논리적으로 분리하는 단위. 팀·환경별로 나눠 사용 가능
- **YAML 구조**: `키: 값` 형식. 주요 키는 `apiVersion`, `kind`, `metadata`(name, labels, namespace), `spec`

---

## STEP 1. 클러스터 상태 확인

```bash
kubectl get nodes          # 노드 목록
kubectl get namespaces     # 네임스페이스 목록 (= kubectl get ns)
kubectl get pods           # 기본 네임스페이스 파드 목록
kubectl get pods -A        # 전체 네임스페이스 파드 목록
kubectl api-resources      # 리소스 종류 확인 (shortname, kind 포함)
```

---

## STEP 2. 파드 실행 및 확인

```bash
# 파드 생성
kubectl run app-nginx --image nginx --port 80

# 상태 확인
kubectl get pods
kubectl get pods app-nginx
kubectl get pods app-nginx -o wide    # IP 등 상세 정보 포함

# 상세 정보 / 로그
kubectl describe pods app-nginx
kubectl logs app-nginx
```

`-o wide`로 확인한 IP로 `curl` 테스트가 가능하다. 다만 클러스터 내부 IP이므로 노드 안에서만 접근된다.

---

## STEP 3. 서비스(NodePort) 노출

```bash
kubectl expose pod app-nginx --type NodePort
kubectl get services
kubectl delete service app-nginx
```

NodePort를 사용하면 클러스터 외부에서 `노드IP:포트`로 파드에 접근할 수 있다.

---

## STEP 4. 네임스페이스 관리

```bash
# 조회
kubectl get namespace          # = kubectl get ns

# 특정 네임스페이스 파드 조회
kubectl get pods --namespace kube-system
kubectl get pods --namespace kube-public

# 생성 / 삭제
kubectl create namespace 1team
kubectl delete ns 1team

# 네임스페이스 지정하여 파드 실행
kubectl run app-nginx --image nginx --port 80 --namespace 1team

# 파드 삭제 (네임스페이스 명시 필수)
kubectl delete po app-nginx --namespace 1team
```

`default` 네임스페이스는 삭제할 수 없다.

---

## STEP 5. YAML로 네임스페이스 생성

```bash
mkdir /pod && cd /pod
vi ns1.yml
```

**ns1.yml**

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: 1team
  labels:
    env: study
```

```bash
kubectl apply -f ns1.yml      # 생성
kubectl get ns --show-labels  # 라벨 포함 확인
kubectl delete -f ns1.yml     # 삭제
```

---

## STEP 6. Docker 이미지 준비 및 노드 배포

클러스터 노드가 인터넷에서 이미지를 직접 pull하기 어려운 환경이므로, rocky9-docker에서 이미지를 받아 tar로 묶은 뒤 워커 노드로 전송한다.

**6-1. Docker 설치 (rocky9-docker)**

```bash
dnf -y install dnf-plugins-core
dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
dnf -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
systemctl enable --now docker
```

**6-2. 이미지 pull (rocky9-docker)**

```bash
docker pull nginx
docker pull httpd
docker pull alpine
docker pull busybox
docker pull rockylinux/rockylinux
docker pull wordpress
docker pull mysql:8.0

docker images    # 목록 확인
```

**6-3. tar로 묶어서 워커 노드로 전송 (rocky9-docker)**

```bash
docker save -o all.tar alpine busybox httpd nginx rockylinux/rockylinux wordpress mysql:8.0

scp all.tar root@10.0.0.12:/root/    # → rocky9-2 (node1)
scp all.tar root@10.0.0.13:/root/    # → rocky9-3 (node2)
```

**6-4. containerd로 import (rocky9-2, rocky9-3 각각 실행)**

```bash
ctr -n k8s.io image import all.tar
# "saved" 메시지가 뜨면 정상

crictl -r unix:///run/containerd/containerd.sock image ls    # import 확인
```

---

## STEP 7. kubeconfig 설정 (워커 노드)

워커 노드에서 kubectl을 사용하려면 kubeconfig를 직접 복사해야 한다. 없으면 `localhost:8080 connection refused` 에러가 발생한다.

```bash
ls ~/.kube/config                              # 파일 존재 여부 확인

mkdir -p ~/.kube
cp /etc/kubernetes/admin.conf ~/.kube/config
chown $(id -u):$(id -g) ~/.kube/config

kubectl get nodes                              # 연결 확인
```

---

## STEP 8. YAML로 파드 생성 (1team 네임스페이스)

**nginx.yml**

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx
  namespace: 1team
  labels:
    env: prod
    app: nginx
spec:
  containers:
  - name: n1
    image: nginx
    imagePullPolicy: Never   # Never | IfNotPresent | Always
    ports:
    - containerPort: 80
```

**imagePullPolicy 옵션**

|값|동작|
|---|---|
|`Never`|로컬 이미지만 사용, pull 시도 안 함|
|`IfNotPresent`|로컬에 없을 때만 pull → 오프라인 환경 권장|
|`Always`|매번 레지스트리에서 pull|

```bash
kubectl apply -f nginx.yml

# 실시간 상태 모니터링 (2초 간격)
watch -n 2 kubectl get po --namespace 1team -o wide
curl 192.168.166.130
```

같은 방식으로 apache pod도 노출하고 접속을 확인한다.

```bash
kubectl expose --name apa pod apache --type NodePort --namespace 2team
curl 10.100.46.211
```

![](../../../assets/images/Cloud/KimSeongDae/2026-06-26-kubernetes-kubectl-01/file-20260626113136994.png)

![](../../../assets/images/Cloud/KimSeongDae/2026-06-26-kubernetes-kubectl-01/file-20260626113204928.png)

pod 안에 들어가 페이지 내용을 직접 수정할 수도 있다.

```bash
kubectl exec --namespace 2team -it apache -- /bin/bash

cat > htdocs/index.html << EOF
<html><body><h1>Apache Test Page</h1></body></html>
EOF
```

노드 3대 모두에서 같은 포트로 접속 가능하다: `10.0.0.11:31880`, `10.0.0.12:31880`, `10.0.0.13:31880`

---

## 실습 문제

**1. `ng1.yml` 파일 작성**

1. 첫 번째 리소스: `1team` 네임스페이스 생성
2. 두 번째 리소스: `1team`에 nginx 파드 실행 (pod명 `nginx`, container명 `n1`)
3. 세 번째 리소스는 명령어로 생성: nginx pod를 외부에 NodePort로 공개
4. 화면 출력 내용은 `이니셜-K8S-NGINX`

**2. `ap1.yml` 파일 작성**

1. 첫 번째 리소스: `2team` 네임스페이스 생성
2. 두 번째 리소스: `2team`에 apache 파드 실행 (pod명 `apache`, container명 `a1`)
3. 세 번째 리소스는 명령어로 생성: apache pod를 외부에 NodePort로 공개
4. 화면 출력 내용은 `이니셜-K8S-APACHE`

```bash
kubectl get svc,po --namespace 1team -o wide
kubectl get svc,po --namespace 2team -o wide
```

### ng1.yml

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: 1team
---
apiVersion: v1
kind: Pod
metadata:
  name: nginx
  namespace: 1team
  labels:
    app: nginx
spec:
  containers:
  - name: n1
    image: nginx
    imagePullPolicy: Never
    ports:
    - containerPort: 80
```

### ap1.yml

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: 2team
---
apiVersion: v1
kind: Pod
metadata:
  name: apache
  namespace: 2team
  labels:
    app: apache
spec:
  containers:
  - name: a1
    image: httpd
    imagePullPolicy: Never
    ports:
    - containerPort: 80
```

### 적용

```bash
vi ng1.yml
kubectl apply -f ng1.yml
kubectl get po,svc -o wide --namespace 1team

vi ap1.yml
kubectl apply -f ap1.yml
kubectl get po,svc -o wide --namespace 2team
```

### 서비스 노출

```bash
kubectl expose --name nginx pod nginx --type NodePort --namespace 1team
kubectl expose --name apache pod apache --type NodePort --namespace 2team
```

### 페이지 내용 수정

```bash
kubectl exec --namespace 1team nginx -it -- /bin/bash

cat > /usr/share/nginx/html/index.html << EOF
<html>
<body>
<h1>JHJANG-K8S-NGINX</h1>
</body>
</html>
EOF
```

```bash
kubectl exec --namespace 2team apache -it -- /bin/bash

cat > /usr/local/apache2/htdocs/index.html << EOF
<html>
<body>
<h1>JHJANG-K8S-APACHE</h1>
</body>
</html>
EOF
```

![](../../../assets/images/Cloud/KimSeongDae/2026-06-26-kubernetes-kubectl-01/file-20260626113136994.png)

![](../../../assets/images/Cloud/KimSeongDae/2026-06-26-kubernetes-kubectl-01/file-20260626120859093.png)

![](../../../assets/images/Cloud/KimSeongDae/2026-06-26-kubernetes-kubectl-01/file-20260626120934817.png)

![](../../../assets/images/Cloud/KimSeongDae/2026-06-26-kubernetes-kubectl-01/file-20260626120951741.png)

---

## 요약

- 파드 생성: `kubectl run <이름> --image <이미지> --port <포트>`
- 서비스 노출: `kubectl expose pod <이름> --type NodePort`
- 네임스페이스 지정: `--namespace <이름>` 또는 `-n <이름>`
- YAML 적용: `kubectl apply -f <파일>.yml`
- 리소스 삭제: `kubectl delete -f <파일>.yml` 또는 `kubectl delete <kind> <이름>`
- 이미지 import: `ctr -n k8s.io image import <파일>.tar`
- 실시간 모니터링: `watch -n 2 kubectl get po --namespace <이름>`
- kubeconfig 설정: `cp /etc/kubernetes/admin.conf ~/.kube/config`

---

## 원본에서 수정한 부분

- `Nodeport` → `NodePort`로 대소문자 오타 수정 (k8s 리소스 타입 값은 대소문자를 구분한다)
- YAML의 `-containerPort: 80` → `- containerPort: 80`으로 공백 수정 (하이픈 뒤 공백 누락 시 리스트 항목으로 인식되지 않음)
- 본문 중간의 `>` 인용구를 일반 문장으로 변경 (과도한 기울임체 방지)
- 실습 문제에서 언급만 되고 빠져 있던 `ap1.yml` 예시를 nginx.yml과 대칭되도록 추가
- 중간에 끊겨 있던 apache heredoc 예시를 nginx 쪽과 형식을 맞춰 완성
- "개요" 섹션의 `인자값`이라는 표현을 `키`로 통일 (YAML 용어 일관성)