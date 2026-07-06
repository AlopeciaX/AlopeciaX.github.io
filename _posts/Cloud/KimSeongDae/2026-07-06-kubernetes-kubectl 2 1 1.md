---
title: kubectl 기초 실습 정리
date: 2026-07-06
categories:
  - cloud
comments: true
tags:
  - kubernetes
---
---
# Kubernetes 실습 정리 — Deployment 롤링 업데이트 & Ingress Path 라우팅

## 1. 무중단 배포 3가지 방식

|방식|개념|장점|단점|
|---|---|---|---|
|**블루-그린**|기존(블루)은 그대로 두고 새 버전(그린)을 통째로 새로 띄운 뒤, 준비되면 트래픽을 한 번에 전환|문제 생기면 즉시 롤백 가능|리소스 2배 필요|
|**롤링 업데이트**|pod을 하나씩 순차적으로 종료하고 새 버전으로 교체|추가 리소스 불필요, k8s Deployment 기본 방식|교체 중 신/구 버전이 잠깐 혼재|
|**카나리아**|새 버전을 일부 비율만 먼저 내보내 테스트 후 점차 비율 확대|문제 생겨도 영향 범위 적음|설정 복잡 (트래픽 비율 조절 필요)|

오늘 실습한 것은 **롤링 업데이트** 방식이며, `kubectl edit deploy`로 이미지 버전만 바꿔도 k8s가 자동으로 수행한다.

---

## 2. Deployment 이미지 버전 변경 실습

### 목표

nginx pod을 배포하고, 이미지 버전을 변경한 뒤, 실제로 바뀌었는지 확인하기

### 사용한 원본 yaml (참고용)

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: dep-nginx
  labels:
    app: nginx
    env: devel
spec:
  replicas: 4
  selector:
    matchLabels:
      tem: nginx
  template:
    metadata:
      name: tem-nginx
      labels:
        tem: nginx
    spec:
      containers:
      - name: n1
        image: nginx:1.14
        imagePullPolicy: Never
        ports:
        - containerPort: 80
        resources:
          limits:
            cpu: "200m"
            memory: "200Mi"
          requests:
            cpu: "100m"
            memory: "100Mi"
```

### 1단계. kubectl 접속 문제 해결

**어디서: k8s-master**

```bash
export KUBECONFIG=/etc/kubernetes/admin.conf
echo 'export KUBECONFIG=/etc/kubernetes/admin.conf' >> ~/.bashrc
source ~/.bashrc
```

> kubectl은 클러스터 접속 정보(kubeconfig)가 필요. 없어서 `localhost:8080` 에러가 났고, 경로를 지정해서 해결.

### 2단계. 클러스터 구조 확인

**어디서: k8s-master**

```bash
kubectl get nodes -o wide
```

> 노드 3개(k8s-master, k8s-worker1, k8s-worker2), 컨테이너 런타임은 **containerd** (docker 아님).

### 3단계. ingress-nginx 컨트롤러 설치

**어디서: k8s-master**

```bash
wget https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.15.1/deploy/static/provider/baremetal/deploy.yaml
kubectl apply -f deploy.yaml
```

### 4단계. 기존 dep-nginx 상태 확인

**어디서: k8s-master**

```bash
kubectl get deploy,po -o wide
kubectl get deploy dep-nginx -o yaml | grep -A5 containers
```

> 실제로는 image: `nginx:latest`, imagePullPolicy: `IfNotPresent`였음 → 인터넷에서 자동 pull 가능한 상태라 tar/scp/ctr import 작업은 불필요했음 (그건 `Never`일 때만 필요).

### 5단계. 이미지 버전 변경

**어디서: k8s-master**

```bash
kubectl edit deploy dep-nginx
```

```yaml
image: nginx:latest   →   image: nginx:1.13
```

`Esc` → `:wq` 저장 → k8s가 자동으로 기존 pod 종료 + 새 pod 생성 (롤링 업데이트)

### 6단계. 새 pod 생성 확인

**어디서: k8s-master**

```bash
kubectl get pods -o wide
```

> pod 이름의 해시값이 바뀌었으면 새로 생성된 것.

### 7단계. pod 내부에서 버전 확인

**어디서: k8s-master**

```bash
kubectl exec -it dep-nginx-677578bf97-4g72d -- bash
```

**어디서: pod 내부**

```bash
nginx -v
```

```
결과: nginx version: nginx/1.13.12  ✅ 성공
```

> `--`는 "여기부터는 pod 안에서 실행할 명령"이라는 구분자.

### 실습 종료 후 정리

```bash
kubectl delete deploy dep-nginx
```

---

## 3. Ingress Path 기반 라우팅 실습

### 목표

하나의 Ingress로 `/pic`, `/mov` 경로에 따라 서로 다른 서비스(nginx, apache)로 트래픽 분기

### 작업 디렉터리 생성

**어디서: k8s-master**

```bash
mkdir /ing
cd /ing
vi ingress.yml
```

### 처음 작성한 (오류 있던) yaml

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: test-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    kubernetes.io/ingress.class: "nginx"
spec:
  rules:
  - http:
    paths:                    # ← 들여쓰기 오류
    - path: /pic
      pathType: Prefix
      backend:
        service:
          name: svc1
          port:
            number: 80
    - path: /mov
```

