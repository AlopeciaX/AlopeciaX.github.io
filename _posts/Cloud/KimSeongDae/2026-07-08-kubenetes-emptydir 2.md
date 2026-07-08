---
title: kubectl 실습 - emptyDir 볼륨
date: 2026-07-08
categories:
  - cloud
comments: true
tags:
  - kubernetes
---
---
## ConfigMap 생성 (파일 전체 가져오기)

```bash
mkdir /conf
cd /conf
vi mysqlconf
```

```bash
MYSQL_ROOT_PASSWORD=It12345!
MYSQL_DATABASE=word
MYSQL_USER=jhjang
MYSQL_PASSWORD=It12345!
```

```bash
kubectl create configmap mysqlenv --from-env-file mysqlconf
kubectl get configmaps
kubectl get configmaps mysqlenv -o yaml
```

## MySQL Pod 배포

```bash
vi mysql.yml
```

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: mysql
  labels:
    app: mysql
    env: devel
spec:
  containers:
  - name: m1
    image: mysql:8.0
    imagePullPolicy: IfNotPresent
    ports:
    - containerPort: 3306
    envFrom:
    - configMapRef:
        name: mysqlenv
```

```bash
kubectl apply -f mysql.yml --dry-run=server
kubectl get pods -o wide
mysql -uroot -pIt12345! -h [IP주소]
kubectl expose -name svc-mysql pod mysql --port 80
kubectl get pods,svc
kubectl get pods -A
kubectl exec mysql -- nslookup svc-mysql
kubectl run alpine --image alpine
```

```bash
kubectl get pods # alpine, mysql 모두 Ready 상태 확인
```

## WordPress ConfigMap 생성 (진행중)

```bash
vi wordconf
kubectl create configmap wordenv
```

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: word
  labels:
    app: wordpress
    env: devel
spec:
  containers:
  - name: w1
    image: wordpress
    imagePullPolicy: Never
    ports:
    - containerPort: 80
    envFrom:
    - configMapRef:
        name: wordenv
```