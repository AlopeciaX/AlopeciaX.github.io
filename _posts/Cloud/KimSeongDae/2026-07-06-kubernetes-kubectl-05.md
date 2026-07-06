---
title: kubectl 기초 실습 정리
date: 2026-07-06
categories:
  - cloud
comments: true
tags:
  - kubernetes
---
# Kubernetes 실습 정리 — Deployment / Service / Ingress

## 1. 무중단 배포 방식

서비스 중단 없이 새 버전으로 교체하는 방법은 크게 세 가지가 있다.

|방식|개념|장점|단점|
|---|---|---|---|
|블루-그린|기존(블루)은 그대로 두고 새 버전(그린)을 통째로 새로 띄운 뒤, 준비되면 트래픽을 한 번에 전환|문제 생기면 즉시 롤백 가능|리소스 2배 필요|
|롤링 업데이트|pod을 하나씩 순차적으로 종료하고 새 버전으로 교체|추가 리소스 불필요, k8s Deployment 기본 방식|교체 중 신/구 버전이 잠깐 혼재|
|카나리아|새 버전을 일부 비율만 먼저 내보내 테스트 후 점차 비율 확대|문제 생겨도 영향 범위 적음|설정이 복잡함|

오늘 실습한 것은 롤링 업데이트 방식이며, `kubectl edit deploy`로 이미지 버전만 바꿔도 k8s가 자동으로 수행한다.

---

## 2. Deployment 이미지 버전 변경 실습

nginx pod을 배포하고, 이미지 버전을 변경한 뒤 실제로 바뀌었는지 확인한다.

### kubectl 접속 설정

```bash
export KUBECONFIG=/etc/kubernetes/admin.conf
echo 'export KUBECONFIG=/etc/kubernetes/admin.conf' >> ~/.bashrc
source ~/.bashrc
```

kubectl은 클러스터 접속 정보(kubeconfig)가 필요하다. 경로를 지정해서 연결했다.

### 클러스터 구조 확인

```bash
kubectl get nodes -o wide
```

노드는 3개(k8s-master, k8s-worker1, k8s-worker2)이고, 컨테이너 런타임은 containerd다.

### 기존 Deployment 상태 확인

```bash
kubectl get deploy,po -o wide
kubectl get deploy dep-nginx -o yaml | grep -A5 containers
```

기존 `dep-nginx`는 image가 `nginx:latest`, imagePullPolicy가 `IfNotPresent`로 설정되어 있었다. 인터넷에서 자동으로 이미지를 받아올 수 있는 상태다.

### 이미지 버전 변경

```bash
kubectl edit deploy dep-nginx
```

```yaml
image: nginx:latest   →   image: nginx:1.13
```

저장하면 k8s가 기존 pod을 하나씩 종료하고 새 이미지로 pod을 재생성한다(롤링 업데이트).

### 새 pod 확인

```bash
kubectl get pods -o wide
```

pod 이름의 해시값이 바뀌었으면 새로 생성된 것이다.

### pod 내부에서 버전 확인

```bash
kubectl exec -it dep-nginx-677578bf97-4g72d -- bash
```

pod 안에서:

```bash
nginx -v
# nginx version: nginx/1.13.12
```

버전이 바뀐 것을 확인했다.

### 정리

```bash
kubectl delete deploy dep-nginx
```

---

## 3. Ingress Path 기반 라우팅 실습

하나의 Ingress로 `/pic`, `/mov` 경로에 따라 서로 다른 서비스(nginx, apache)로 트래픽을 분기한다.

### Ingress 작성

```bash
mkdir /ing
cd /ing
vi ingress.yml
```

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

```bash
kubectl apply -f ingress.yml --namespace=ingress-nginx
```

### 백엔드 pod/service 생성

```bash
kubectl create deployment nginx --image nginx --replicas 1 --namespace ingress-nginx
kubectl create deployment apache --image httpd --replicas 1 --namespace ingress-nginx
```

```bash
kubectl expose --name svc1 deployment nginx --port 80 --namespace ingress-nginx
kubectl expose --name svc2 deployment apache --port 80 --namespace ingress-nginx
```

완성된 구조:

```
Ingress (test-ingress)
   /pic 경로 → svc1 → nginx pod
   /mov 경로 → svc2 → apache pod
```

### 테스트

```bash
kubectl get pod,svc,ing -n ingress-nginx
curl http://10.0.0.11:30914/pic   # nginx 기본 페이지
curl http://10.0.0.11:30705/mov   # apache 기본 페이지
```

ingress-nginx-controller Service가 NodePort 타입이라 노드IP:NodePort로 접속해서 확인한다.

### 정리

```bash
kubectl delete deploy nginx apache --namespace ingress-nginx
kubectl delete svc svc1 svc2 --namespace ingress-nginx
kubectl delete -f deploy.yaml
```

```bash
kubectl get all -n ingress-nginx    # No resources found
kubectl get namespace                # ingress-nginx 없어야 함
```

---

## 4. Deployment/Service를 yaml로 재작성

지금까지는 `kubectl create`, `kubectl expose` 같은 명령형 명령으로 리소스를 만들었다. 실무에서는 보통 yaml 파일로 작성해서 관리한다. 파일로 남겨두면 재사용과 버전 관리가 가능하고, protocol이나 다중 포트 같은 세부 옵션도 명령어보다 정확하게 표현할 수 있다.

