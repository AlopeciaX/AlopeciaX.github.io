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
```