```
Error from server (BadRequest): unknown field "spec.rules[0].paths"
```

> `paths`가 `http:`와 같은 들여쓰기 위치에 있어서 `rules`의 필드로 잘못 인식됨. YAML은 들여쓰기 한 칸으로 구조가 완전히 달라짐.

### 수정된 올바른 yaml

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: test-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
  - http:
      paths:
      - path: /pic
        pathType: Prefix
        backend:
          service:
            name: svc1
            port:
              number: 80
      - path: /mov
        pathType: Prefix
        backend:
          service:
            name: svc2
            port:
              number: 80
```

> `kubernetes.io/ingress.class` (구버전 방식)는 제거하고 `spec.ingressClassName: nginx`로 통일.

### 적용

**어디서: k8s-master**

```bash
kubectl apply -f ingress.yml --namespace=ingress-nginx
```

```
ingress.networking.k8s.io/test-ingress created
```

### 백엔드 pod/service 생성 (Ingress가 가리킬 대상)

**Pod 생성 (Deployment)**

```bash
kubectl create deployment nginx --image nginx --replicas 1 --namespace ingress-nginx
kubectl create deployment apache --image httpd --replicas 1 --namespace ingress-nginx
```

> `--image-pull-policy` 옵션은 `kubectl create deployment`에서 지원되지 않음 (에러 발생 후 제거하고 재시도).

**Service 생성 (pod을 고정 주소로 묶음)**

```bash
kubectl expose --name svc1 deployment nginx --port 80 --namespace ingress-nginx
kubectl expose --name svc2 deployment apache --port 80 --namespace ingress-nginx
```

> 처음에 svc1로 apache까지 expose 시도해서 `AlreadyExists` 에러 → svc2로 이름 변경해서 해결.

### 완성된 구조

```
Ingress (test-ingress)
   /pic 경로 → svc1 → nginx pod
   /mov 경로 → svc2 → apache pod
```

### 테스트 (다음 단계)

```bash
kubectl get pod,svc,ing -n ingress-nginx
curl http://10.0.0.11:30914/pic   # nginx 기본 페이지 예상
curl http://10.0.0.11:30705/mov   # apache 기본 페이지 예상
```

![](../../../assets/images/Cloud/KimSeongDae/2026-07-06-kubernetes-kubectl%202%201%201/file-20260706112235343.png)

---

## 4. 실습 환경 정리 (Cleanup)

|명령|삭제된 것|
|---|---|
|`kubectl delete deploy nginx apache --namespace ingress-nginx`|nginx, apache Deployment(pod 포함)|
|`kubectl delete svc svc1 svc2 --namespace ingress-nginx`|Service svc1, svc2|
|`kubectl delete -f deploy.yaml`|ingress-nginx 컨트롤러 전체 (namespace, controller pod, RBAC, webhook 등)|

**중간 오타/실수**

```bash
kubectl delete deploy ngnix apache        # 오타(ngnix) → NotFound
kubectl delete svc1 svc2 --namespace ...  # 리소스 타입(svc) 누락 → 에러
```

→ `kubectl delete <타입> <이름1> <이름2>` 순서 정확히 지켜야 함.

**`deploy.yaml` 삭제 시 나온 마지막 에러 2줄은 정상**

```
Error from server (NotFound): jobs.batch "ingress-nginx-admission-create" not found
Error from server (NotFound): jobs.batch "ingress-nginx-admission-patch" not found
```

> 설치 시 일회성으로 실행되고 자동 삭제되는 Job이라, 이미 없는 상태에서 삭제 시도한 것뿐. 핵심 리소스는 전부 정상 삭제됨.

### 최종 확인

```bash
kubectl get all -n ingress-nginx    # No resources found 기대
kubectl get namespace                # ingress-nginx 없어야 함
```

### 남은 파일 정리

```bash
ll ~
# nginx-1.14.tar (44MB) - 더 안 쓰면 삭제 가능: rm nginx-1.14.tar
# deploy.yaml - ingress-nginx 재설치용 원본, 유지 가능
# dep/ - httpd, mysql, wordpress deployment yaml (별도 실습용, 유지)
```

---

## 핵심 개념 요약

- **Pod (Deployment)**: 컨테이너 실행. `imagePullPolicy: Never`면 로컬에 이미지가 미리 있어야 함 (`ctr import` 필요). `IfNotPresent`/`Always`면 인터넷에서 자동 pull.
- **Service**: 여러 pod을 고정 주소로 묶고 로드밸런싱. pod IP는 계속 바뀌므로 Service가 안정적인 진입점 역할.
- **Ingress**: 외부 요청을 도메인/경로 기준으로 어떤 Service로 보낼지 라우팅하는 입구. Service가 먼저 존재해야 정상 동작.
- **YAML 들여쓰기**: k8s yaml 에러의 대부분은 들여쓰기 문제. `rules → http → paths → path/backend` 계층 구조를 정확히 지켜야 함.