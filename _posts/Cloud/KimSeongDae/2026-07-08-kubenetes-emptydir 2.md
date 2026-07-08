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

파일 전체를 가져다 쓰는 방법

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

```bash
vi mysql.yml
```

```bash
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
kubectl get pods #alpine과 mysql Ready상태
```

```
vi wordconf
kubectl cre
```