### dep-apache.yml

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: dep-apache
  labels:
    app: httpd
    env: prod
spec:
  replicas: 4
  selector:
    matchLabels:
      tem: apache
  template:
    metadata:
      name: tem-apache
      labels:
        tem: apache
    spec:
      containers:
      - name: n1
        image: httpd
        imagePullPolicy: Never
        ports:
        - containerPort: 80
```

```bash
kubectl apply -f httpd.yml --namespace ingress-nginx
```

이전에 명령어로 만든 apache는 imagePullPolicy를 지정하지 않아 기본값(자동 pull)이 적용되어 문제없이 동작했다. 이 yaml은 `Never`를 직접 명시했기 때문에, 해당 노드에 httpd 이미지가 로컬로 미리 있어야 한다. 없으면 `ErrImageNeverPull`이 발생한다. `IfNotPresent`로 바꾸거나, nginx 때처럼 이미지를 tar로 저장해 각 노드에 `ctr import` 해줘야 한다.

### svc2.yml

```yaml
apiVersion: v1
kind: Service
metadata:
  name: svc2
  labels:
    env: prod
spec:
  type: ClusterIP
  ports:
  - port: 80
    targetPort: 80
    protocol: TCP
  selector:
    tem: apache
```

```bash
kubectl apply -f nginxsvc2.yml -n ingress-nginx
kubectl get svc -n ingress-nginx
```

`spec.selector`는 연결할 pod의 label과 정확히 일치해야 한다. yaml로 만든 `dep-apache`는 label이 `tem: apache`라 일치하지만, 이전에 명령어(`kubectl create deployment apache`)로 만든 pod은 기본적으로 `app: apache` label을 갖기 때문에 selector와 맞지 않을 수 있다. 실제 label은 아래로 확인한다.

```bash
kubectl get pods -n ingress-nginx --show-labels
```

`metadata.labels`는 Service 자신을 구분하는 꼬리표라 없어도 동작에는 지장이 없다. 반면 `spec.selector`는 필수이며, 이게 없거나 pod label과 안 맞으면 Service가 어떤 pod과도 연결되지 않는다.

---

## 핵심 개념 요약

- **Pod (Deployment)**: 컨테이너 실행. `imagePullPolicy: Never`면 로컬에 이미지가 미리 있어야 한다. `IfNotPresent`/`Always`(또는 미지정 기본값)면 인터넷에서 자동으로 pull 받는다.
- **Service**: 여러 pod을 고정 주소로 묶고 로드밸런싱한다. pod IP는 계속 바뀌므로 Service가 안정적인 진입점 역할을 한다. `spec.selector`가 pod label과 일치해야 연결된다.
- **Ingress**: 외부 요청을 도메인/경로 기준으로 어떤 Service로 보낼지 라우팅하는 입구다. Service가 먼저 존재해야 정상 동작한다.
- **명령형 vs 선언형**: `kubectl create`/`expose`는 빠른 테스트용, 실제 운영/재사용은 yaml 파일 기반(`kubectl apply -f`)이 표준이다.

---

## 트러블슈팅 기록

**kubectl이 localhost:8080에 접속 시도** `KUBECONFIG` 환경변수가 세션에 설정 안 돼서 발생. `export KUBECONFIG=/etc/kubernetes/admin.conf`로 해결.

**Ingress yaml에서 `unknown field "spec.rules[0].paths"` 에러** `paths`가 `http:`와 같은 들여쓰기 위치에 있어서 `rules`의 필드로 잘못 인식됨. `paths`는 `http:`보다 한 단계 더 들여써야 한다.

**`kubectl create deployment`에 `--image-pull-policy` 옵션 사용 시 에러** 이 옵션은 지원되지 않는다. 옵션 없이 생성 후 필요하면 `kubectl edit`으로 추가해야 한다.

**`kubectl expose --name svc1 deployment apache`에서 AlreadyExists 에러** svc1을 nginx에 이미 붙여놨는데 같은 이름으로 apache에도 붙이려다 발생. svc2로 이름을 바꿔서 해결.

**`kubectl delete deploy ngnix apache` → NotFound** `nginx`를 `ngnix`로 오타. 정확한 이름으로 재시도해서 해결.

**`kubectl delete svc1 svc2 --namespace ...` → unknown resource type** 리소스 타입(`svc`)을 빠뜨리고 이름만 입력해서 발생. `kubectl delete svc svc1 svc2` 형태로 타입을 명시해야 한다.

**`kubectl delete -f deploy.yaml` 마지막에 Job not found 에러 2줄** ingress-nginx 설치 시 일회성으로 실행되고 자동 삭제되는 Job이라, 이미 없는 상태에서 삭제를 시도한 것뿐이다. 핵심 리소스는 정상적으로 삭제됐으므로 무시해도 된다.

**Service yaml에서 `-port: 80`으로 작성해 문법 오류** 하이픈과 필드명 사이에 공백이 빠졌다. `- port: 80`처럼 하이픈 뒤에 공백이 있어야 리스트 항목으로 인식된다.