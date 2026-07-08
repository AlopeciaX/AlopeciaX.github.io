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