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
## Ingress

무중단 배포

1.블루, 그린 배포
![](../../../assets/images/Cloud/KimSeongDae/2026-07-06-kubernetes-kubectl%202%201%201/file-20260706093445190.png)


2.롤링 업데이트

![](../../../assets/images/Cloud/KimSeongDae/2026-07-06-kubernetes-kubectl%202%201%201/file-20260706093424202.png)

3.카나리아

![](../../../assets/images/Cloud/KimSeongDae/2026-07-06-kubernetes-kubectl%202%201%201/file-20260706093536467.png)

```bash
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

![](../../../assets/images/Cloud/KimSeongDae/2026-07-06-kubernetes-kubectl%202%201%201/file-20260706105517456.png)

1.14를 1.13으로 업데이트
kubectl edit deploy dep-nginx
kubectl get pods -o wide
kubectl exec -it  -- bash
nginx -v




---

### 목표

nginx pod을 배포하고, 이미지 버전을 변경한 뒤, 실제로 바뀌었는지 확인하기

---

### 1단계. kubectl 접속 문제 해결

**어디서: k8s-master**

bash

```bash
export KUBECONFIG=/etc/kubernetes/admin.conf
echo 'export KUBECONFIG=/etc/kubernetes/admin.conf' >> ~/.bashrc
source ~/.bashrc
```

**설명**: `kubectl`은 클러스터 접속 정보(kubeconfig)가 필요합니다. 이게 없어서 `localhost:8080` 에러가 났고, 정확한 설정 파일 경로를 지정해서 해결했습니다.

---

### 2단계. 클러스터 구조 확인

**어디서: k8s-master**

bash

```bash
kubectl get nodes -o wide
```

**설명**: 노드가 3개(`k8s-master`, `k8s-worker1`, `k8s-worker2`)이고, 컨테이너 런타임이 **containerd**임을 확인했습니다. (docker 아님 — 그래서 docker 설치가 원래 불필요했습니다.)

---

### 3단계. ingress-nginx 설치 (별도 작업)

**어디서: k8s-master**

bash

```bash
wget https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.15.1/deploy/static/provider/baremetal/deploy.yaml
kubectl apply -f deploy.yaml
```

**설명**: k8s 클러스터 외부에서 서비스로 접속하기 위한 ingress 컨트롤러를 설치했습니다. (nginx pod 배포와는 별개 작업)

---

### 4단계. nginx Deployment 상태 확인

**어디서: k8s-master**

bash

```bash
kubectl get deploy,po -o wide
```

**설명**: 이미 `dep-nginx`라는 Deployment가 존재하고 있었습니다. 실제 설정을 열어보니:

bash

```bash
kubectl get deploy dep-nginx -o yaml | grep -A5 containers
```

- image: **nginx:latest**
- imagePullPolicy: **IfNotPresent** (로컬에 없으면 자동으로 인터넷에서 pull)

→ 즉 **인터넷에서 이미지를 자동으로 받아올 수 있는 상태**라서, 이전에 얘기했던 tar 파일 만들고 scp로 옮기고 `ctr import` 하는 복잡한 과정은 **이 경우엔 필요 없었습니다.** (그건 `imagePullPolicy: Never`일 때만 필요)

---

### 5단계. 이미지 버전 변경

**어디서: k8s-master**

bash

```bash
kubectl edit deploy dep-nginx
```

vi 편집기가 열리고, 아래처럼 수정:

yaml

```yaml
image: nginx:latest   →   image: nginx:1.13
```

`Esc` → `:wq` 저장

**설명**: Deployment 설정(레시피)을 바꾼 것입니다. 저장하는 순간 k8s가 자동으로:

- 기존 pod(`nginx:latest`로 뜬 것)을 하나씩 종료
- 새 pod을 `nginx:1.13` 이미지로 새로 생성  
    (이걸 "롤링 업데이트"라고 합니다)

---

### 6단계. 새 pod 생성 확인

**어디서: k8s-master**

bash

```bash
kubectl get pods -o wide
```

**설명**: pod 이름이 바뀌었는지 확인 (예: `dep-nginx-677578bf97-4g72d` — 해시값이 이전과 다름 = 새 pod이 생성됐다는 뜻)

---

### 7단계. pod 내부로 들어가서 실제 버전 확인

**어디서: k8s-master**

bash

```bash
kubectl exec -it dep-nginx-677578bf97-4g72d -- bash
```

**설명**: `--`는 "여기부터는 pod 안에서 실행할 명령"이라는 구분자입니다. 이 명령으로 마치 그 pod 안에 SSH로 접속한 것처럼 들어갑니다.

**어디서: pod 내부 (bash 진입 후, 프롬프트가 `root@dep-nginx-...:/#`로 바뀜)**

bash

```bash
nginx -v
```

**설명**: 이게 최종 확인입니다. 여기서 `nginx version: nginx/1.13.x`가 나오면 → **Deployment 수정 → 롤링 업데이트 → 실제 pod 안의 nginx 버전 변경**까지 전체 과정이 성공적으로 끝난 것입니다.


```bash
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
    paths:  
    - path: /pic
      pathType: Prefix
      backend:
        service:
          name: svc1
          port:   
            number: 80
    - path: /mov
```

```bash
kubectl apply -f ingress.yml --namespace=ingress-nginx
```



![](../../../assets/images/Cloud/KimSeongDae/2026-07-06-kubernetes-kubectl%202%201%201/file-20260706105459356.png)